#!/usr/bin/env bash
set -euo pipefail

RAW_BASE="${RAW_BASE:-https://raw.githubusercontent.com/zenenznze/setup-codesome/master}"
CONFIG_SCRIPT="setup-codex-gpt-v5.sh"
BASE_URL="https://v5.codesome.cn/openai"
MODEL="gpt-6-astra"
KEY_HINT="cr-..."

log() { printf '\033[0;32m[OK]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err() { printf '\033[0;31m[ERR]\033[0m %s\n' "$*"; }
has() { command -v "$1" >/dev/null 2>&1; }
os_name() {
  case "$(uname -s 2>/dev/null || echo unknown)" in
    Darwin*) echo macos ;;
    Linux*) grep -qi microsoft /proc/version 2>/dev/null && echo wsl || echo linux ;;
    MINGW*|MSYS*|CYGWIN*) echo windows ;;
    *) echo unknown ;;
  esac
}

read_key() {
  if [ -n "${1:-}" ]; then API_KEY="$1"; else
    if [ -t 0 ]; then
      read -rsp "请输入 Codesome V5 API Key (${KEY_HINT}): " API_KEY; echo ""
    elif [ -r /dev/tty ]; then
      read -rsp "请输入 Codesome V5 API Key (${KEY_HINT}): " API_KEY < /dev/tty; echo ""
    else
      err "无交互终端，无法读取 API Key。请先下载脚本再运行。"; exit 1
    fi
  fi
  [ -n "$API_KEY" ] || { err "API Key 不能为空"; exit 1; }
  case "$API_KEY" in
    cr-*) ;;
    *)
      warn "Key 不是以 cr- 开头，请确认这是 Codesome V5 的 Key。"
      if [ -t 0 ]; then
        read -rp "仍要继续? [y/N]: " CONFIRM
        case "${CONFIRM:-}" in
          y|Y|yes|YES) ;;
          *) err "已取消"; exit 1 ;;
        esac
      fi
      ;;
  esac
}

ensure_node_unix() {
  has node && has npm && return 0
  log "安装 Node.js LTS..."
  export NVM_DIR="$HOME/.nvm"
  mkdir -p "$NVM_DIR"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm alias default 'lts/*'
}

ensure_git() {
  if has git || has git.exe; then log "Git 已安装"; return 0; fi
  case "$(os_name)" in
    windows)
      log "Windows: 安装 Git..."
      powershell.exe -NoProfile -ExecutionPolicy Bypass -Command 'if (Get-Command winget -ErrorAction SilentlyContinue) { winget install Git.Git -e --accept-source-agreements --accept-package-agreements } else { throw "请先安装 Git for Windows: https://git-scm.com/download/win" }'
      ;;
    macos)
      if has brew; then brew install git; else xcode-select --install || warn "请按系统提示安装 Command Line Tools"; fi
      ;;
    linux|wsl)
      if has apt-get; then sudo apt-get update && sudo apt-get install -y git; else err "请先安装 git"; exit 1; fi
      ;;
  esac
}

install_codex() {
  OS="$(os_name)"
  if has codex || has codex.exe; then log "CodeX 已安装"; return 0; fi
  case "$OS" in
    windows)
      log "Windows: 检查 Node.js..."
      powershell.exe -NoProfile -ExecutionPolicy Bypass -Command 'if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { if (Get-Command winget -ErrorAction SilentlyContinue) { winget install OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements } else { throw "请先安装 Node.js: https://nodejs.org/en/download" } }'
      log "Windows: 安装 CodeX CLI..."
      powershell.exe -NoProfile -ExecutionPolicy Bypass -Command 'npm i -g @openai/codex; if ($LASTEXITCODE -ne 0) { npm i -g @openai/codex --registry=https://registry.npmmirror.com }'
      ;;
    macos|linux|wsl)
      ensure_node_unix
      log "安装 CodeX CLI..."
      npm i -g @openai/codex || npm i -g @openai/codex --registry=https://registry.npmmirror.com
      ;;
    *) err "无法识别系统，请手动安装 Node.js 和 CodeX 后重试"; exit 1 ;;
  esac
}

configure_windows() {
  log "Windows: 写入 CodeX 配置..."
  CODESOME_SETUP_API_KEY="$API_KEY" powershell.exe -NoProfile -ExecutionPolicy Bypass -Command '
    $Key = $env:CODESOME_SETUP_API_KEY
    $CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
    New-Item -ItemType Directory -Force $CodexHome | Out-Null
    $AuthPath = Join-Path $CodexHome "auth.json"
    $ConfigPath = Join-Path $CodexHome "config.toml"
    $Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    foreach ($f in @($ConfigPath, $AuthPath)) {
      if (Test-Path $f) { Copy-Item $f "$f.bak.$Stamp" -Force }
    }
    $Config = @"
model = "'"$MODEL"'"
model_provider = "codesome_v5"

[model_providers.codesome_v5]
name = "Codesome V5"
base_url = "'"$BASE_URL"'"
wire_api = "responses"
requires_openai_auth = true
"@
    $Auth = @{ OPENAI_API_KEY = $Key } | ConvertTo-Json -Depth 2
    $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($ConfigPath, $Config, $Utf8NoBom)
    [System.IO.File]::WriteAllText($AuthPath, $Auth, $Utf8NoBom)
    try {
      $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
      icacls $AuthPath /inheritance:r /grant:r "${Identity}:(R,W)" | Out-Null
      icacls $ConfigPath /inheritance:r /grant:r "${Identity}:(R,W)" | Out-Null
    } catch {
      Write-Host "[WARN] 无法收紧文件 ACL，请手动检查权限。" -ForegroundColor Yellow
    }
    Write-Host "[OK] CodeX 配置完成: $ConfigPath"
    Write-Host "请彻底退出所有 Codex 进程后重新打开 PowerShell，再输入 codex 验证。"
  '
}

configure_unix() {
  local script="./$CONFIG_SCRIPT"
  if [ ! -f "$script" ]; then
    curl -fsSLO "$RAW_BASE/$CONFIG_SCRIPT"
    chmod +x "$CONFIG_SCRIPT"
  fi
  bash "$script" "$API_KEY"
}

echo "============================================"
echo " 完整安装 + 配置：CodeX / GPT 模型 / Codesome V5"
echo "============================================"
read_key "${1:-}"
ensure_git
install_codex
if [ "$(os_name)" = "windows" ]; then configure_windows; else configure_unix; fi
log "完成。请彻底退出所有 Codex 进程后重新打开终端，再运行 codex 验证。"

#!/usr/bin/env bash
set -euo pipefail

RAW_BASE="${RAW_BASE:-https://raw.githubusercontent.com/zenenznze/setup-codesome/master}"
CONFIG_SCRIPT="setup-vscode-claude-codesome.sh"
BASE_URL="https://cc.codesome.ai"

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
  if [ -n "${1:-}" ]; then API_KEY="$1"; else read -rsp "请输入 Codesome API Key (sk-...): " API_KEY; echo ""; fi
  [ -n "$API_KEY" ] || { err "API Key 不能为空"; exit 1; }
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

install_claude() {
  OS="$(os_name)"
  if has claude || has claude.exe; then log "Claude Code 已安装"; return 0; fi
  case "$OS" in
    windows)
      log "Windows: 使用官方 PowerShell 安装器安装 Claude Code..."
      powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm https://claude.ai/install.ps1 | iex"
      ;;
    macos|linux|wsl)
      ensure_node_unix
      log "安装 Claude Code CLI..."
      npm install -g @anthropic-ai/claude-code || npm install -g @anthropic-ai/claude-code --registry=https://registry.npmmirror.com
      ;;
    *) err "无法识别系统，请手动安装 Claude Code 后重试"; exit 1 ;;
  esac
}

install_vscode_extension() {
  if has code; then
    log "安装 VS Code Claude Code 扩展..."
    code --install-extension anthropic.claude-code || warn "VS Code 扩展自动安装失败，可在插件市场搜索 Claude Code 手动安装"
  elif has code.cmd; then
    log "安装 VS Code Claude Code 扩展..."
    code.cmd --install-extension anthropic.claude-code || warn "VS Code 扩展自动安装失败，可在插件市场搜索 Claude Code 手动安装"
  else
    warn "未检测到 code 命令，跳过 VS Code 扩展安装。请在 VS Code 插件市场搜索 Claude Code 安装。"
  fi
}

configure_windows() {
  log "Windows: 写入 VS Code 插件配置..."
  CODESOME_SETUP_API_KEY="$API_KEY" powershell.exe -NoProfile -ExecutionPolicy Bypass -Command '
    $Key = $env:CODESOME_SETUP_API_KEY
    $ClaudeHome = Join-Path $HOME ".claude"
    New-Item -ItemType Directory -Force $ClaudeHome | Out-Null
    $settings = @{
      env = @{
        ANTHROPIC_BASE_URL = "'"$BASE_URL"'"
        ANTHROPIC_AUTH_TOKEN = $Key
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"
        CLAUDE_CODE_ATTRIBUTION_HEADER = "0"
      }
    } | ConvertTo-Json -Depth 4
    $settings | Set-Content -Encoding UTF8 (Join-Path $ClaudeHome "settings.json")
    Write-Host "VS Code Claude Code 插件配置完成。请完全退出并重启 VS Code。"
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
echo " 完整安装 + 配置：VS Code 插件 / Claude 模型 / Codesome"
echo "============================================"
read_key "${1:-}"
ensure_git
install_claude
install_vscode_extension
if [ "$(os_name)" = "windows" ]; then configure_windows; else configure_unix; fi
log "完成。请完全退出并重启 VS Code。"

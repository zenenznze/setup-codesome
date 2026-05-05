#!/usr/bin/env bash
set -euo pipefail

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
  export NVM_DIR="$HOME/.nvm"
  mkdir -p "$NVM_DIR"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm alias default 'lts/*'
}

install_claude() {
  if has claude || has claude.exe; then log "Claude Code 已安装"; return 0; fi
  case "$(os_name)" in
    windows) powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm https://claude.ai/install.ps1 | iex" ;;
    macos|linux|wsl)
      ensure_node_unix
      npm install -g @anthropic-ai/claude-code || npm install -g @anthropic-ai/claude-code --registry=https://registry.npmmirror.com
      ;;
    *) err "无法识别系统，请手动安装 Claude Code"; exit 1 ;;
  esac
}

install_ccswitch() {
  case "$(os_name)" in
    macos)
      if has brew; then
        brew tap farion1231/ccswitch || true
        brew install --cask cc-switch || warn "ccswitch 自动安装失败，请手动安装"
      else
        warn "未检测到 Homebrew，请手动安装 ccswitch: https://github.com/farion1231/cc-switch/releases"
      fi
      ;;
    windows)
      warn "Windows 请从 https://github.com/farion1231/cc-switch/releases 下载 .msi 安装 ccswitch"
      ;;
    *)
      warn "当前系统未提供 ccswitch 自动安装流程，请手动安装并开启代理"
      ;;
  esac
}

echo "============================================"
echo " 完整安装入口：Claude Code / GPT 模型 / Codesome"
echo "============================================"
read_key "${1:-}"
install_claude
install_ccswitch
echo ""
warn "Claude Code 使用 GPT 模型需要 ccswitch 做 API 格式转换，不能只靠脚本写环境变量完成。"
echo "请在 ccswitch 中填写："
echo "供应商名称: codesome"
echo "请求地址: https://cc.codesome.ai"
echo "API Key: ${API_KEY:0:12}..."
echo "API 格式: openai response api"
echo "模型 ID: gpt-5.5"
echo "并打开 ccswitch 本地代理开关，然后新开终端运行 claude。"

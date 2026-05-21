#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err() { echo -e "${RED}[ERR]${NC} $*"; }
info() { echo -e "${BLUE}[..]${NC} $*"; }

CLAUDE_SETTINGS="$HOME/.claude/settings.json"
CODEX_AUTH="$HOME/.codex/auth.json"
CODEX_CONFIG="$HOME/.codex/config.toml"
RC_FILES=(
  "$HOME/.bashrc"
  "$HOME/.bash_profile"
  "$HOME/.zshrc"
  "$HOME/.profile"
  "$HOME/.zprofile"
  "$HOME/.zshenv"
)

mask_secret() {
  local secret="${1:-}"
  if (( ${#secret} <= 12 )); then
    printf '***'
  else
    printf '%s...' "${secret:0:12}"
  fi
}

json_escape() {
  local value="${1:-}"
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\n'/\\n}
  value=${value//$'\r'/\\r}
  value=${value//$'\t'/\\t}
  printf '%s' "$value"
}

cleanup_claude() {
  info "清理 Claude Code 环境变量残留..."
  local var f
  for var in \
    ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_MODEL \
    ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL \
    ANTHROPIC_DEFAULT_HAIKU_MODEL CLAUDE_CODE_SUBAGENT_MODEL \
    CLAUDE_CODE_EFFORT_LEVEL CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC \
    CLAUDE_CODE_ATTRIBUTION_HEADER; do
    unset "$var" 2>/dev/null || true
  done

  for f in "${RC_FILES[@]}"; do
    if [[ -f "$f" ]]; then
      sed -i.bak -E \
        -e '/^[[:space:]]*#[[:space:]]*----[[:space:]]*Claude Code/d' \
        -e '/^[[:space:]]*(export[[:space:]]+)?ANTHROPIC_[A-Za-z0-9_]*=/d' \
        -e '/^[[:space:]]*(export[[:space:]]+)?CLAUDE_CODE_[A-Za-z0-9_]*=/d' \
        -e '/^[[:space:]]*unset[[:space:]]+ANTHROPIC_[A-Za-z0-9_]*$/d' \
        -e '/^[[:space:]]*unset[[:space:]]+CLAUDE_CODE_[A-Za-z0-9_]*$/d' \
        "$f"
    fi
  done

  rm -f "$HOME/.claude/config.json"
}

cleanup_codex() {
  info "清理 CodeX 环境变量残留..."
  local var f
  for var in CODESOME_API_KEY OPENAI_API_KEY CODEX_HOME; do
    unset "$var" 2>/dev/null || true
  done

  for f in "${RC_FILES[@]}"; do
    if [[ -f "$f" ]]; then
      sed -i.bak -E \
        -e '/^[[:space:]]*#[[:space:]]*----[[:space:]]*CodeX/d' \
        -e '/^[[:space:]]*(export[[:space:]]+)?CODESOME_API_KEY=/d' \
        -e '/^[[:space:]]*(export[[:space:]]+)?OPENAI_API_KEY=/d' \
        -e '/^[[:space:]]*(export[[:space:]]+)?CODEX_HOME=/d' \
        -e '/^[[:space:]]*unset[[:space:]]+CODEX_HOME$/d' \
        "$f"
    fi
  done
}

write_claude_settings() {
  local base_url="$1"
  local api_key="$2"
  local api_key_json
  api_key_json=$(json_escape "$api_key")

  cleanup_claude
  mkdir -p "$HOME/.claude"
  cat > "$CLAUDE_SETTINGS" <<EOF
{
  "env": {
    "ANTHROPIC_BASE_URL": "$base_url",
    "ANTHROPIC_AUTH_TOKEN": "$api_key_json",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "CLAUDE_CODE_ATTRIBUTION_HEADER": "0"
  },
  "includeCoAuthoredBy": false
}
EOF
  chmod 600 "$CLAUDE_SETTINGS"

  log "Claude Code 配置已写入: $CLAUDE_SETTINGS"
  echo "ANTHROPIC_BASE_URL=$base_url"
  echo "ANTHROPIC_AUTH_TOKEN=$(mask_secret "$api_key")"
}

write_codex_config() {
  local base_url="$1"
  local model="$2"
  local api_key="$3"
  local api_key_json
  api_key_json=$(json_escape "$api_key")

  cleanup_codex
  mkdir -p "$HOME/.codex"
  cat > "$CODEX_AUTH" <<EOF
{
  "OPENAI_API_KEY": "$api_key_json"
}
EOF

  cat > "$CODEX_CONFIG" <<EOF
model = "$model"
review_model = "$model"
model_reasoning_effort = "xhigh"
model_provider = "codesome"

disable_response_storage = true
network_access = "enabled"
check_for_update_on_startup = false

model_context_window = 1000000
model_auto_compact_token_limit = 900000

[model_providers.codesome]
name = "Codesome"
base_url = "$base_url"
wire_api = "responses"
requires_openai_auth = true

[features]
goals = true
EOF

  chmod 600 "$CODEX_AUTH" "$CODEX_CONFIG"

  log "CodeX 认证已写入: $CODEX_AUTH"
  log "CodeX 配置已写入: $CODEX_CONFIG"
  echo "OPENAI_API_KEY=$(mask_secret "$api_key")"
  echo "base_url=$base_url"
  echo "model=$model"
}

read_api_key() {
  local prompt="$1"
  local api_key="${2:-}"
  if [[ -z "$api_key" ]]; then
    read -rsp "$prompt" api_key
    echo ""
  fi
  if [[ -z "$api_key" ]]; then
    err "API Key 不能为空"
    exit 1
  fi
  printf '%s' "$api_key"
}

configure_choice() {
  local choice="$1"
  local api_key="${2:-}"
  case "$choice" in
    1|claude-codesome)
      api_key=$(read_api_key "请输入你的 Codesome API Key (sk-...): " "$api_key")
      write_claude_settings "https://cc.codesome.ai" "$api_key"
      log "完成。新开终端后运行 claude 验证。"
      ;;
    2|claude-aio)
      api_key=$(read_api_key "请输入你的二合一月卡 API Key (cr-...): " "$api_key")
      write_claude_settings "https://aio.codesome.ai/api" "$api_key"
      log "完成。新开终端后运行 claude 验证。"
      ;;
    3|codex-codesome)
      api_key=$(read_api_key "请输入你的 Codesome API Key (sk-...): " "$api_key")
      write_codex_config "https://cc.codesome.ai/v1" "gpt-5.5" "$api_key"
      log "完成。新开终端后运行 codex 验证。"
      ;;
    4|codex-aio)
      api_key=$(read_api_key "请输入你的二合一月卡 API Key (cr-...): " "$api_key")
      write_codex_config "https://aio.codesome.ai/openai" "gpt-5.5" "$api_key"
      log "完成。新开终端后运行 codex 验证。"
      ;;
    5|vscode-claude-codesome)
      api_key=$(read_api_key "请输入你的 Codesome API Key (sk-...): " "$api_key")
      write_claude_settings "https://cc.codesome.ai" "$api_key"
      log "完成。请完全退出并重启 VS Code。"
      ;;
    *)
      err "无效选择: $choice"
      exit 1
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "============================================"
  echo " Codesome 一键配置脚本"
  echo "============================================"
  echo ""
  echo "请选择要配置的客户端:"
  echo "  1) Claude Code / Claude 模型 / Codesome"
  echo "  2) Claude Code / Claude 模型 / 二合一月卡"
  echo "  3) CodeX / GPT 模型 / Codesome"
  echo "  4) CodeX / GPT 模型 / 二合一月卡"
  echo "  5) VS Code Claude Code 插件 / Claude 模型 / Codesome"
  read -rp "输入 1-5 [1]: " CHOICE
  CHOICE="${CHOICE:-1}"
  echo ""
  configure_choice "$CHOICE" "${1:-}"
fi

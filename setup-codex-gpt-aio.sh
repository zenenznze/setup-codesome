#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err() { echo -e "${RED}[ERR]${NC} $*"; }

BASE_URL="https://aio.codesome.ai/openai"
MODEL="gpt-5.5"
TITLE="CodeX 配置 GPT 模型 - 二合一月卡"

echo "============================================"
echo " $TITLE"
echo "============================================"
echo ""

if [[ -n "${1:-}" ]]; then
  API_KEY="$1"
else
  read -rsp "请输入你的二合一月卡 API Key (cr-...): " API_KEY
  echo ""
fi

if [[ -z "$API_KEY" ]]; then
  err "API Key 不能为空"
  exit 1
fi

CURRENT_SHELL=$(basename "${SHELL:-/bin/bash}")
case "$CURRENT_SHELL" in
  zsh) TARGET_RC="$HOME/.zshrc" ;;
  *) TARGET_RC="$HOME/.bashrc" ;;
esac
mkdir -p "$HOME"
touch "$TARGET_RC"
log "检测到 shell: $CURRENT_SHELL，配置文件: $TARGET_RC"

log "清理 CodeX 旧配置..."
for var in CODESOME_API_KEY CODEX_HOME OPENAI_API_KEY; do
  unset "$var" 2>/dev/null || true
done

for f in ~/.bashrc ~/.bash_profile ~/.zshrc ~/.profile ~/.zprofile ~/.zshenv; do
  if [[ -f "$f" ]]; then
    sed -i.bak -E \
      -e '/^[[:space:]]*export[[:space:]]+CODESOME_API_KEY/d' \
      -e '/^[[:space:]]*export[[:space:]]+OPENAI_API_KEY/d' \
      -e '/^[[:space:]]*unset[[:space:]]+CODEX_HOME/d' \
      -e '/^[[:space:]]*export[[:space:]]+CODEX_HOME/d' \
      -e '/# ---- CodeX via Codesome/d' \
      "$f"
  fi
done

mkdir -p ~/.codex
cat > ~/.codex/config.toml <<EOF
model = "$MODEL"
review_model = "$MODEL"
model_reasoning_effort = "xhigh"
model_provider = "codesome"

disable_response_storage = true
network_access = "enabled"
check_for_update_on_startup = false

model_context_window = 1000000
model_auto_compact_token_limit = 900000

[model_providers.codesome]
name = "Codesome"
base_url = "$BASE_URL"
wire_api = "responses"
env_key = "CODESOME_API_KEY"
EOF
chmod 600 ~/.codex/config.toml

ESCAPED_KEY=$(printf "%s" "$API_KEY" | sed "s/'/'\\\\''/g")
cat >> "$TARGET_RC" <<EOF

# ---- CodeX via Codesome ----
unset CODEX_HOME
export CODEX_HOME="\$HOME/.codex"
export CODESOME_API_KEY='$ESCAPED_KEY'
EOF

export CODEX_HOME="$HOME/.codex"
export CODESOME_API_KEY="$API_KEY"

echo ""
log "配置完成"
echo "CODEX_HOME=$CODEX_HOME"
echo "CODESOME_API_KEY=${CODESOME_API_KEY:0:12}..."
echo "config=$HOME/.codex/config.toml"
echo ""
log "请新开一个终端，输入 codex 验证。"

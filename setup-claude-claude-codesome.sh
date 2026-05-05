#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err() { echo -e "${RED}[ERR]${NC} $*"; }

BASE_URL="https://cc.codesome.ai"
TITLE="Claude Code 配置 Claude 模型 - Codesome 按量/lite/pro/max/codex月卡"

echo "============================================"
echo " $TITLE"
echo "============================================"
echo ""

if [[ -n "${1:-}" ]]; then
  API_KEY="$1"
else
  read -rsp "请输入你的 Codesome API Key (sk-...): " API_KEY
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

log "清理 Claude Code 旧环境变量和残留配置..."
for var in \
  ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_MODEL \
  ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL \
  ANTHROPIC_DEFAULT_HAIKU_MODEL CLAUDE_CODE_SUBAGENT_MODEL \
  CLAUDE_CODE_EFFORT_LEVEL CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC \
  CLAUDE_CODE_ATTRIBUTION_HEADER; do
  unset "$var" 2>/dev/null || true
done

for f in ~/.bashrc ~/.bash_profile ~/.zshrc ~/.profile ~/.zprofile ~/.zshenv; do
  if [[ -f "$f" ]]; then
    sed -i.bak -E \
      -e '/^[[:space:]]*export[[:space:]]+ANTHROPIC_/d' \
      -e '/^[[:space:]]*export[[:space:]]+CLAUDE_CODE_/d' \
      -e '/^[[:space:]]*ANTHROPIC_/d' \
      -e '/^[[:space:]]*CLAUDE_CODE_/d' \
      -e '/# ---- Claude Code via Codesome/d' \
      "$f"
  fi
done

rm -f ~/.claude/config.json ~/.claude/settings.json

ESCAPED_KEY=$(printf "%s" "$API_KEY" | sed "s/'/'\\\\''/g")
cat >> "$TARGET_RC" <<EOF

# ---- Claude Code via Codesome ----
export ANTHROPIC_BASE_URL="$BASE_URL"
export ANTHROPIC_AUTH_TOKEN='$ESCAPED_KEY'
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
EOF

export ANTHROPIC_BASE_URL="$BASE_URL"
export ANTHROPIC_AUTH_TOKEN="$API_KEY"
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

echo ""
log "配置完成"
echo "ANTHROPIC_BASE_URL=$ANTHROPIC_BASE_URL"
echo "ANTHROPIC_AUTH_TOKEN=${ANTHROPIC_AUTH_TOKEN:0:12}..."
echo "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=$CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"
echo ""
log "请新开一个终端，输入 claude 验证。"

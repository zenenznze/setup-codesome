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
SETTINGS_FILE="$HOME/.claude/settings.json"
TITLE="VS Code 插件配置 Claude 模型 - Codesome 按量/lite/pro/max/codex月卡"

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

log "清理当前终端里的 Claude Code 相关环境变量..."
for var in \
  ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_MODEL \
  ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL \
  ANTHROPIC_DEFAULT_HAIKU_MODEL CLAUDE_CODE_SUBAGENT_MODEL \
  CLAUDE_CODE_EFFORT_LEVEL CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC \
  CLAUDE_CODE_ATTRIBUTION_HEADER; do
  unset "$var" 2>/dev/null || true
done

mkdir -p "$HOME/.claude"
if [[ -f "$SETTINGS_FILE" ]]; then
  cp "$SETTINGS_FILE" "$SETTINGS_FILE.bak"
  warn "已备份旧配置: $SETTINGS_FILE.bak"
fi

JSON_KEY=$(printf "%s" "$API_KEY" | sed 's/\\/\\\\/g; s/"/\\"/g')
cat > "$SETTINGS_FILE" <<EOF
{
  "env": {
    "ANTHROPIC_BASE_URL": "$BASE_URL",
    "ANTHROPIC_AUTH_TOKEN": "$JSON_KEY",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "CLAUDE_CODE_ATTRIBUTION_HEADER": "0"
  }
}
EOF
chmod 600 "$SETTINGS_FILE"

echo ""
log "配置完成"
echo "settings=$SETTINGS_FILE"
echo "ANTHROPIC_BASE_URL=$BASE_URL"
echo "ANTHROPIC_AUTH_TOKEN=${API_KEY:0:12}..."
echo ""
log "请完全退出并重启 VS Code，再打开 Claude Code 插件验证。"

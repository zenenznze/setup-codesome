#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err() { echo -e "${RED}[ERR]${NC} $*"; }

BASE_URL="https://v5.codesome.cn/openai"
MODEL="gpt-6-astra"
PROVIDER="codesome_v5"
TITLE="CodeX 配置 GPT 模型 - Codesome V5"

CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
AUTH_FILE="$CODEX_DIR/auth.json"
CONFIG_FILE="$CODEX_DIR/config.toml"

mask_secret() {
  local secret="${1:-}"
  if (( ${#secret} <= 8 )); then
    printf '***'
  else
    printf '%s...%s' "${secret:0:6}" "${secret: -4}"
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

backup_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  local backup="${file}.bak.$(date +%Y%m%d-%H%M%S).$$"
  cp -p "$file" "$backup"
  chmod 600 "$backup" 2>/dev/null || true
  warn "已备份原有配置: $backup"
}

echo "============================================"
echo " $TITLE"
echo "============================================"
echo ""

if [[ -n "${1:-}" ]]; then
  API_KEY="$1"
  warn "通过命令行参数传入 Key 可能留在 shell 历史中，建议下次使用交互式输入。"
else
  if [[ -t 0 ]]; then
    read -rsp "请输入你的 Codesome V5 API Key (cr-...): " API_KEY
    echo "" >&2
  elif [[ -r /dev/tty ]]; then
    read -rsp "请输入你的 Codesome V5 API Key (cr-...): " API_KEY < /dev/tty
    echo "" >&2
  else
    err "无交互终端，无法读取 API Key。请先下载脚本再运行。"
    exit 1
  fi
fi

if [[ -z "${API_KEY:-}" ]]; then
  err "API Key 不能为空"
  exit 1
fi

if [[ "$API_KEY" != cr-* ]]; then
  if [[ -t 0 ]]; then
    warn "Key 不是以 cr- 开头，请确认这是 Codesome V5 的 Key。"
    read -rp "仍要继续? [y/N]: " CONFIRM
    case "${CONFIRM:-}" in
      y|Y|yes|YES) ;;
      *) err "已取消"; exit 1 ;;
    esac
  else
    warn "Key 不是以 cr- 开头，请确认这是 Codesome V5 的 Key。"
  fi
fi

log "Codex 配置目录: $CODEX_DIR"

# 不修改 shell rc，也不自动 unset CODEX_HOME；V5 使用 Codex 文件认证。
for f in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.zprofile" "$HOME/.zshenv"; do
  if [[ -f "$f" ]] && grep -Eq '^[[:space:]]*(export[[:space:]]+)?OPENAI_API_KEY=' "$f"; then
    warn "检测到 $f 中存在 OPENAI_API_KEY 设置，环境变量可能覆盖 auth.json，建议手动移除。"
  fi
done

mkdir -p "$CODEX_DIR"
chmod 700 "$CODEX_DIR" 2>/dev/null || true

backup_file "$CONFIG_FILE"
backup_file "$AUTH_FILE"

JSON_KEY=$(json_escape "$API_KEY")

umask 077
cat > "$AUTH_FILE" <<EOF
{
  "OPENAI_API_KEY": "$JSON_KEY"
}
EOF

cat > "$CONFIG_FILE" <<EOF
model = "$MODEL"
model_provider = "$PROVIDER"

[model_providers.$PROVIDER]
name = "Codesome V5"
base_url = "$BASE_URL"
wire_api = "responses"
requires_openai_auth = true
EOF

chmod 600 "$AUTH_FILE" "$CONFIG_FILE" 2>/dev/null || true

echo ""
log "配置完成"
echo "auth=$AUTH_FILE"
echo "config=$CONFIG_FILE"
echo "OPENAI_API_KEY=$(mask_secret "$API_KEY")"
echo "base_url=$BASE_URL"
echo "model=$MODEL"
echo ""
log "请彻底退出所有 Codex 进程（终端、IDE 插件等）后重新打开，再运行 codex 验证。"
log "旧进程可能仍缓存旧的认证信息，仅重开终端不一定生效。"

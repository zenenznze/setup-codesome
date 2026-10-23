#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/codesome-v5-test.XXXXXX")"
export HOME="$WORK/home"
mkdir -p "$HOME"
unset CODEX_HOME || true

PYTHON="$(command -v python || command -v python3 || true)"
[[ -n "$PYTHON" ]] || { echo "[ERR] 需要 Python 3.11+ 校验 TOML/JSON"; exit 1; }

win_path() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s' "$1"; fi
}

fail() { echo "[FAIL] $*"; exit 1; }
pass() { echo "[PASS] $*"; }

check_no_leak() {
  local file="$1"
  if grep -q 'cr-test-only' "$file"; then
    fail "$file 泄露了明文 Key"
  fi
  pass "无明文 Key 泄露: $file"
}

echo "== 1. setup-codex-gpt-v5.sh 配置 =="
bash "$ROOT/setup-codex-gpt-v5.sh" "cr-test-only" >"$WORK/run1.log" 2>&1 || {
  cat "$WORK/run1.log"; fail "setup-codex-gpt-v5.sh 执行失败"
}
AUTH="$HOME/.codex/auth.json"
CONFIG="$HOME/.codex/config.toml"
[[ -f "$AUTH" && -f "$CONFIG" ]] || fail "未生成 auth.json / config.toml"
check_no_leak "$WORK/run1.log"

"$PYTHON" - "$(win_path "$AUTH")" "$(win_path "$CONFIG")" <<'PY'
import json, sys, tomllib
auth_path, config_path = sys.argv[1], sys.argv[2]
with open(auth_path, encoding="utf-8") as f:
    auth = json.load(f)
with open(config_path, "rb") as f:
    cfg = tomllib.load(f)

assert auth == {"OPENAI_API_KEY": "cr-test-only"}, auth
assert cfg["model"] == "gpt-6-astra", cfg
assert cfg["model_provider"] == "codesome_v5", cfg
provider = cfg["model_providers"]["codesome_v5"]
assert provider["base_url"] == "https://v5.codesome.cn/openai", provider
assert provider["wire_api"] == "responses", provider
assert provider["requires_openai_auth"] is True, provider
assert "env_key" not in provider, provider
PY
pass "TOML/JSON 可解析且字段正确"

grep -q '/openai/responses' "$CONFIG" && fail "base_url 重复附加了 /responses"
pass "base_url 未重复附加 /responses"

if [[ "$(uname -s)" != MINGW* && "$(uname -s)" != MSYS* ]]; then
  [[ "$(stat -c '%a' "$AUTH" 2>/dev/null || stat -f '%Lp' "$AUTH")" == "600" ]] \
    || fail "auth.json 权限不是 600"
  pass "auth.json 权限为 600"
fi

echo "== 2. 重复运行安全更新并备份 =="
bash "$ROOT/setup-codex-gpt-v5.sh" "cr-test-only-2" >"$WORK/run2.log" 2>&1
"$PYTHON" - "$(win_path "$AUTH")" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    assert json.load(f)["OPENAI_API_KEY"] == "cr-test-only-2"
PY
compgen -G "$AUTH.bak.*" >/dev/null || fail "auth.json 未生成备份"
compgen -G "$CONFIG.bak.*" >/dev/null || fail "config.toml 未生成备份"
check_no_leak "$WORK/run2.log"
pass "重复运行可更新配置且保留备份"

echo "== 3. setup.sh 菜单 6 =="
export HOME="$WORK/home-menu"
mkdir -p "$HOME"
printf '6\ncr-test-only\n' | bash "$ROOT/setup.sh" >"$WORK/menu.log" 2>&1 || {
  cat "$WORK/menu.log"; fail "setup.sh 菜单 6 执行失败"
}
grep -q 'Codesome V5' "$WORK/menu.log" || fail "菜单未显示 V5 入口"
"$PYTHON" - "$(win_path "$HOME/.codex/config.toml")" <<'PY'
import sys, tomllib
with open(sys.argv[1], "rb") as f:
    cfg = tomllib.load(f)
assert cfg["model"] == "gpt-6-astra"
assert cfg["model_providers"]["codesome_v5"]["requires_openai_auth"] is True
PY
check_no_leak "$WORK/menu.log"
pass "setup.sh 菜单 6 正常"

echo "== 4. 原有 cc / aio 渠道不受影响 =="
export HOME="$WORK/home-legacy"
mkdir -p "$HOME"
bash "$ROOT/setup-codex-gpt-codesome.sh" "sk-test-only" >/dev/null 2>&1
"$PYTHON" - "$(win_path "$HOME/.codex/config.toml")" <<'PY'
import sys, tomllib
with open(sys.argv[1], "rb") as f:
    cfg = tomllib.load(f)
assert cfg["model"] == "gpt-5.5"
assert cfg["model_providers"]["codesome"]["base_url"] == "https://cc.codesome.ai/v1"
assert cfg["model_providers"]["codesome"]["requires_openai_auth"] is True
PY
bash "$ROOT/setup-codex-gpt-aio.sh" "cr-test-only" >/dev/null 2>&1
"$PYTHON" - "$(win_path "$HOME/.codex/config.toml")" <<'PY'
import sys, tomllib
with open(sys.argv[1], "rb") as f:
    cfg = tomllib.load(f)
assert cfg["model"] == "gpt-5.5"
assert cfg["model_providers"]["codesome"]["base_url"] == "https://aio.codesome.ai/openai"
assert cfg["model_providers"]["codesome"]["requires_openai_auth"] is True
PY
pass "cc / aio 渠道配置保持原值"

echo "== 5. Shell 语法检查 =="
for s in setup-codex-gpt-v5.sh install-codex-gpt-v5.sh setup.sh; do
  bash -n "$ROOT/$s" || fail "$s 语法错误"
done
pass "新增与修改脚本语法正常"

echo ""
echo "全部测试通过 (工作目录: $WORK)"

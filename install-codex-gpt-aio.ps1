param(
  [string]$ApiKey
)

$ErrorActionPreference = "Stop"

$BaseUrl = "https://aio.codesome.ai/openai"
$Model = "gpt-5.5"
$KeyHint = "cr-..."

function Write-Ok($Message) { Write-Host "[OK] $Message" -ForegroundColor Green }
function Fail($Message) { Write-Host "[ERR] $Message" -ForegroundColor Red; exit 1 }

function Read-ApiKey {
  if (-not [string]::IsNullOrWhiteSpace($ApiKey)) {
    return $ApiKey
  }
  $secure = Read-Host "请输入二合一月卡 API Key ($KeyHint)" -AsSecureString
  $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
  }
}

function Ensure-Git {
  if (Get-Command git -ErrorAction SilentlyContinue) { Write-Ok "Git 已安装"; return }
  if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Ok "安装 Git for Windows..."
    winget install Git.Git -e --accept-source-agreements --accept-package-agreements
    return
  }
  Fail "未检测到 Git 或 winget。请先安装 Git for Windows: https://git-scm.com/download/win"
}

function Ensure-Node {
  if ((Get-Command node -ErrorAction SilentlyContinue) -and (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Ok "Node.js / npm 已安装"
    return
  }
  if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Ok "安装 Node.js LTS..."
    winget install OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements
    return
  }
  Fail "未检测到 Node.js/npm 或 winget。请先安装 Node.js: https://nodejs.org/en/download"
}

function Ensure-Codex {
  if (Get-Command codex -ErrorAction SilentlyContinue) { Write-Ok "CodeX 已安装"; return }
  Ensure-Node
  Write-Ok "安装 CodeX CLI..."
  npm i -g @openai/codex
  if ($LASTEXITCODE -ne 0) {
    npm i -g @openai/codex --registry=https://registry.npmmirror.com
  }
}

function Configure-Codex($Key) {
  $CodexHome = Join-Path $HOME ".codex"
  New-Item -ItemType Directory -Force $CodexHome | Out-Null
  @"
model = "$Model"
review_model = "$Model"
model_reasoning_effort = "xhigh"
model_provider = "codesome"

disable_response_storage = true
network_access = "enabled"
windows_wsl_setup_acknowledged = true
check_for_update_on_startup = false

model_context_window = 1000000
model_auto_compact_token_limit = 900000

[model_providers.codesome]
name = "Codesome"
base_url = "$BaseUrl"
wire_api = "responses"
requires_openai_auth = true

[features]
goals = true
"@ | Set-Content -Encoding UTF8 (Join-Path $CodexHome "config.toml")
  @{ OPENAI_API_KEY = $Key } | ConvertTo-Json -Depth 2 | Set-Content -Encoding UTF8 (Join-Path $CodexHome "auth.json")
  [Environment]::SetEnvironmentVariable("CODEX_HOME", $null, "User")
  [Environment]::SetEnvironmentVariable("CODESOME_API_KEY", $null, "User")
  [Environment]::SetEnvironmentVariable("OPENAI_API_KEY", $null, "User")
  Remove-Item Env:CODEX_HOME -ErrorAction SilentlyContinue
  Remove-Item Env:CODESOME_API_KEY -ErrorAction SilentlyContinue
  Remove-Item Env:OPENAI_API_KEY -ErrorAction SilentlyContinue
}

Write-Host "============================================"
Write-Host " 完整安装 + 配置：CodeX / GPT 模型 / 二合一月卡"
Write-Host "============================================"
$Key = Read-ApiKey
if ([string]::IsNullOrWhiteSpace($Key)) { Fail "API Key 不能为空" }
Ensure-Git
Ensure-Codex
Configure-Codex $Key
Write-Ok "完成。请新开 PowerShell，输入 codex 验证。"

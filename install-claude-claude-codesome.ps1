param(
  [string]$ApiKey
)

$ErrorActionPreference = "Stop"

$BaseUrl = "https://cc.codesome.ai"
$KeyHint = "sk-..."

function Write-Ok($Message) { Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warn($Message) { Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Fail($Message) { Write-Host "[ERR] $Message" -ForegroundColor Red; exit 1 }

function Read-ApiKey {
  if (-not [string]::IsNullOrWhiteSpace($ApiKey)) {
    return $ApiKey
  }
  $secure = Read-Host "请输入 Codesome API Key ($KeyHint)" -AsSecureString
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

function Ensure-Claude {
  if (Get-Command claude -ErrorAction SilentlyContinue) { Write-Ok "Claude Code 已安装"; return }
  Write-Ok "安装 Claude Code..."
  irm https://claude.ai/install.ps1 | iex
}

function Configure-Claude($Key) {
  $vars = @(
    "ANTHROPIC_BASE_URL",
    "ANTHROPIC_AUTH_TOKEN",
    "ANTHROPIC_MODEL",
    "ANTHROPIC_DEFAULT_OPUS_MODEL",
    "ANTHROPIC_DEFAULT_SONNET_MODEL",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL",
    "CLAUDE_CODE_SUBAGENT_MODEL",
    "CLAUDE_CODE_EFFORT_LEVEL",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC",
    "CLAUDE_CODE_ATTRIBUTION_HEADER"
  )
  foreach ($var in $vars) {
    [Environment]::SetEnvironmentVariable($var, $null, "User")
    Remove-Item "Env:$var" -ErrorAction SilentlyContinue
  }
  Remove-Item "$HOME\.claude\config.json" -ErrorAction SilentlyContinue
  $ClaudeHome = Join-Path $HOME ".claude"
  New-Item -ItemType Directory -Force $ClaudeHome | Out-Null
  @{
    env = @{
      ANTHROPIC_BASE_URL = $BaseUrl
      ANTHROPIC_AUTH_TOKEN = $Key
      CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"
      CLAUDE_CODE_ATTRIBUTION_HEADER = "0"
    }
    includeCoAuthoredBy = $false
  } | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $ClaudeHome "settings.json")
}

Write-Host "============================================"
Write-Host " 完整安装 + 配置：Claude Code / Claude 模型 / Codesome"
Write-Host "============================================"
$Key = Read-ApiKey
if ([string]::IsNullOrWhiteSpace($Key)) { Fail "API Key 不能为空" }
Ensure-Git
Ensure-Claude
Configure-Claude $Key
Write-Ok "完成。请新开 PowerShell，输入 claude 验证。"

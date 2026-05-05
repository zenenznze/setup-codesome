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

function Install-VSCodeExtension {
  if (Get-Command code -ErrorAction SilentlyContinue) {
    Write-Ok "安装 VS Code Claude Code 扩展..."
    code --install-extension anthropic.claude-code
    return
  }
  Write-Warn "未检测到 code 命令，跳过扩展自动安装。请在 VS Code 插件市场搜索 Claude Code 安装。"
}

function Configure-VSCodeClaude($Key) {
  $ClaudeHome = Join-Path $HOME ".claude"
  New-Item -ItemType Directory -Force $ClaudeHome | Out-Null
  $settings = @{
    env = @{
      ANTHROPIC_BASE_URL = $BaseUrl
      ANTHROPIC_AUTH_TOKEN = $Key
      CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"
      CLAUDE_CODE_ATTRIBUTION_HEADER = "0"
    }
  } | ConvertTo-Json -Depth 4
  $settings | Set-Content -Encoding UTF8 (Join-Path $ClaudeHome "settings.json")
}

Write-Host "============================================"
Write-Host " 完整安装 + 配置：VS Code 插件 / Claude 模型 / Codesome"
Write-Host "============================================"
$Key = Read-ApiKey
if ([string]::IsNullOrWhiteSpace($Key)) { Fail "API Key 不能为空" }
Ensure-Git
Ensure-Claude
Install-VSCodeExtension
Configure-VSCodeClaude $Key
Write-Ok "完成。请完全退出并重启 VS Code。"

param(
  [string]$ApiKey
)

$ErrorActionPreference = "Stop"

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

function Install-CCSwitchHint {
  if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Warn "ccswitch 需要图形安装包配置。请从 https://github.com/farion1231/cc-switch/releases 下载 .msi 安装。"
    return
  }
  Write-Warn "请手动安装 ccswitch: https://github.com/farion1231/cc-switch/releases"
}

Write-Host "============================================"
Write-Host " 完整安装入口：Claude Code / GPT 模型 / Codesome"
Write-Host "============================================"
$Key = Read-ApiKey
if ([string]::IsNullOrWhiteSpace($Key)) { Fail "API Key 不能为空" }
Ensure-Git
Ensure-Claude
Install-CCSwitchHint
Write-Warn "Claude Code 使用 GPT 模型需要 ccswitch 做 API 格式转换，不能只靠脚本写环境变量完成。"
Write-Host "请在 ccswitch 中填写："
Write-Host "供应商名称: codesome"
Write-Host "请求地址: https://cc.codesome.ai"
Write-Host "API Key: $($Key.Substring(0, [Math]::Min(12, $Key.Length)))..."
Write-Host "API 格式: openai response api"
Write-Host "模型 ID: gpt-5.5"
Write-Host "并打开 ccswitch 本地代理开关，然后新开 PowerShell 运行 claude。"

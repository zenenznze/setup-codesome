param(
  [string]$ApiKey
)

$ErrorActionPreference = "Stop"

$BaseUrl = "https://v5.codesome.cn/openai"
$Model = "gpt-6-astra"
$KeyHint = "cr-..."

function Write-Ok($Message) { Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warn($Message) { Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Fail($Message) { Write-Host "[ERR] $Message" -ForegroundColor Red; exit 1 }

function Read-ApiKey {
  if (-not [string]::IsNullOrWhiteSpace($ApiKey)) {
    return $ApiKey
  }
  $secure = Read-Host "请输入 Codesome V5 API Key ($KeyHint)" -AsSecureString
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

function Backup-File($Path) {
  if (-not (Test-Path $Path)) { return }
  $Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
  $Backup = "$Path.bak.$Stamp"
  Copy-Item $Path $Backup -Force
  Write-Warn "已备份原有配置: $Backup"
}

function Limit-FileAccess($Path) {
  try {
    $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $Rule = $Identity + ':(R,W)'
    icacls $Path /inheritance:r /grant:r $Rule | Out-Null
  } catch {
    Write-Warn "无法收紧 $Path 的 ACL，请手动检查权限。"
  }
}

function Configure-Codex($Key) {
  $CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
  New-Item -ItemType Directory -Force $CodexHome | Out-Null
  $AuthPath = Join-Path $CodexHome "auth.json"
  $ConfigPath = Join-Path $CodexHome "config.toml"

  Backup-File $ConfigPath
  Backup-File $AuthPath

  $Config = @"
model = "$Model"
model_provider = "codesome_v5"

[model_providers.codesome_v5]
name = "Codesome V5"
base_url = "$BaseUrl"
wire_api = "responses"
requires_openai_auth = true
"@
  $Auth = @{ OPENAI_API_KEY = $Key } | ConvertTo-Json -Depth 2
  $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($ConfigPath, $Config, $Utf8NoBom)
  [System.IO.File]::WriteAllText($AuthPath, $Auth, $Utf8NoBom)

  Limit-FileAccess $AuthPath
  Limit-FileAccess $ConfigPath

  Write-Ok "CodeX 认证已写入: $AuthPath"
  Write-Ok "CodeX 配置已写入: $ConfigPath"
}

Write-Host "============================================"
Write-Host " 完整安装 + 配置：CodeX / GPT 模型 / Codesome V5"
Write-Host "============================================"
$Key = Read-ApiKey
if ([string]::IsNullOrWhiteSpace($Key)) { Fail "API Key 不能为空" }
if (-not $Key.StartsWith("cr-")) {
  Write-Warn "Key 不是以 cr- 开头，请确认这是 Codesome V5 的 Key。"
  $Confirm = Read-Host "仍要继续? [y/N]"
  if ($Confirm -notmatch '^(y|yes)$') { Fail "已取消" }
}
Ensure-Git
Ensure-Codex
Configure-Codex $Key
$Masked = if ($Key.Length -le 8) { "***" } else { "$($Key.Substring(0,6))...$($Key.Substring($Key.Length-4))" }
Write-Host "OPENAI_API_KEY=$Masked"
Write-Host "base_url=$BaseUrl"
Write-Host "model=$Model"
Write-Ok "完成。请彻底退出所有 Codex 进程后重新打开 PowerShell，再输入 codex 验证。"

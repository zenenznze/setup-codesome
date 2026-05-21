# setup-codesome

Codesome 一键配置脚本集合。用户通过 `curl` 下载脚本，运行后只需要按提示粘贴 API Key。

脚本分三类：

- `setup.sh`：统一交互式配置入口，选择要配置的客户端后再输入 API Key。
- `setup-*.sh`：只做配置，适合已经装好 Claude Code / CodeX / VS Code 插件的用户。**大多数时候你只需要这个。**
- `install-*.ps1`：Windows PowerShell 完整安装 + 配置入口。
- `install-*.sh`：macOS / Linux / WSL / Git Bash 完整安装 + 配置入口，适合首次安装的用户。

如果你已经装过工具，优先使用下面的 `setup.sh` 或「仅配置」脚本；只有全新环境才需要完整安装脚本。

## 统一交互式配置

```bash
curl -fsSLO https://raw.githubusercontent.com/zenenznze/setup-codesome/master/setup.sh
chmod +x setup.sh
./setup.sh
```

脚本会让你选择：

- Claude Code / Claude 模型 / Codesome
- Claude Code / Claude 模型 / 二合一月卡
- CodeX / GPT 模型 / Codesome
- CodeX / GPT 模型 / 二合一月卡
- VS Code Claude Code 插件 / Claude 模型 / Codesome

清理策略：

- 配置 Claude Code 或 VS Code 插件时，只清理 Claude Code 相关环境变量残留，并写入 `~/.claude/settings.json`。
- 配置 CodeX 时，只清理 CodeX 相关环境变量残留，并写入 `~/.codex/auth.json` 和 `~/.codex/config.toml`。
- 不会因为配置某一个客户端而删除另一个客户端的配置文件。

## 脚本列表

### 仅配置脚本

| 序号 | 脚本 | 用途 | 适用用户 |
| --- | --- | --- | --- |
| 1 | `setup-claude-claude-codesome.sh` | Claude Code 里配置 Claude 模型 | 按量分组 lite / pro / max、codex 月卡 |
| 2 | `setup-claude-claude-aio.sh` | Claude Code 里配置 Claude 模型 | 二合一月卡 |
| 3 | `setup-claude-gpt-codesome.sh` | Claude Code 里配置 GPT 模型 | 暂不支持一键直配，需要 ccswitch |
| 4 | `setup-codex-gpt-codesome.sh` | CodeX 里配置 GPT 模型 | 按量 codex 分组、codex 月卡 |
| 5 | `setup-codex-gpt-aio.sh` | CodeX 里配置 GPT 模型 | 二合一月卡 |
| 6 | `setup-vscode-claude-codesome.sh` | VS Code 插件里使用 Claude 模型 | 按量分组 lite / pro / max、codex 月卡 |

### 完整安装 + 配置脚本

| 序号 | 脚本 | 用途 | 适用用户 |
| --- | --- | --- | --- |
| 1 | `install-claude-claude-codesome.ps1` / `install-claude-claude-codesome.sh` | 安装 Claude Code，并配置 Claude 模型 | 按量分组 lite / pro / max、codex 月卡 |
| 2 | `install-claude-claude-aio.ps1` / `install-claude-claude-aio.sh` | 安装 Claude Code，并配置 Claude 模型 | 二合一月卡 |
| 3 | `install-claude-gpt-codesome.ps1` / `install-claude-gpt-codesome.sh` | 安装 Claude Code，并引导 ccswitch 配置 GPT 模型 | 按量 codex 分组、codex 月卡 |
| 4 | `install-codex-gpt-codesome.ps1` / `install-codex-gpt-codesome.sh` | 安装 CodeX，并配置 GPT 模型 | 按量 codex 分组、codex 月卡 |
| 5 | `install-codex-gpt-aio.ps1` / `install-codex-gpt-aio.sh` | 安装 CodeX，并配置 GPT 模型 | 二合一月卡 |
| 6 | `install-vscode-claude-codesome.ps1` / `install-vscode-claude-codesome.sh` | 安装 Claude Code 和 VS Code Claude Code 插件，并写入插件配置 | 按量分组 lite / pro / max、codex 月卡 |

## GitHub 快速使用：仅配置

### 1. Claude Code 配置 Claude 模型

适用于按量分组 lite / pro / max、codex 月卡。

```bash
curl -fsSLO https://raw.githubusercontent.com/zenenznze/setup-codesome/master/setup-claude-claude-codesome.sh
chmod +x setup-claude-claude-codesome.sh
./setup-claude-claude-codesome.sh
```

写入 `~/.claude/settings.json`：

- `ANTHROPIC_BASE_URL=https://cc.codesome.ai`
- `ANTHROPIC_AUTH_TOKEN=你输入的 sk-... API Key`
- `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`

验证：

```bash
claude
```

### 2. Claude Code 配置 Claude 模型，二合一月卡

```bash
curl -fsSLO https://raw.githubusercontent.com/zenenznze/setup-codesome/master/setup-claude-claude-aio.sh
chmod +x setup-claude-claude-aio.sh
./setup-claude-claude-aio.sh
```

写入 `~/.claude/settings.json`：

- `ANTHROPIC_BASE_URL=https://aio.codesome.ai/api`
- `ANTHROPIC_AUTH_TOKEN=你输入的 cr-... API Key`
- `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`

验证：

```bash
claude
```

### 3. Claude Code 配置 GPT 模型

这个场景需要 `ccswitch` 做 API 格式转换，不能只靠写环境变量稳定完成。脚本仅保留为说明入口：

```bash
curl -fsSLO https://raw.githubusercontent.com/zenenznze/setup-codesome/master/setup-claude-gpt-codesome.sh
chmod +x setup-claude-gpt-codesome.sh
./setup-claude-gpt-codesome.sh
```

请在 `ccswitch` 中配置：

- 供应商名称：`codesome`
- 请求地址：`https://cc.codesome.ai`
- API 格式：`openai response api`
- 模型 ID：`gpt-5.5`
- 开启本地代理开关

### 4. CodeX 配置 GPT 模型

适用于按量 codex 分组、codex 月卡。

```bash
curl -fsSLO https://raw.githubusercontent.com/zenenznze/setup-codesome/master/setup-codex-gpt-codesome.sh
chmod +x setup-codex-gpt-codesome.sh
./setup-codex-gpt-codesome.sh
```

写入：

- `~/.codex/auth.json`
- `~/.codex/config.toml`
- `OPENAI_API_KEY=你输入的 sk-... API Key`
- `base_url=https://cc.codesome.ai/v1`
- `model=gpt-5.5`

验证：

```bash
codex
```

### 5. CodeX 配置 GPT 模型，二合一月卡

```bash
curl -fsSLO https://raw.githubusercontent.com/zenenznze/setup-codesome/master/setup-codex-gpt-aio.sh
chmod +x setup-codex-gpt-aio.sh
./setup-codex-gpt-aio.sh
```

写入：

- `~/.codex/auth.json`
- `~/.codex/config.toml`
- `OPENAI_API_KEY=你输入的 cr-... API Key`
- `base_url=https://aio.codesome.ai/openai`
- `model=gpt-5.5`

验证：

```bash
codex
```

### 6. VS Code 插件里使用 Claude 模型

适用于按量分组 lite / pro / max、codex 月卡。

```bash
curl -fsSLO https://raw.githubusercontent.com/zenenznze/setup-codesome/master/setup-vscode-claude-codesome.sh
chmod +x setup-vscode-claude-codesome.sh
./setup-vscode-claude-codesome.sh
```

写入 `~/.claude/settings.json`：

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://cc.codesome.ai",
    "ANTHROPIC_AUTH_TOKEN": "你的apikey",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "CLAUDE_CODE_ATTRIBUTION_HEADER": "0"
  }
}
```

配置完成后，完全退出并重启 VS Code。

## GitHub 快速使用：完整安装 + 配置

### 1. Claude Code 配置 Claude 模型

适用于按量分组 lite / pro / max、codex 月卡。

Windows PowerShell：

```powershell
irm https://raw.githubusercontent.com/zenenznze/setup-codesome/master/install-claude-claude-codesome.ps1 | iex
```

macOS / Linux / WSL / Git Bash：

```bash
curl -fsSLO https://raw.githubusercontent.com/zenenznze/setup-codesome/master/install-claude-claude-codesome.sh
chmod +x install-claude-claude-codesome.sh
./install-claude-claude-codesome.sh
```

会自动安装：

- Windows：Claude Code 官方 PowerShell 安装器
- macOS / Linux / WSL：Node.js LTS，`@anthropic-ai/claude-code`

会写入 `~/.claude/settings.json`：

- `ANTHROPIC_BASE_URL=https://cc.codesome.ai`
- `ANTHROPIC_AUTH_TOKEN=你输入的 sk-... API Key`
- `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`

验证：

```bash
claude
```

### 2. Claude Code 配置 Claude 模型，二合一月卡

Windows PowerShell：

```powershell
irm https://raw.githubusercontent.com/zenenznze/setup-codesome/master/install-claude-claude-aio.ps1 | iex
```

macOS / Linux / WSL / Git Bash：

```bash
curl -fsSLO https://raw.githubusercontent.com/zenenznze/setup-codesome/master/install-claude-claude-aio.sh
chmod +x install-claude-claude-aio.sh
./install-claude-claude-aio.sh
```

会自动安装 Claude Code，并写入 `~/.claude/settings.json`：

- `ANTHROPIC_BASE_URL=https://aio.codesome.ai/api`
- `ANTHROPIC_AUTH_TOKEN=你输入的 cr-... API Key`
- `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`

验证：

```bash
claude
```

### 3. Claude Code 配置 GPT 模型

这个场景需要 `ccswitch` 做 API 格式转换，不能只靠写环境变量稳定完成。完整脚本会安装 Claude Code，并在 macOS 上尝试通过 Homebrew 安装 ccswitch；Windows 会提示下载 `.msi`。

Windows PowerShell：

```powershell
irm https://raw.githubusercontent.com/zenenznze/setup-codesome/master/install-claude-gpt-codesome.ps1 | iex
```

macOS / Linux / WSL / Git Bash：

```bash
curl -fsSLO https://raw.githubusercontent.com/zenenznze/setup-codesome/master/install-claude-gpt-codesome.sh
chmod +x install-claude-gpt-codesome.sh
./install-claude-gpt-codesome.sh
```

请在 `ccswitch` 中配置：

- 供应商名称：`codesome`
- 请求地址：`https://cc.codesome.ai`
- API 格式：`openai response api`
- 模型 ID：`gpt-5.5`
- 开启本地代理开关

### 4. CodeX 配置 GPT 模型

适用于按量 codex 分组、codex 月卡。

Windows PowerShell：

```powershell
irm https://raw.githubusercontent.com/zenenznze/setup-codesome/master/install-codex-gpt-codesome.ps1 | iex
```

macOS / Linux / WSL / Git Bash：

```bash
curl -fsSLO https://raw.githubusercontent.com/zenenznze/setup-codesome/master/install-codex-gpt-codesome.sh
chmod +x install-codex-gpt-codesome.sh
./install-codex-gpt-codesome.sh
```

会自动安装：

- Windows：Node.js LTS（优先 `winget`），`@openai/codex`
- macOS / Linux / WSL：Node.js LTS，`@openai/codex`

会写入：

- `~/.codex/auth.json`
- `~/.codex/config.toml`
- `OPENAI_API_KEY=你输入的 sk-... API Key`
- `base_url=https://cc.codesome.ai/v1`
- `model=gpt-5.5`

验证：

```bash
codex
```

### 5. CodeX 配置 GPT 模型，二合一月卡

Windows PowerShell：

```powershell
irm https://raw.githubusercontent.com/zenenznze/setup-codesome/master/install-codex-gpt-aio.ps1 | iex
```

macOS / Linux / WSL / Git Bash：

```bash
curl -fsSLO https://raw.githubusercontent.com/zenenznze/setup-codesome/master/install-codex-gpt-aio.sh
chmod +x install-codex-gpt-aio.sh
./install-codex-gpt-aio.sh
```

会自动安装 CodeX，并写入：

- `~/.codex/auth.json`
- `~/.codex/config.toml`
- `OPENAI_API_KEY=你输入的 cr-... API Key`
- `base_url=https://aio.codesome.ai/openai`
- `model=gpt-5.5`

验证：

```bash
codex
```

### 6. VS Code 插件里使用 Claude 模型

适用于按量分组 lite / pro / max、codex 月卡。

Windows PowerShell：

```powershell
irm https://raw.githubusercontent.com/zenenznze/setup-codesome/master/install-vscode-claude-codesome.ps1 | iex
```

macOS / Linux / WSL / Git Bash：

```bash
curl -fsSLO https://raw.githubusercontent.com/zenenznze/setup-codesome/master/install-vscode-claude-codesome.sh
chmod +x install-vscode-claude-codesome.sh
./install-vscode-claude-codesome.sh
```

会自动安装 Claude Code，并在检测到 `code` 命令时安装 VS Code 扩展：

- `anthropic.claude-code`

会写入 `~/.claude/settings.json`。配置完成后，完全退出并重启 VS Code。

## 通用说明

- 脚本运行后只需要输入 API Key。
- 也可以直接传 key，例如：`./install-codex-gpt-codesome.sh "sk-..."`
- Windows PowerShell 可以直接使用 `irm ...ps1 | iex`，不需要先安装 Git Bash。
- 脚本会按所选客户端清理相关旧环境变量，再写入对应配置文件。
- 清理 shell 配置文件中的旧环境变量时会生成 `.bak` 备份。
- 配置后建议新开一个终端验证。
- 如果使用桌面客户端或 VS Code 插件，需要完全退出并重启应用。

## 测试记录

- [Linux 远端真机完整安装测试：2026-05-05](docs/linux-remote-install-test-2026-05-05.md)

## 开源协议

MIT License

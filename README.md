# setup-codesome

Codesome 一键配置脚本集合。用户通过 `curl` 下载脚本，运行后只需要按提示粘贴 API Key。

适用环境：Linux / macOS / WSL 的 Bash 或 Zsh。Windows PowerShell 用户请参考对应教程里的 PowerShell 命令。

## 脚本列表

| 序号 | 脚本 | 用途 | 适用用户 |
| --- | --- | --- | --- |
| 1 | `setup-claude-claude-codesome.sh` | Claude Code 里配置 Claude 模型 | 按量分组 lite / pro / max、codex 月卡 |
| 2 | `setup-claude-claude-aio.sh` | Claude Code 里配置 Claude 模型 | 二合一月卡 |
| 3 | `setup-claude-gpt-codesome.sh` | Claude Code 里配置 GPT 模型 | 暂不支持一键直配，需要 ccswitch |
| 4 | `setup-codex-gpt-codesome.sh` | CodeX 里配置 GPT 模型 | 按量 codex 分组、codex 月卡 |
| 5 | `setup-codex-gpt-aio.sh` | CodeX 里配置 GPT 模型 | 二合一月卡 |
| 6 | `setup-vscode-claude-codesome.sh` | VS Code 插件里使用 Claude 模型 | 按量分组 lite / pro / max、codex 月卡 |

## GitHub 快速使用

### 1. Claude Code 配置 Claude 模型

适用于按量分组 lite / pro / max、codex 月卡。

```bash
curl -fsSLO https://raw.githubusercontent.com/zenenznze/setup-codesome/master/setup-claude-claude-codesome.sh
chmod +x setup-claude-claude-codesome.sh
./setup-claude-claude-codesome.sh
```

写入：

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

写入：

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

- `~/.codex/config.toml`
- `CODEX_HOME=$HOME/.codex`
- `CODESOME_API_KEY=你输入的 sk-... API Key`
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

- `~/.codex/config.toml`
- `CODEX_HOME=$HOME/.codex`
- `CODESOME_API_KEY=你输入的 cr-... API Key`
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

## Gitee 快速使用

国内网络优先使用 Gitee raw 链接。仓库创建并同步后，可把上面的 GitHub 地址替换为：

```text
https://gitee.com/hicodesome/setup-codesome/raw/master/<脚本名>
```

示例：

```bash
curl -fsSLO https://gitee.com/hicodesome/setup-codesome/raw/master/setup-codex-gpt-codesome.sh
chmod +x setup-codex-gpt-codesome.sh
./setup-codex-gpt-codesome.sh
```

## 通用说明

- 脚本运行后只需要输入 API Key。
- 也可以直接传 key，例如：`./setup-codex-gpt-codesome.sh "sk-..."`
- 脚本会清理相关旧环境变量，再写入新配置。
- 修改 shell 配置文件时会生成 `.bak` 备份。
- 配置后建议新开一个终端验证。
- 如果使用桌面客户端或 VS Code 插件，需要完全退出并重启应用。

## 开源协议

MIT License

# setup-codesome

Linux 上一键清理旧配置并配置 Claude Code / CodeX 连接 Codesome 的脚本集合。

---

## 脚本列表

| 脚本 | 用途 | 方案 |
|------|------|------|
| `setup-claude-codesome.sh` | Claude Code (cc) | Codesome |
| `setup-codex-codesome.sh` | CodeX | Codesome |

---

## 1. setup-claude-codesome.sh

配置 Claude Code，使用 Codesome 官方 API 地址（`https://cc.codesome.ai`）。

### 快速使用

```bash
curl -O https://raw.githubusercontent.com/zenenznze/setup-codesome/main/setup-claude-codesome.sh
chmod +x setup-claude-codesome.sh
./setup-claude-codesome.sh
```

也可以直接传 key：

```bash
./setup-claude-codesome.sh "sk-..."
```

### 写入的环境变量

| 变量 | 值 |
|------|-----|
| `ANTHROPIC_BASE_URL` | `https://cc.codesome.ai` |
| `ANTHROPIC_AUTH_TOKEN` | 你输入的 key |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | `1` |

> 与 dpsk 方案不同，此方案不设置 `ANTHROPIC_MODEL` 等模型覆盖变量。脚本会自动清理之前 dpsk 方案残留的模型环境变量。

### 验证

```bash
claude
```

---

## 2. setup-codex-codesome.sh

配置 CodeX（OpenAI CLI），使用 Codesome 方案，模型 gpt-5.5。

### 快速使用

```bash
curl -O https://raw.githubusercontent.com/zenenznze/setup-codesome/main/setup-codex-codesome.sh
chmod +x setup-codex-codesome.sh
./setup-codex-codesome.sh
```

也可以直接传 key：

```bash
./setup-codex-codesome.sh "sk-..."
```

### 写入内容

- `~/.codex/config.toml` — CodeX 主配置（模型 gpt-5.5，provider codesome，地址 `https://cc.codesome.ai/v1`）
- shell 配置中写入 `CODEX_HOME` 和 `CODESOME_API_KEY`

### 验证

```bash
codex
```

---

## 通用说明

全部脚本均：

- **交互式**：运行后只需输入 API Key，其余全自动
- 自动检测 bash / zsh
- 先清理旧配置（环境变量、shell 配置文件、残留 JSON/TOML），再写入新配置
- 支持命令行参数传 key，方便自动化：`./xxx.sh "key"`

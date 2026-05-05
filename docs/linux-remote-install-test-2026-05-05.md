# Linux Remote Full Install Test - 2026-05-05

This document records the real-machine Linux test for the full install scripts.

## Environment

- SSH host alias: `Test`
- Remote host: `debian-1`
- User: `joe`
- OS: Debian Linux, x86_64
- Kernel: `6.16.6-x64v3-xanmod1`
- Sudo: passwordless sudo available
- Test directory: `/tmp/setup-codesome-test`

## Scope

The goal was to verify the Linux path for the `install-*.sh` full scripts after removing existing installations.

The test intentionally removed:

- `node`
- `npm`
- `git`
- `codex`
- `claude`
- `~/.nvm`
- `~/.npm`
- `~/.codex`
- `~/.claude`
- related shell configuration lines for `ANTHROPIC_*`, `CLAUDE_CODE_*`, `CODESOME_API_KEY`, and `CODEX_HOME`

After cleanup, these commands were confirmed absent:

- `node`
- `npm`
- `git`
- `codex`
- `claude`

`curl` and `sudo` remained available.

## Scripts Tested

### `install-codex-gpt-codesome.sh`

Result: passed.

Observed behavior:

- Installed `git` through `apt-get`.
- Installed Node.js LTS through `nvm`.
- Installed `@openai/codex` through `npm`.
- Ran the existing `setup-codex-gpt-codesome.sh` configuration path.
- Created `~/.codex/config.toml`.

Verified config:

```text
model = "gpt-5.5"
review_model = "gpt-5.5"
base_url = "https://cc.codesome.ai/v1"
env_key = "CODESOME_API_KEY"
```

### `install-claude-claude-codesome.sh`

Result: passed.

Observed behavior:

- Reused installed `git` and Node.js.
- Installed `@anthropic-ai/claude-code` through `npm`.
- Ran the existing `setup-claude-claude-codesome.sh` configuration path.

Verified config in `~/.bashrc`:

```text
export ANTHROPIC_BASE_URL="https://cc.codesome.ai"
export ANTHROPIC_AUTH_TOKEN='test-key-install-claude-codesome'
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
```

### `install-claude-claude-aio.sh`

Result: passed.

Observed behavior:

- Detected `git` and Claude Code as already installed.
- Ran the existing `setup-claude-claude-aio.sh` configuration path.

Verified config in `~/.bashrc`:

```text
export ANTHROPIC_BASE_URL="https://aio.codesome.ai/api"
export ANTHROPIC_AUTH_TOKEN='test-key-install-claude-aio'
```

### `install-codex-gpt-aio.sh`

Result: passed.

Observed behavior:

- Detected `git` and CodeX as already installed.
- Ran the existing `setup-codex-gpt-aio.sh` configuration path.

Verified config:

```text
model = "gpt-5.5"
review_model = "gpt-5.5"
base_url = "https://aio.codesome.ai/openai"
env_key = "CODESOME_API_KEY"
```

### `install-vscode-claude-codesome.sh`

Result: passed with expected Linux limitation.

Observed behavior:

- Detected `git` and Claude Code as already installed.
- Did not find the `code` command, so skipped automatic VS Code extension installation.
- Wrote `~/.claude/settings.json`.

Verified config:

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://cc.codesome.ai",
    "ANTHROPIC_AUTH_TOKEN": "test-key-install-vscode",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "CLAUDE_CODE_ATTRIBUTION_HEADER": "0"
  }
}
```

### `install-claude-gpt-codesome.sh`

Result: passed with expected product limitation.

Observed behavior:

- Detected `git` and Claude Code as already installed.
- On Linux, reported that `ccswitch` must be installed and enabled manually.
- Printed the required ccswitch configuration:
  - provider name: `codesome`
  - request URL: `https://cc.codesome.ai`
  - API format: `openai response api`
  - model ID: `gpt-5.5`

This matches the current limitation that Claude Code GPT usage requires ccswitch API-format conversion.

## Final Remote State

After the test, the remote machine had:

```text
git version 2.39.5
node v24.15.0
npm 11.12.1
codex-cli 0.128.0
Claude Code 2.1.128
```

Command paths:

```text
git=/usr/bin/git
node=/home/joe/.nvm/versions/node/v24.15.0/bin/node
npm=/home/joe/.nvm/versions/node/v24.15.0/bin/npm
codex=/home/joe/.nvm/versions/node/v24.15.0/bin/codex
claude=/home/joe/.nvm/versions/node/v24.15.0/bin/claude
```

## Follow-up Change From Test

The test identified one missing dependency in the full scripts: `git` was not explicitly installed.

Fix applied:

- Added `ensure_git` to all six `install-*.sh` scripts.
- Linux/WSL path installs `git` with `sudo apt-get update && sudo apt-get install -y git`.
- macOS path uses Homebrew when available, otherwise prompts Command Line Tools.
- Windows path uses `winget install Git.Git` when available, otherwise tells the user to install Git for Windows.

The fix was committed as:

```text
c7a5ffe Install git in full setup scripts
```

## Known Limitations

- This test only covered Linux.
- Windows PowerShell `.ps1` entrypoints and macOS installation paths are implemented but not real-machine tested in this run.
- VS Code extension auto-install requires the `code` command to be available in PATH.
- Claude Code GPT usage still requires ccswitch; scripts cannot fully automate the ccswitch GUI configuration.

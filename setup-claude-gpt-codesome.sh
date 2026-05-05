#!/usr/bin/env bash
set -euo pipefail

echo "============================================"
echo " Claude Code 配置 GPT 模型 - 暂不提供一键直配"
echo "============================================"
echo ""
echo "Claude Code 直接读取的是 Anthropic 格式接口。"
echo "在 Claude Code 里使用 GPT 模型需要 ccswitch 做 API 格式转换，并打开本地代理开关。"
echo ""
echo "因此这个场景不能只靠写环境变量稳定完成。请按 README 的 ccswitch 方案配置："
echo "1. 供应商名称：codesome"
echo "2. 请求地址：https://cc.codesome.ai"
echo "3. API 格式：openai response api"
echo "4. 模型 ID：gpt-5.5"
echo "5. 打开 ccswitch 代理开关后，再运行 claude"
echo ""
exit 1

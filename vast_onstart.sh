#!/bin/bash
set -e

# --- PyWorker env vars ---
export WORKER_PORT="${WORKER_PORT:-3000}"
export REPORT_ADDR="${REPORT_ADDR:-https://run.vast.ai}"
export MODEL_LOG="/var/log/sglang.log"
export PYWORKER_REPO="${PYWORKER_REPO:-https://github.com/verbeux-ai/qwen-vast-serverless}"
export HF_HUB_ENABLE_HF_TRANSFER=1

# --- SGLang em background ---
mkdir -p /var/log
echo "Iniciando SGLang -> $MODEL_LOG"
nohup python3 -m sglang.launch_server \
    --model-path AEON-7/Qwen3.6-27B-AEON-Ultimate-Uncensored-Multimodal-NVFP4-MTP \
    --host 0.0.0.0 \
    --port 30000 \
    --trust-remote-code \
    > "$MODEL_LOG" 2>&1 &

# --- PyWorker (foreground) ---
wget -qO /tmp/start_server.sh https://raw.githubusercontent.com/vast-ai/pyworker/main/start_server.sh
chmod +x /tmp/start_server.sh
exec /tmp/start_server.sh

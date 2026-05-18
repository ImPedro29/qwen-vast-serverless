#!/bin/bash
set -e

# --- PyWorker env vars ---
export USE_SYSTEM_PYTHON=true
export WORKER_PORT="${WORKER_PORT:-3000}"
export REPORT_ADDR="${REPORT_ADDR:-https://run.vast.ai}"
export MODEL_LOG="/var/log/sglang.log"
export PYWORKER_REPO="${PYWORKER_REPO:-https://github.com/ImPedro29/qwen-vast-serverless}"
export MODEL_NAME="${MODEL_NAME:-qwen3.6-27b}"

# --- Baixar modelo (idempotente) ---
pip install hf-transfer huggingface_hub -q --upgrade
if [ ! -f "/workspace/model/config.json" ]; then
    echo "Baixando modelo..."
    HF_HUB_ENABLE_HF_TRANSFER=1 python3 -c "
from huggingface_hub import snapshot_download
snapshot_download('sakamakismile/Qwen3.6-27B-NVFP4', local_dir='/workspace/model')
"
else
    echo "Modelo já em cache."
fi

# --- SGLang em background, log no MODEL_LOG ---
mkdir -p /var/log
echo "Iniciando SGLang em background -> $MODEL_LOG"
nohup python3 -m sglang.launch_server \
    --model-path /workspace/model \
    --tp-size 1 \
    --host 0.0.0.0 --port 8000 \
    --context-length 65536 \
    --mem-fraction-static 0.85 \
    --max-running-requests 8 \
    --quantization compressed-tensors \
    --reasoning-parser qwen3 \
    --tool-call-parser qwen3_coder \
    --mamba-scheduler-strategy extra_buffer \
    --attention-backend triton \
    --served-model-name "$MODEL_NAME" \
    --api-key "$SGLANG_API_KEY" \
    --enable-metrics \
    --enable-cache-report \
    --trust-remote-code \
    > "$MODEL_LOG" 2>&1 &

# --- PyWorker (foreground) ---
echo "Baixando start_server.sh do vast-ai/pyworker..."
wget -qO /tmp/start_server.sh https://raw.githubusercontent.com/vast-ai/pyworker/main/start_server.sh
chmod +x /tmp/start_server.sh
exec /tmp/start_server.sh

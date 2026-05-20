#!/bin/bash
set -e

# --- PyWorker env vars ---
export WORKER_PORT="${WORKER_PORT:-3000}"
export REPORT_ADDR="${REPORT_ADDR:-https://run.vast.ai}"
export MODEL_LOG="/var/log/vllm.log"
export PYWORKER_REPO="${PYWORKER_REPO:-https://github.com/verbeux-ai/qwen-vast-serverless}"
export HF_HUB_ENABLE_HF_TRANSFER=1

# --- NVFP4 + TurboQuant performance flags ---
export VLLM_NVFP4_GEMM_BACKEND=flashinfer-cutlass
export VLLM_USE_FLASHINFER_SAMPLER=1
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

# --- vLLM em background ---
mkdir -p /var/log
echo "Iniciando vLLM -> $MODEL_LOG"
nohup python3 -m vllm.entrypoints.openai.api_server \
    --model AEON-7/Qwen3.6-27B-AEON-Ultimate-Uncensored-Multimodal-NVFP4-MTP \
    --served-model-name qwen3.6-27b \
    --quantization modelopt \
    --kv-cache-dtype turboquant_k8v4 \
    --max-model-len 262144 \
    --max-num-seqs 12 \
    --max-num-batched-tokens 65536 \
    --gpu-memory-utilization 0.94 \
    --enable-chunked-prefill \
    --enable-prefix-caching \
    --reasoning-parser qwen3 \
    --tool-call-parser qwen3_coder \
    --enable-auto-tool-choice \
    --speculative-config '{"method":"mtp","num_speculative_tokens":3}' \
    --trust-remote-code \
    --host 0.0.0.0 \
    --port 30000 \
    > "$MODEL_LOG" 2>&1 &

# --- PyWorker (foreground) ---
wget -qO /tmp/start_server.sh https://raw.githubusercontent.com/vast-ai/pyworker/main/start_server.sh
chmod +x /tmp/start_server.sh
exec /tmp/start_server.sh

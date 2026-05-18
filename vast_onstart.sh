#!/bin/bash
set -e

# Health stub em :8000 enquanto baixa o modelo
python3 -c "
import http.server, threading
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200); self.end_headers(); self.wfile.write(b'ok')
    def log_message(self, *a): pass
srv = http.server.HTTPServer(('0.0.0.0', 8000), H)
threading.Thread(target=srv.serve_forever, daemon=True).start()
import time; time.sleep(99999)
" &
STUB_PID=$!
echo "Health stub PID=$STUB_PID rodando em :8000"

# Instalar hf-transfer para download rápido
pip install hf-transfer -q

# Download do modelo (idempotente)
if [ ! -f "/workspace/model/config.json" ]; then
    echo "Baixando modelo..."
    HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download \
        sakamakismile/Qwen3.6-27B-NVFP4 \
        --local-dir /workspace/model
else
    echo "Modelo já em cache, pulando download."
fi

# Encerrar stub
kill $STUB_PID 2>/dev/null || true
echo "Iniciando SGLang..."

exec python3 -m sglang.launch_server \
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
    --served-model-name qwen3.6-27b \
    --api-key "$SGLANG_API_KEY" \
    --enable-metrics \
    --enable-cache-report \
    --trust-remote-code

#!/bin/bash
set -e

MODEL_ID="${MODEL_ID:-Qwen/Qwen2.5-1.5B-Instruct}"
GPU_UTIL="${GPU_UTIL:-0.85}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-2048}"

echo "==> Starting vLLM Server with Model: $MODEL_ID"

python3 -m vllm.entrypoints.openai.api_server \
	--model "$MODEL_ID" \
	--host 0.0.0.0 \
	--port 8000 \
	--gpu-memory-utilization "$GPU_UTIL" \
	--dtype float16 \
	--trust-remote-code \
	--max-model-len "$MAX_MODEL_LEN"
# --guided-decoding-backend lm-format-enforcer \  # It is for guided/structured output (forcing JSON, regex or schema)
--served-model-name "$MODEL_ID" &

VLLM_PID=$!

echo "==> Waiting for vLLM to be ready..."
READY=0
for i in $(seq 1 120); do
	if ! kill -0 "$VLLM_PID" 2>/dev/null; then
		echo "ERROR: vLLM process exited during startup" >&2
		exit 1
	fi
	if curl -sf http://localhost:8000/health >/dev/null 2>&1; then
		READY=1
		break
	fi
	sleep 5
done

if [ "$READY" -ne 1 ]; then
	echo "ERROR: vLLM not ready after 10 minutes" >&2
	kill "$VLLM_PID" 2>/dev/null
	exit 1
fi

echo "===> vLLM ready! Starting Streamlit..."
exec streamlit run app.py --server.port 80 --server.address 0.0.0.0 --server.headless true

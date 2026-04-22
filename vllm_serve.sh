#!/usr/bin/env bash
set -euo pipefail
# 대안: vLLM 기반 OpenAI 호환 서버
# llama.cpp 대신 멀티 사용자 서빙 또는 배치 처리가 필요할 때 사용

# ── dependencies ─────────────────────────────────────────────────────────────
sudo apt-get install -y python3 python3-venv
VENV_DIR="./.venv-vllm"
if [[ ! -d "$VENV_DIR" ]]; then
  python3 -m venv "$VENV_DIR"
fi
source "$VENV_DIR/bin/activate"
pip install -q --pre vllm
pip install -q --upgrade transformers  # 구버전 롤백 시 Gemma 4 로드 실패
# ─────────────────────────────────────────────────────────────────────────────

python -m vllm.entrypoints.openai.api_server \
  --model google/gemma-4-31b-it \
  --dtype bfloat16 \
  --max-model-len 8192 \
  --port 8000

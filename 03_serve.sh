#!/usr/bin/env bash
set -euo pipefail

# ── dependencies ─────────────────────────────────────────────────────────────
command -v docker &>/dev/null || sudo apt-get install -y docker-ce docker-ce-cli
# ─────────────────────────────────────────────────────────────────────────────

# 01_download.sh에서 받은 모델 경로로 수정
MODEL_FILE="./models/gemma4-31b-gguf/gemma-4-31b-it-Q4_K_M.gguf"
PORT=8080
# 컨텍스트 길이: 클수록 메모리 더 사용 (최대 262144)
# 8192: 일반 사용 / 32768: 긴 문서 / 131072: 대용량 컨텍스트
CTX=8192

MODEL_DIR=$(dirname "${MODEL_FILE}")
MODEL_BASENAME=$(basename "${MODEL_FILE}")
ABS_MODEL_DIR=$(realpath "${MODEL_DIR}")

echo "모델: ${MODEL_BASENAME}"
echo "컨텍스트: ${CTX} tokens"
echo "포트: ${PORT}"
echo ""

docker run --rm --gpus all \
  -p "${PORT}:${PORT}" \
  -v "${ABS_MODEL_DIR}:/models" \
  llama-cpp-dgx \
  /llama.cpp/build/bin/llama-server \
    -m "/models/${MODEL_BASENAME}" \
    --host 0.0.0.0 \
    --port "${PORT}" \
    -ngl 999 \
    -c "${CTX}"

# -ngl 999: 모든 레이어를 통합 메모리(GPU)에 적재
# DGX Spark 128GB 통합 메모리로 PCIe 병목 없이 전체 GPU 대역폭 활용

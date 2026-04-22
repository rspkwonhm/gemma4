#!/usr/bin/env bash
set -euo pipefail

# 00_check.sh 추천 결과에 따라 MODEL_REPO / MODEL_FILE 변경
# 기본값: 31B Dense Q4_K_M (DGX Spark 128GB 기준 균형 옵션)

MODEL_REPO="unsloth/gemma-4-31b-it-GGUF"
MODEL_FILE="gemma-4-31b-it-Q4_K_M.gguf"
LOCAL_DIR="./models/gemma4-31b-gguf"

# ── 대안 옵션 (주석 해제해서 사용) ───────────────────────────────────────────
# 품질 최우선 (BF16 전체, ~62GB 다운로드 / 런타임 ~117GB)
# MODEL_REPO="google/gemma-4-31b-it"
# MODEL_FILE=""
# LOCAL_DIR="./models/gemma4-31b-bf16"

# 속도 최우선 (MoE BF16, 런타임 ~50GB, ~69 t/s)
# MODEL_REPO="google/gemma-4-26b-a4b-it"
# MODEL_FILE=""
# LOCAL_DIR="./models/gemma4-26b-moe-bf16"

# MoE Q4 (런타임 ~18GB)
# MODEL_REPO="unsloth/gemma-4-26B-A4B-it-GGUF"
# MODEL_FILE="gemma-4-26B-A4B-it-Q4_K_M.gguf"
# LOCAL_DIR="./models/gemma4-26b-moe-gguf"
# ─────────────────────────────────────────────────────────────────────────────

# ── dependencies ─────────────────────────────────────────────────────────────
if ! command -v pipx &>/dev/null; then
  sudo apt-get install -y pipx
fi
export PATH="$HOME/.local/bin:$PATH"
if ! command -v hf &>/dev/null; then
  pipx install 'huggingface_hub[cli]'
fi
# ─────────────────────────────────────────────────────────────────────────────

# HF 토큰 필요: https://huggingface.co/settings/tokens
# Gemma 4 약관 동의 필요: https://huggingface.co/google/gemma-4-31b-it
hf auth login

mkdir -p "${LOCAL_DIR}"

if [[ -z "${MODEL_FILE}" ]]; then
  hf download "${MODEL_REPO}" --local-dir "${LOCAL_DIR}"
else
  hf download "${MODEL_REPO}" \
    --include "${MODEL_FILE}" \
    --local-dir "${LOCAL_DIR}"
fi

echo "다운로드 완료:"
ls -lh "${LOCAL_DIR}/"

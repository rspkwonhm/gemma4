#!/usr/bin/env bash
set -euo pipefail

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
# Gemma 4 약관 동의: https://huggingface.co/google/gemma-4-31b-it
hf auth login

# ── 다운로드할 모델 목록 ──────────────────────────────────────────────────────
declare -A MODELS=(
  ["gemma4-e2b"]="unsloth/gemma-4-E2B-it-GGUF|gemma-4-E2B-it-Q4_K_M.gguf"
  ["gemma4-e4b"]="unsloth/gemma-4-E4B-it-GGUF|gemma-4-E4B-it-Q4_K_M.gguf"
  ["gemma4-26b"]="unsloth/gemma-4-26B-A4B-it-GGUF|gemma-4-26B-A4B-it-Q4_K_M.gguf"
  ["gemma4-31b"]="unsloth/gemma-4-31B-it-GGUF|gemma-4-31B-it-Q4_K_M.gguf"
)
# ─────────────────────────────────────────────────────────────────────────────

mkdir -p ./models

for KEY in "${!MODELS[@]}"; do
  REPO="${MODELS[$KEY]%%|*}"
  FILE="${MODELS[$KEY]##*|}"
  DIR="./models/${KEY}"

  if [[ -f "${DIR}/${FILE}" ]]; then
    echo "[SKIP] ${KEY} 이미 존재: ${DIR}/${FILE}"
    continue
  fi

  echo ""
  echo "[DOWN] ${KEY} ← ${REPO}/${FILE}"
  mkdir -p "${DIR}"
  hf download "${REPO}" "${FILE}" --local-dir "${DIR}"
done

echo ""
echo "=== 전체 모델 현황 ==="
ls -lh ./models/*/

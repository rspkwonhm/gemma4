#!/usr/bin/env bash
set -euo pipefail

# ── dependencies ─────────────────────────────────────────────────────────────
command -v docker &>/dev/null || sudo apt-get install -y docker-ce docker-ce-cli
if ! docker info &>/dev/null; then
  sudo usermod -aG docker "$USER"
  echo "docker 그룹에 추가했습니다. 아래 명령 실행 후 다시 시도하세요:"
  echo "  newgrp docker"
  exit 1
fi
# ─────────────────────────────────────────────────────────────────────────────

# 모델 → 포트 매핑
# 전부 동시에 띄워도 총 ~44GB (128GB 여유)
declare -A MODEL_MAP=(
  ["e2b"]="models/gemma4-e2b/gemma-4-E2B-it-Q4_K_M.gguf|8082"
  ["e4b"]="models/gemma4-e4b/gemma-4-E4B-it-Q4_K_M.gguf|8081"
  ["26b"]="models/gemma4-26b/gemma-4-26B-A4B-it-Q4_K_M.gguf|8083"
  ["31b"]="models/gemma4-31b/gemma-4-31B-it-Q4_K_M.gguf|8080"
)

CTX=8192

_run_model() {
  local KEY="$1"
  local ENTRY="${MODEL_MAP[$KEY]}"
  local MODEL_FILE="${ENTRY%%|*}"
  local PORT="${ENTRY##*|}"
  local BASENAME
  BASENAME=$(basename "$MODEL_FILE")
  local ABS_DIR
  ABS_DIR=$(realpath "$(dirname "$MODEL_FILE")")

  echo "▶ ${KEY} | ${BASENAME} | port ${PORT}"

  docker run -d \
    --gpus all \
    --name "gemma4-${KEY}" \
    -p "${PORT}:${PORT}" \
    -v "${ABS_DIR}:/models" \
    llama-cpp-dgx \
      -m "/models/${BASENAME}" \
      --host 0.0.0.0 \
      --port "${PORT}" \
      -ngl 999 \
      -c "${CTX}"
}

# ── 사용법 ───────────────────────────────────────────────────────────────────
# ./03_serve.sh          → 모델 선택 메뉴
# ./03_serve.sh all      → 전체 동시 실행
# ./03_serve.sh 31b      → 특정 모델만 실행
# ./03_serve.sh stop     → 전체 종료
# ─────────────────────────────────────────────────────────────────────────────

CMD="${1:-menu}"

case "$CMD" in
  all)
    echo "=== 전체 모델 시작 ==="
    for KEY in e2b e4b 26b 31b; do
      docker rm -f "gemma4-${KEY}" 2>/dev/null || true
      _run_model "$KEY"
    done
    echo ""
    echo "포트 현황:"
    echo "  E2B  → http://localhost:8082"
    echo "  E4B  → http://localhost:8081"
    echo "  26B  → http://localhost:8083"
    echo "  31B  → http://localhost:8080"
    ;;

  stop)
    echo "=== 전체 종료 ==="
    for KEY in e2b e4b 26b 31b; do
      docker rm -f "gemma4-${KEY}" 2>/dev/null && echo "  종료: gemma4-${KEY}" || true
    done
    ;;

  e2b|e4b|26b|31b)
    docker rm -f "gemma4-${CMD}" 2>/dev/null || true
    _run_model "$CMD"
    echo "  → http://localhost:${MODEL_MAP[$CMD]##*|}"
    ;;

  menu|*)
    echo "================================"
    echo " Gemma 4 모델 선택"
    echo "================================"
    echo "  1) E2B  Q4_K_M  ~2GB   port 8082  (초경량)"
    echo "  2) E4B  Q4_K_M  ~4GB   port 8081  (경량)"
    echo "  3) 26B  Q4_K_M  ~18GB  port 8083  (속도 우선, MoE)"
    echo "  4) 31B  Q4_K_M  ~20GB  port 8080  (품질 우선)"
    echo "  5) 전체 동시 실행 (~44GB)"
    echo "  0) 전체 종료"
    echo "================================"
    read -rp "선택 [0-5]: " SEL
    case "$SEL" in
      1) $0 e2b ;;
      2) $0 e4b ;;
      3) $0 26b ;;
      4) $0 31b ;;
      5) $0 all ;;
      0) $0 stop ;;
      *) echo "잘못된 선택" ; exit 1 ;;
    esac
    ;;
esac

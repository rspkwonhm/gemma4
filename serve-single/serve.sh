#!/usr/bin/env bash
# 단일 라우터 서버 — 모든 모델을 port 8080 하나로, 요청 시 on-demand 로드
# model 필드로 선택: gemma-4-31B-it-Q4_K_M / gemma-4-E2B-it-Q4_K_M 등
set -euo pipefail

cd "$(dirname "$0")"

# ── 사용법 ───────────────────────────────────────────────────────────────────
# ./serve.sh start  → 서버 시작
# ./serve.sh stop   → 서버 종료
# ./serve.sh ps     → 상태 확인
# ./serve.sh logs   → 로그
# ./serve.sh models → 로드된 모델 목록
# ─────────────────────────────────────────────────────────────────────────────

CMD="${1:-start}"

case "$CMD" in
  start)
    docker compose up -d
    echo "  router → http://localhost:8080"
    echo ""
    echo "  요청 시 model 필드로 모델 선택:"
    echo "    gemma4-31b/gemma-4-31B-it-Q4_K_M"
    echo "    gemma4-26b/gemma-4-26B-A4B-it-UD-Q4_K_M"
    echo "    gemma4-e4b/gemma-4-E4B-it-Q4_K_M"
    echo "    gemma4-e2b/gemma-4-E2B-it-Q4_K_M"
    ;;
  stop)   docker compose down ;;
  ps)     docker compose ps ;;
  logs)   docker compose logs -f router ;;
  models)
    curl -s http://localhost:8080/v1/models | python3 -m json.tool
    ;;
  *)
    echo "사용법: $0 {start|stop|ps|logs|models}"
    exit 1
    ;;
esac

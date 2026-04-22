#!/usr/bin/env bash
# 모델별 독립 컨테이너 — 포트 고정, 동시 운용 가능
# 31B:8080 / 26B:8081 / E4B:8082 / E2B:8083
set -euo pipefail

cd "$(dirname "$0")"

# ── 사용법 ───────────────────────────────────────────────────────────────────
# ./serve.sh          → 메뉴
# ./serve.sh all      → 전체 시작
# ./serve.sh 31b      → 특정 모델 (31b / 26b / e4b / e2b)
# ./serve.sh stop     → 전체 종료
# ./serve.sh ps       → 상태 확인
# ./serve.sh logs 31b → 로그
# ─────────────────────────────────────────────────────────────────────────────

CMD="${1:-menu}"

case "$CMD" in
  all)
    docker compose up -d
    echo ""
    echo "  31B → http://localhost:8080"
    echo "  26B → http://localhost:8081"
    echo "  E4B → http://localhost:8082"
    echo "  E2B → http://localhost:8083"
    ;;
  stop)   docker compose down ;;
  ps)     docker compose ps ;;
  logs)   docker compose logs -f "${2:-31b}" ;;
  31b|26b|e4b|e2b)
    docker compose up -d "$CMD"
    ;;
  menu|*)
    echo "================================"
    echo " 모델별 독립 서버"
    echo "================================"
    echo "  1) 31B  ~20GB  port 8080"
    echo "  2) 26B  ~18GB  port 8081"
    echo "  3) E4B  ~5GB   port 8082"
    echo "  4) E2B  ~3GB   port 8083"
    echo "  5) 전체 동시 실행"
    echo "  0) 전체 종료"
    echo "================================"
    read -rp "선택 [0-5]: " SEL
    case "$SEL" in
      1) $0 31b ;; 2) $0 26b ;; 3) $0 e4b ;; 4) $0 e2b ;;
      5) $0 all ;; 0) $0 stop ;;
      *) echo "잘못된 선택" ; exit 1 ;;
    esac
    ;;
esac

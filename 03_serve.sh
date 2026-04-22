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

# ── 사용법 ───────────────────────────────────────────────────────────────────
# ./03_serve.sh          → 메뉴
# ./03_serve.sh all      → 전체 시작
# ./03_serve.sh 31b      → 특정 모델 시작 (e2b / e4b / 26b / 31b)
# ./03_serve.sh stop     → 전체 종료
# ./03_serve.sh logs 31b → 특정 모델 로그
# ./03_serve.sh ps       → 실행 상태 확인
# ─────────────────────────────────────────────────────────────────────────────

CMD="${1:-menu}"

case "$CMD" in
  all)
    docker compose up -d
    echo ""
    echo "포트 현황:"
    echo "  31B  → http://localhost:8080"
    echo "  26B  → http://localhost:8081"
    echo "  E4B  → http://localhost:8082"
    echo "  E2B  → http://localhost:8083"
    ;;

  stop)
    docker compose down
    ;;

  ps)
    docker compose ps
    ;;

  logs)
    docker compose logs -f "${2:-31b}"
    ;;

  e2b|e4b|26b|31b)
    docker compose up -d "$CMD"
    ;;

  menu|*)
    echo "================================"
    echo " Gemma 4 모델 선택"
    echo "================================"
    echo "  1) 31B  ~20GB  port 8080  (품질 최고)"
    echo "  2) 26B  ~18GB  port 8081  (속도 우선)"
    echo "  3) E4B  ~5GB   port 8082"
    echo "  4) E2B  ~3GB   port 8083  (최경량)"
    echo "  5) 전체 동시 실행 (~44GB)"
    echo "  0) 전체 종료"
    echo "================================"
    read -rp "선택 [0-5]: " SEL
    case "$SEL" in
      1) $0 31b ;;
      2) $0 26b ;;
      3) $0 e4b ;;
      4) $0 e2b ;;
      5) $0 all ;;
      0) $0 stop ;;
      *) echo "잘못된 선택" ; exit 1 ;;
    esac
    ;;
esac

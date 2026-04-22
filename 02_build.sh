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

IMAGE="ghcr.io/ardge-labs/llama-cpp-dgx-spark:latest"

echo "=== pre-built 이미지 pull ==="
docker pull "$IMAGE"
docker tag "$IMAGE" llama-cpp-dgx

echo "=== 완료 ==="
docker images llama-cpp-dgx

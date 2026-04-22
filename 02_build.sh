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
docker compose version &>/dev/null || sudo apt-get install -y docker-compose-plugin
# ─────────────────────────────────────────────────────────────────────────────

echo "=== llama.cpp 빌드 (ARM64 + CUDA 13 + SM_121) ==="
docker build -t llama-cpp-dgx .

echo "=== 완료 ==="
docker images llama-cpp-dgx

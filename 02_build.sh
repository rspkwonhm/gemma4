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

# NGC 로그인
# Username: $oauthtoken  ← 이 문자열 그대로 입력
# Password: <NGC API Key> ← https://ngc.nvidia.com/setup/api-key 에서 발급
docker login nvcr.io

# ARM64 + CUDA 13 + SM_121 빌드 (~3분 소요)
docker build -t llama-cpp-dgx .

echo "=== 빌드 완료 ==="
docker images llama-cpp-dgx

#!/usr/bin/env bash
set -euo pipefail

# ── dependencies ─────────────────────────────────────────────────────────────
command -v docker &>/dev/null || sudo apt-get install -y docker-ce docker-ce-cli
# ─────────────────────────────────────────────────────────────────────────────

# NGC API Key 필요: https://ngc.nvidia.com/setup/api-key
docker login nvcr.io

# ARM64 + CUDA 13 + SM_121 빌드 (~3분 소요)
docker build -t llama-cpp-dgx .

echo "=== 빌드 완료 ==="
docker images llama-cpp-dgx

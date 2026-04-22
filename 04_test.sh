#!/usr/bin/env bash
set -euo pipefail

# ── dependencies ─────────────────────────────────────────────────────────────
sudo apt-get install -y curl python3
# ─────────────────────────────────────────────────────────────────────────────

PORT=8080

echo "=== Health check ==="
curl -sf "http://localhost:${PORT}/health" | python3 -m json.tool

echo ""
echo "=== Chat 테스트 ==="
curl -s "http://localhost:${PORT}/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma4",
    "messages": [
      {"role": "user", "content": "안녕하세요! 한 문장으로 자기소개 해주세요."}
    ],
    "max_tokens": 100
  }' | python3 -m json.tool

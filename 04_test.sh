#!/usr/bin/env bash
set -euo pipefail

# ── dependencies ─────────────────────────────────────────────────────────────
command -v curl    &>/dev/null || sudo apt-get install -y curl
command -v python3 &>/dev/null || sudo apt-get install -y python3
# ─────────────────────────────────────────────────────────────────────────────

declare -A PORTS=(
  ["E2B"]=8082
  ["E4B"]=8081
  ["26B"]=8083
  ["31B"]=8080
)

PROMPT="한 문장으로 자기소개 해주세요."

for MODEL in E2B E4B 26B 31B; do
  PORT="${PORTS[$MODEL]}"
  printf "%-5s (:%s) → " "$MODEL" "$PORT"

  HEALTH=$(curl -sf "http://localhost:${PORT}/health" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','?'))" 2>/dev/null || echo "offline")

  if [[ "$HEALTH" != "ok" ]]; then
    echo "offline (서버 미실행)"
    continue
  fi

  RESP=$(curl -sf "http://localhost:${PORT}/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"gemma4\",\"messages\":[{\"role\":\"user\",\"content\":\"${PROMPT}\"}],\"max_tokens\":80}" \
    2>/dev/null \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['choices'][0]['message']['content'].strip())" 2>/dev/null \
    || echo "응답 실패")

  echo "$RESP"
done

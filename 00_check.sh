#!/usr/bin/env bash
set -euo pipefail

# ── dependencies ─────────────────────────────────────────────────────────────
command -v curl   &>/dev/null || sudo apt-get install -y curl
command -v docker &>/dev/null || sudo apt-get install -y docker-ce docker-ce-cli
# ─────────────────────────────────────────────────────────────────────────────

echo "============================================"
echo " DGX Spark 사양 확인 & Gemma 4 모델 추천"
echo "============================================"

# 1. 아키텍처 확인
ARCH=$(uname -m)
echo "[arch]    $ARCH"
if [[ "$ARCH" != "aarch64" ]]; then
  echo "경고: ARM64(aarch64)가 아닙니다. DGX Spark가 맞는지 확인하세요."
fi

# 2. 가용 메모리 확인 (GB 단위)
TOTAL_MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
AVAIL_MEM_KB=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
TOTAL_GB=$((TOTAL_MEM_KB / 1024 / 1024))
AVAIL_GB=$((AVAIL_MEM_KB / 1024 / 1024))

echo "[메모리]  전체: ${TOTAL_GB}GB / 가용: ${AVAIL_GB}GB"

# 3. GPU 확인
echo ""
echo "[GPU]"
nvidia-smi --query-gpu=name,memory.total,memory.free --format=csv,noheader 2>/dev/null \
  || echo "  (통합 메모리: 시스템 RAM과 공유)"

# 4. 디스크 확인
DISK_AVAIL=$(df -BG . | awk 'NR==2 {print $4}' | tr -d 'G')
echo "[디스크]  가용: ${DISK_AVAIL}GB"

# 5. Docker & CUDA 확인
echo ""
echo "[Docker]  $(docker --version 2>/dev/null || echo '미설치')"
echo "[CUDA]    $(nvcc --version 2>/dev/null | grep release | awk '{print $6}' | tr -d , || echo '확인 필요')"

# 6. 모델 추천 로직
echo ""
echo "============================================"
echo " Gemma 4 모델 추천"
echo "============================================"
echo ""
echo "  Gemma 4 모델별 메모리 요구량 (llama.cpp GGUF 기준):"
echo "  ┌─────────────────┬──────────┬──────────┬──────────────────────────┐"
echo "  │ 모델            │ Q4_K_M   │ BF16 전체│ 특징                     │"
echo "  ├─────────────────┼──────────┼──────────┼──────────────────────────┤"
echo "  │ Gemma-4-E2B     │  ~2GB    │  ~4GB    │ 초경량, 테스트용          │"
echo "  │ Gemma-4-E4B     │  ~4GB    │  ~8GB    │ 경량, 빠른 응답           │"
echo "  │ Gemma-4-26B-MoE │ ~18GB    │ ~50GB    │ 속도 최우선 (69 t/s)     │"
echo "  │ Gemma-4-31B     │ ~20GB    │ ~117GB   │ 품질 최우선 (11 t/s)     │"
echo "  └─────────────────┴──────────┴──────────┴──────────────────────────┘"
echo ""

if [[ $AVAIL_GB -ge 100 ]]; then
  echo "  ✅ 추천: Gemma-4-31B (BF16 전체 정밀도)"
  echo "     이유: 가용 메모리 ${AVAIL_GB}GB → BF16 117GB 적재 가능"
  echo "     벤치: ~11 tokens/s | 품질 leaderboard #3 (오픈 모델)"
  echo "     다운로드: google/gemma-4-31b-it (HF)"
  echo ""
  echo "  ⚡ 속도 우선이라면: Gemma-4-26B-A4B (MoE, BF16)"
  echo "     이유: 활성 파라미터 4B만 연산 → 69 t/s로 6배 빠름"
  echo "     다운로드: google/gemma-4-26b-a4b-it (HF)"

elif [[ $AVAIL_GB -ge 30 ]]; then
  echo "  ✅ 추천: Gemma-4-31B (Q4_K_M GGUF)"
  echo "     이유: 가용 메모리 ${AVAIL_GB}GB → Q4 20GB 적재 가능"
  echo "     벤치: ~70 tokens/s | 품질 leaderboard #3"
  echo "     다운로드: unsloth/gemma-4-31b-it-GGUF (gemma-4-31b-it-Q4_K_M.gguf)"

elif [[ $AVAIL_GB -ge 20 ]]; then
  echo "  ✅ 추천: Gemma-4-26B-A4B (Q4_K_M GGUF, MoE)"
  echo "     이유: 가용 메모리 ${AVAIL_GB}GB → MoE Q4 18GB에 적합"
  echo "     벤치: ~69 tokens/s | leaderboard #6"
  echo "     다운로드: unsloth/gemma-4-26B-A4B-it-GGUF"

elif [[ $AVAIL_GB -ge 6 ]]; then
  echo "  ✅ 추천: Gemma-4-E4B (Q4_K_M GGUF)"
  echo "     이유: 가용 메모리 ${AVAIL_GB}GB → E4B ~4GB에 적합"
  echo "     다운로드: unsloth/gemma-4-e4b-it-GGUF"

else
  echo "  ⚠️  메모리 부족: Gemma-4-E2B 또는 다른 경량 모델을 검토하세요."
fi

echo ""
if [[ $DISK_AVAIL -lt 25 ]]; then
  echo "  ⚠️  디스크 경고: ${DISK_AVAIL}GB 남음. Q4 모델 최소 25GB 권장."
fi

echo "============================================"

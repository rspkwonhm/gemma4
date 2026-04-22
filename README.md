# Gemma 4 on NVIDIA DGX Spark

NVIDIA DGX Spark(GB10 Grace Blackwell, ARM64, SM_121, 128GB 통합 메모리)에 Google Gemma 4를 설치하는 가이드.

> Ollama 0.20.0에서 Gemma 4 26B/31B segfault 버그([#15318](https://github.com/ollama/ollama/issues/15318))가 있으므로 **llama.cpp Docker** 방식을 사용한다.

---

## 사용 목적

사이드 프로젝트에서 API로 연결하거나 직접 대화하는 용도. 서버를 한 번 띄워두면 아래 두 가지 방식으로 사용 가능하다.

**API 연결 (사이드 프로젝트 코드에서 호출)**

OpenAI SDK와 호환되므로 `base_url`만 바꾸면 된다.

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://<DGX_SPARK_IP>:8080/v1",
    api_key="none",  # 로컬 서버라 불필요
)

response = client.chat.completions.create(
    model="gemma4",
    messages=[{"role": "user", "content": "안녕!"}],
)
print(response.choices[0].message.content)
```

```typescript
import OpenAI from "openai";

const client = new OpenAI({
  baseURL: "http://<DGX_SPARK_IP>:8080/v1",
  apiKey: "none",
});

const res = await client.chat.completions.create({
  model: "gemma4",
  messages: [{ role: "user", content: "안녕!" }],
});
console.log(res.choices[0].message.content);
```

**직접 대화 (터미널)**

```bash
# 서버 실행 후 curl로 한 줄 대화
curl -s http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gemma4","messages":[{"role":"user","content":"질문 내용"}]}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['choices'][0]['message']['content'])"
```

또는 Open WebUI 같은 채팅 UI를 `http://localhost:8080`에 연결해 브라우저에서 대화 가능.

---

## 사전 준비

- [NVIDIA NGC API Key](https://ngc.nvidia.com/setup/api-key) — Docker 이미지 pull용
- [Hugging Face 토큰](https://huggingface.co/settings/tokens) — 모델 다운로드용
- Gemma 4 약관 동의 — [google/gemma-4-31b-it](https://huggingface.co/google/gemma-4-31b-it)

---

## 실행 순서

### 1. 환경 확인 + 모델 추천

```bash
bash 00_check.sh
```

가용 메모리를 읽어 적합한 모델을 자동 추천한다.

| 가용 메모리 | 추천 모델 | 정밀도 | 속도 | 품질 |
|------------|----------|--------|------|------|
| ≥ 100GB | Gemma-4-31B Dense | BF16 | 11 t/s | Leaderboard #3 |
| ≥ 100GB (속도 우선) | Gemma-4-26B-A4B MoE | BF16 | 69 t/s | Leaderboard #6 |
| ≥ 30GB | Gemma-4-31B Dense | Q4_K_M | ~70 t/s | Leaderboard #3 |
| ≥ 20GB | Gemma-4-26B-A4B MoE | Q4_K_M | ~69 t/s | Leaderboard #6 |

> DGX Spark 128GB 기준: **일반 사용 → Q4_K_M 31B** (속도·품질 균형), **품질 최우선 → BF16 31B**, **속도 최우선 → BF16 26B MoE**

### 2. 모델 다운로드

```bash
bash 01_download.sh
```

기본값: `unsloth/gemma-4-31b-it-GGUF` (Q4_K_M, ~20GB). 스크립트 상단 변수를 수정해 다른 모델로 변경 가능.

### 3. Docker 이미지 빌드

```bash
bash 02_build.sh
```

NGC 베이스 이미지(`nvcr.io/nvidia/cuda:13.0.1`)를 사용해 ARM64 + SM_121용 llama.cpp를 컴파일한다. 약 3분 소요.

### 4. 추론 서버 실행

```bash
bash 03_serve.sh
```

`http://localhost:8080`에 OpenAI 호환 API 서버가 실행된다. 컨텍스트 길이(`CTX`)와 모델 경로는 스크립트 상단에서 조정.

### 5. 동작 확인

```bash
bash 04_test.sh
```

---

## 파일 구조

```
gemma4/
├── 00_check.sh      # 환경 확인 + 모델 자동 추천
├── 01_download.sh   # 모델 다운로드 (HF)
├── 02_build.sh      # llama.cpp Docker 이미지 빌드
├── 03_serve.sh      # 추론 서버 실행 (port 8080)
├── 04_test.sh       # 동작 확인 (curl)
├── Dockerfile       # ARM64 + CUDA 13 + SM_121 빌드 정의
└── vllm_serve.sh    # 대안: vLLM 멀티 사용자 서빙
```

---

## 대안: vLLM

멀티 사용자 서빙이나 배치 처리가 필요할 때:

```bash
bash vllm_serve.sh
```

---

## 참고

- [shamily/gemma4-llama-dgx-spark](https://github.com/shamily/gemma4-llama-dgx-spark)
- [NVIDIA DGX Spark llama.cpp 공식 가이드](https://build.nvidia.com/spark/llama-cpp/overview)
- [Arm 러닝 패스: llama.cpp SM_121 빌드](https://learn.arm.com/learning-paths/laptops-and-desktops/dgx_spark_llamacpp/2_gb10_llamacpp_gpu/)
- [Ollama segfault 버그 #15318](https://github.com/ollama/ollama/issues/15318)

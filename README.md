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
    api_key="none",
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
curl -s http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gemma4","messages":[{"role":"user","content":"질문 내용"}]}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['choices'][0]['message']['content'])"
```

---

## 모델 구성

4개 모델을 동시에 운용한다. 총 ~44GB로 128GB 통합 메모리에 여유 있게 적재된다.

| 모델 | 포트 | 메모리 | 속도 | 용도 |
|------|------|--------|------|------|
| Gemma-4-E2B Q4 | 8082 | ~2GB | 빠름 | 초경량, 테스트 |
| Gemma-4-E4B Q4 | 8081 | ~4GB | 빠름 | 경량 |
| Gemma-4-26B MoE Q4 | 8083 | ~18GB | ~69 t/s | 속도 우선 |
| Gemma-4-31B Q4 | 8080 | ~20GB | ~70 t/s | 품질 우선 |

---

## 사전 준비

- [NVIDIA NGC API Key](https://ngc.nvidia.com/setup/api-key) — Docker 이미지 빌드용 (Username: `$oauthtoken`)
- [Hugging Face 토큰](https://huggingface.co/settings/tokens) — 모델 다운로드용
- Gemma 4 약관 동의 — [google/gemma-4-31b-it](https://huggingface.co/google/gemma-4-31b-it)

---

## 실행 순서

### 1. 환경 확인 + 모델 추천

```bash
bash 00_check.sh
```

### 2. 모델 다운로드 (4개 전체, 이미 있으면 스킵)

```bash
bash 01_download.sh
```

### 3. llama.cpp Docker 이미지 빌드

```bash
bash 02_build.sh
```

NGC 로그인 필요 (Username: `$oauthtoken`, Password: NGC API Key). 빌드 20~40분 소요.

### 4. 서버 실행

```bash
# 전체 동시 실행
./03_serve.sh all

# 특정 모델만
./03_serve.sh 31b   # 31B (port 8080)
./03_serve.sh 26b   # 26B MoE (port 8083)
./03_serve.sh e4b   # E4B (port 8081)
./03_serve.sh e2b   # E2B (port 8082)

# 메뉴 선택
./03_serve.sh

# 전체 종료
./03_serve.sh stop
```

### 5. 전체 응답 비교 테스트

```bash
bash 04_test.sh
```

실행 중인 모델에만 요청하고, 오프라인 모델은 스킵한다.

---

## 파일 구조

```
gemma4/
├── 00_check.sh      # 환경 확인 + 모델 자동 추천
├── 01_download.sh   # 4개 모델 일괄 다운로드
├── 02_build.sh      # llama.cpp Docker 이미지 빌드
├── 03_serve.sh      # 모델 선택/실행/종료 (멀티 모델)
├── 04_test.sh       # 전체 모델 응답 비교
├── Dockerfile       # ARM64 + CUDA 13.1.1 + SM_121a-real
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
- [Ollama segfault 버그 #15318](https://github.com/ollama/ollama/issues/15318)
- [Arm 러닝 패스: llama.cpp SM_121 빌드](https://learn.arm.com/learning-paths/laptops-and-desktops/dgx_spark_llamacpp/2_gb10_llamacpp_gpu/)
- [unsloth Gemma 4 GGUF (HF)](https://huggingface.co/unsloth/gemma-4-31B-it-GGUF)

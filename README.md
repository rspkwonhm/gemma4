# Gemma 4 on NVIDIA DGX Spark

NVIDIA DGX Spark(GB10 Grace Blackwell, ARM64, SM_121, 128GB 통합 메모리)에 Google Gemma 4를 설치하는 가이드.

> Ollama 0.20.0에서 Gemma 4 26B/31B segfault 버그([#15318](https://github.com/ollama/ollama/issues/15318))가 있으므로 **llama.cpp Docker** 방식을 사용한다.

---

## 사용 목적

사이드 프로젝트에서 API로 연결하거나 직접 대화하는 용도.

**API 연결**

```python
from openai import OpenAI

client = OpenAI(base_url="http://<DGX_SPARK_IP>:8080/v1", api_key="none")
response = client.chat.completions.create(
    model="gemma4",
    messages=[{"role": "user", "content": "안녕!"}],
)
print(response.choices[0].message.content)
```

```typescript
import OpenAI from "openai";

const client = new OpenAI({ baseURL: "http://<DGX_SPARK_IP>:8080/v1", apiKey: "none" });
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
  -d '{"model":"gemma4","messages":[{"role":"user","content":"질문"}]}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['choices'][0]['message']['content'])"
```

---

## 모델 구성

4개 모델을 docker compose로 동시 운용. 총 ~44GB로 128GB 통합 메모리에 여유 있게 적재된다.

| 모델 | 포트 | 메모리 | 속도 | 용도 |
|------|------|--------|------|------|
| Gemma-4-E2B Q4 | 8082 | ~2GB | 빠름 | 초경량, 테스트 |
| Gemma-4-E4B Q4 | 8081 | ~4GB | 빠름 | 경량 |
| Gemma-4-26B MoE Q4 | 8083 | ~18GB | ~69 t/s | 속도 우선 |
| Gemma-4-31B Q4 | 8080 | ~20GB | ~70 t/s | 품질 우선 |

---

## 사전 준비

- [NVIDIA NGC API Key](https://ngc.nvidia.com/setup/api-key) — Docker 빌드용 (Username: `$oauthtoken`)
- [Hugging Face 토큰](https://huggingface.co/settings/tokens) — 모델 다운로드용
- Gemma 4 약관 동의 — [google/gemma-4-31b-it](https://huggingface.co/google/gemma-4-31b-it)

---

## 실행 순서

```bash
bash 00_check.sh      # 환경 확인 + 모델 추천
bash 01_download.sh   # 4개 모델 다운로드 (이미 있으면 스킵)
bash 02_build.sh      # llama.cpp Docker 이미지 빌드 (20~40분)
./03_serve.sh all     # 전체 시작
./04_test.sh          # 전체 응답 비교
```

---

## 서버 관리

```bash
./03_serve.sh          # 메뉴 선택
./03_serve.sh all      # 전체 시작
./03_serve.sh 31b      # 특정 모델만 (e2b / e4b / 26b / 31b)
./03_serve.sh stop     # 전체 종료
./03_serve.sh ps       # 상태 확인
./03_serve.sh logs 31b # 로그 확인
```

또는 docker compose 직접 사용:

```bash
docker compose up -d          # 전체 시작
docker compose down           # 전체 종료
docker compose ps             # 상태 확인
docker compose logs -f 31b    # 로그
```

---

## 파일 구조

```
gemma4/
├── 00_check.sh          # 환경 확인 + 모델 자동 추천
├── 01_download.sh       # 4개 모델 일괄 다운로드
├── 02_build.sh          # llama.cpp Docker 이미지 빌드
├── 03_serve.sh          # 모델 선택/실행/종료
├── 04_test.sh           # 전체 모델 응답 비교
├── docker-compose.yml   # 4개 모델 서비스 정의
├── Dockerfile           # ARM64 + CUDA 13.1.1 + SM_121a-real
└── vllm_serve.sh        # 대안: vLLM 서빙
```

---

## 참고

- [shamily/gemma4-llama-dgx-spark](https://github.com/shamily/gemma4-llama-dgx-spark)
- [NVIDIA DGX Spark llama.cpp 공식 가이드](https://build.nvidia.com/spark/llama-cpp/overview)
- [Ollama segfault 버그 #15318](https://github.com/ollama/ollama/issues/15318)
- [unsloth Gemma 4 GGUF](https://huggingface.co/unsloth/gemma-4-31B-it-GGUF)

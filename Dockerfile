# ardge-labs/llama-cpp-dgx-spark: DGX Spark(ARM64 + SM_121) 전용 pre-built 이미지
# 직접 빌드 불필요 — pull만으로 사용 가능
FROM ghcr.io/ardge-labs/llama-cpp-dgx-spark:latest

# 모델은 외부 볼륨으로 마운트
VOLUME ["/models"]
EXPOSE 8080

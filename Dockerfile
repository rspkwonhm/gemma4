# Build stage
FROM nvidia/cuda:13.1.1-devel-ubuntu24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git cmake build-essential curl \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/ggerganov/llama.cpp /llama.cpp

WORKDIR /llama.cpp

RUN cmake -B build \
    -DGGML_CUDA=ON \
    -DGGML_NATIVE=ON \
    -DLLAMA_CURL=ON \
    -DCMAKE_CUDA_ARCHITECTURES=121a-real \
    -DCMAKE_LIBRARY_PATH=/usr/local/cuda-13.1/compat \
    -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build --config Release -j$(nproc)

# Runtime stage
FROM nvidia/cuda:13.1.1-runtime-ubuntu24.04

RUN apt-get update && apt-get install -y curl libcurl4 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /llama.cpp/build/bin/llama-server /usr/local/bin/llama-server

EXPOSE 8080
ENTRYPOINT ["llama-server"]

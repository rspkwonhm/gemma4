FROM nvcr.io/nvidia/cuda:13.0.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
# SM_121 = GB10 Grace Blackwell (DGX Spark)
ENV CUDA_DOCKER_ARCH=121
ENV CUDAARCHS=121

RUN apt-get update && apt-get install -y \
    git cmake build-essential \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/ggerganov/llama.cpp /llama.cpp

WORKDIR /llama.cpp

RUN cmake -B build \
    -G Ninja \
    -DGGML_CUDA=ON \
    -DCMAKE_CUDA_ARCHITECTURES=121 \
    -DGGML_CUDA_F16=ON \
    -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build -j4

# GPU build stage — uses CUDA devel image so nvcc is available
FROM nvcr.io/nvidia/cuda:11.8.0-devel-ubuntu20.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
        build-essential \
        cmake \
        ninja-build \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . .

RUN cmake -S . -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -G Ninja \
    && cmake --build build --target gpu_demo -j"$(nproc)" --verbose

# GPU runtime image — much smaller than the devel image
FROM nvcr.io/nvidia/cuda:11.8.0-runtime-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
        libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /src/build/gpu_demo /app/gpu_demo

EXPOSE 5000
CMD ["/app/gpu_demo"]

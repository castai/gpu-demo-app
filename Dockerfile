# Multi-stage, multi-arch Dockerfile for C++ GPU demo app
#
# GPU target:  linux/amd64 only (CUDA requires x86_64)
# CPU target:  linux/amd64 + linux/arm64

# ── Shared build argument for header-only vendored libraries ─────────────────
# Both stages copy from the same source tree; no extra ARGs needed.

# =============================================================================
# GPU build stage — uses CUDA devel image so nvcc is available
# =============================================================================
FROM nvcr.io/nvidia/cuda:11.8.0-devel-ubuntu20.04 AS gpu-builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
        build-essential \
        cmake \
        ninja-build \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . .

# Configure and build only the GPU target
RUN cmake -S . -B build_gpu \
        -DCMAKE_BUILD_TYPE=Release \
        -G Ninja \
    && cmake --build build_gpu --target gpu_demo -j"$(nproc)" --verbose

# =============================================================================
# GPU runtime image — much smaller than the devel image
# =============================================================================
FROM nvcr.io/nvidia/cuda:11.8.0-runtime-ubuntu20.04 AS gpu-base

ENV DEBIAN_FRONTEND=noninteractive

# libstdc++ and libgcc are needed to run the C++ binary
RUN apt-get update && apt-get install -y \
        libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=gpu-builder /src/build_gpu/gpu_demo /app/gpu_demo

EXPOSE 5000
CMD ["/app/gpu_demo"]

# =============================================================================
# CPU build stage — plain Debian bookworm
# =============================================================================
FROM debian:bookworm-slim AS cpu-builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
        build-essential \
        cmake \
        ninja-build \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . .

# Configure and build only the CPU target (FORCE_CPU is defined by CMakeLists
# via target_compile_definitions, not by the env var at build time)
RUN cmake -S . -B build_cpu \
        -DCMAKE_BUILD_TYPE=Release \
        -DFORCE_CPU_ONLY=ON \
        -G Ninja \
    && cmake --build build_cpu --target cpu_demo -j"$(nproc)"

# =============================================================================
# CPU runtime image — minimal Debian bookworm
# =============================================================================
FROM debian:bookworm-slim AS cpu-base

ENV FORCE_CPU=true

RUN apt-get update && apt-get install -y \
        libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=cpu-builder /src/build_cpu/cpu_demo /app/cpu_demo

EXPOSE 5000
CMD ["/app/cpu_demo"]

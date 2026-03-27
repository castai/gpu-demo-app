# GPU Demo App — C++ Version

A C++ port of the Python GPU demo app. Generates a 600×600 Mandelbrot set
image every 10 seconds, serves it as PNG over HTTP on port 5000 (`GET /`).

## Vendored header-only libraries

Two header-only libraries must be placed in this directory before building.
They are **not** bundled here because of their file size / licensing — fetch
them once with the commands below.

### cpp-httplib (`httplib.h`)

Single-file C++11 HTTP/HTTPS server & client library.

```bash
curl -L -o httplib.h \
  https://raw.githubusercontent.com/yhirose/cpp-httplib/master/httplib.h
```

- Repository: <https://github.com/yhirose/cpp-httplib>
- License: MIT

### stb_image_write (`stb_image_write.h`)

Single-file PNG/BMP/TGA/JPG encoder from the stb collection.

```bash
curl -L -o stb_image_write.h \
  https://raw.githubusercontent.com/nothings/stb/master/stb_image_write.h
```

- Repository: <https://github.com/nothings/stb>
- License: MIT / Public Domain (dual)

---

## Building locally (without Docker)

### Prerequisites

- CMake ≥ 3.18
- A C++17-capable compiler (GCC 9+, Clang 10+, MSVC 19.14+)
- For the GPU target: CUDA Toolkit ≥ 11.x and `nvcc`
- The two header files above, placed in `cpp_version/`

### CPU-only build

```bash
cd cpp_version
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DFORCE_CPU_ONLY=ON
cmake --build build --target cpu_demo
./build/cpu_demo
```

### GPU build

```bash
cd cpp_version
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --target gpu_demo
./build/gpu_demo
```

Set the `PORT` environment variable to change the listening port (default 5000).

---

## Docker builds (via Makefile)

The Makefile mirrors the parent project's interface exactly.

```bash
# Build both images locally
make all

# Run the CPU image
make run-cpu

# Run the GPU image (requires NVIDIA Container Toolkit)
make run-gpu

# Push to a registry
make push REGISTRY=docker.io/myorg TAG=v1.0
```

### Variables

| Variable    | Default          | Description                         |
|-------------|------------------|-------------------------------------|
| `IMAGE`     | `gpu-demo-cpp`   | Base image name                     |
| `TAG`       | `latest`         | Image tag                           |
| `REGISTRY`  | *(empty)*        | Registry prefix, e.g. `docker.io/x` |
| `CPU_IMAGE` | `$(IMAGE)-cpu:$(TAG)` | Full CPU image reference       |
| `GPU_IMAGE` | `$(IMAGE)-gpu:$(TAG)` | Full GPU image reference       |

All variables honour `?=` so environment variables take precedence.

---

## File structure

```
cpp_version/
├── main.cpp            HTTP server + CPU Mandelbrot + background thread
├── mandelbrot.cu       CUDA kernel (GPU Mandelbrot computation)
├── mandelbrot.cuh      Shared header (params struct, color schemes, declarations)
├── CMakeLists.txt      Build system (gpu_demo + cpu_demo targets)
├── Dockerfile          Multi-stage: gpu-base / cpu-base
├── Makefile            Docker build/push/run targets
├── README.md           This file
├── httplib.h           ← fetch with curl command above
└── stb_image_write.h   ← fetch with curl command above
```

---

## Behaviour

- **Image size**: 600 × 600 pixels, RGB PNG
- **Generation interval**: every 10 seconds (background thread)
- **HTTP endpoint**: `GET /` → `image/png`
- **Port**: 5000 (override with `PORT` env var)
- **CUDA fallback**: if GPU computation fails at runtime, automatically falls
  back to CPU for subsequent frames
- **FORCE_CPU**: set `FORCE_CPU=true` (or `FORCE_CPU=1`) to skip CUDA even
  when the `gpu_demo` binary was compiled with CUDA support
- **Color schemes** (random per frame):
  1. Rainbow spectrum
  2. Fire (red-orange-yellow)
  3. Ocean (blue-cyan-white)
  4. Electric (purple-pink-cyan)
  5. Sunset (orange-red-purple)
  6. Forest (green-yellow-brown)
  7. Galaxy (deep purple-blue-white)
  8. Neon (bright cycling)

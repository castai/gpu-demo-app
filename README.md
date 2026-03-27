# GPU Demo App

Generates a 600×600 Mandelbrot set image every 10 seconds using CUDA, serves it as PNG over HTTP on port 5000 (`GET /`).

## Vendored header-only libraries

Two header-only libraries must be placed in this directory before building.

### cpp-httplib (`httplib.h`)

```bash
curl -L -o httplib.h \
  https://raw.githubusercontent.com/yhirose/cpp-httplib/master/httplib.h
```

### stb_image_write (`stb_image_write.h`)

```bash
curl -L -o stb_image_write.h \
  https://raw.githubusercontent.com/nothings/stb/master/stb_image_write.h
```

---

## Building locally (without Docker)

### Prerequisites

- CMake ≥ 3.16
- C++17-capable compiler (GCC 9+, Clang 10+)
- CUDA Toolkit ≥ 11.x and `nvcc`

### Build

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --target gpu_demo
./build/gpu_demo
```

Set the `PORT` environment variable to change the listening port (default 5000).

---

## Docker (via Makefile)

```bash
# Build image locally
make build

# Run (requires NVIDIA Container Toolkit)
make run

# Push to a registry
make push REGISTRY=docker.io/myorg TAG=v1.0
```

### Variables

| Variable    | Default             | Description                         |
|-------------|---------------------|-------------------------------------|
| `IMAGE`     | `gpu-demo-cpp`      | Base image name                     |
| `TAG`       | `latest`            | Image tag                           |
| `REGISTRY`  | *(empty)*           | Registry prefix, e.g. `docker.io/x` |
| `GPU_IMAGE` | `$(IMAGE):$(TAG)`   | Full image reference                |

---

## File structure

```
├── main.cpp            HTTP server + background generation thread
├── mandelbrot.cu       CUDA kernel (GPU Mandelbrot computation)
├── mandelbrot.cuh      Shared header (params struct, color schemes, declarations)
├── CMakeLists.txt      Build system
├── Dockerfile          Multi-stage GPU build
├── Makefile            Docker build/push/run targets
├── httplib.h           ← fetch with curl command above
└── stb_image_write.h   ← fetch with curl command above
```

---

## Behaviour

- **Image size**: 600 × 600 pixels, RGB PNG
- **Generation interval**: every 10 seconds (background thread)
- **HTTP endpoint**: `GET /` → `image/png`
- **Port**: 5000 (override with `PORT` env var)
- **Color schemes** (random per frame):
  1. Rainbow spectrum
  2. Fire (red-orange-yellow)
  3. Ocean (blue-cyan-white)
  4. Electric (purple-pink-cyan)
  5. Sunset (orange-red-purple)
  6. Forest (green-yellow-brown)
  7. Galaxy (deep purple-blue-white)
  8. Neon (bright cycling)

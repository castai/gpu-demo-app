# GPU Demo App

Generates a 600×600 Mandelbrot set image every 10 seconds using CUDA, serves it as PNG over HTTP on port 5000 (`GET /`).

## Deploying on Kubernetes

1. Run:

```bash
kubectl apply -f k8s-deployment.yaml
```

2. Access via port-forward

```bash
kubectl port-forward -n gpu-demo svc/gpu-demo-service 5000:5000
```

Then open your browser at `http://localhost:5000` - it will serve the latest Mandelbrot PNG.

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

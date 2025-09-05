# GPU Demo App

A geometric figure generator that creates **big, colorful, random** Mandelbrot fractals every 10 seconds with CUDA acceleration when available.

## Features

- ✅ **CUDA Acceleration** - Uses GPU when available, falls back to CPU
- ✅ **Big Images** - 600x600 pixel high-resolution fractals
- ✅ **Vibrant Colors** - 8 stunning color schemes (Rainbow, Fire, Ocean, Electric, etc.)
- ✅ **Random Generation** - Different image every 10 seconds with random parameters
- ✅ **Performance Optimized** - Generation guaranteed under 30 seconds
- ✅ **Simple API** - Single endpoint returns PNG image
- ✅ **Kubernetes Ready** - Complete deployment manifests included

## Quick Start

**Local (CPU):**
```bash
pip install -r requirements.txt
./run.sh
```

**Local (GPU with CUDA):**
```bash
pip install -r requirements.txt
python app.py
```

**Docker:**
```bash
./build.sh

# GPU version (requires nvidia-docker)
docker run --gpus all -p 5000:5000 gpu-demo:gpu

# CPU version
docker run -p 5000:5000 gpu-demo:cpu
```

**Kubernetes:**
```bash
# Deploy both GPU and CPU versions
kubectl apply -f k8s-deployment.yaml

# Access via port-forward
kubectl port-forward -n gpu-demo service/gpu-demo-service 5000:80
```

## Usage

Visit `http://localhost:5000/` to see the current generated image.

- **GPU mode**: ~2-15 seconds generation time (600x600, high detail)
- **CPU mode**: ~5-25 seconds generation time (600x600, moderate detail)
- **Auto-refresh**: New **random** image every 10 seconds
- **Format**: **600x600 pixel** high-resolution PNG images
- **Colors**: 8 vibrant schemes - Rainbow, Fire, Ocean, Electric, Sunset, Forest, Galaxy, Neon
- **Variety**: Random zoom (0.5x-3x), center points, adaptive detail levels
- **Performance**: Optimized to complete within 30 seconds maximum

## Architecture

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐
│   HTTP Client   │───▶│  Flask API   │───▶│ Image Generator │
└─────────────────┘    └──────────────┘    └─────────────────┘
                                                     │
                                                     ▼
                                           ┌─────────────────┐
                                           │ CUDA (GPU) OR   │
                                           │ NumPy (CPU)     │
                                           └─────────────────┘
```

## Files

- `app.py` - Main application with CUDA support
- `requirements.txt` - Dependencies (includes CuPy for CUDA)
- `Dockerfile` - Multi-stage build (GPU + CPU)
- `k8s-deployment.yaml` - Complete Kubernetes deployment
- `build.sh` - Build script for both versions
- `run.sh` - Local start script
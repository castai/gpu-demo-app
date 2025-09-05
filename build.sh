#!/bin/bash

# Build GPU Demo App - Both GPU and CPU versions

set -e

echo "🚀 Building GPU Demo App..."

# Build GPU version
echo "📦 Building GPU version..."
docker build --target gpu-base -t gpu-demo:gpu .

# Build CPU version  
echo "📦 Building CPU version..."
docker build --target cpu-base -t gpu-demo:cpu .

echo "✅ Build completed successfully!"
echo ""
echo "Available images:"
echo "  - gpu-demo:gpu (CUDA support)"
echo "  - gpu-demo:cpu (CPU fallback)"
echo ""
echo "🏃 Quick start:"
echo "  GPU: docker run --gpus all -p 5000:5000 gpu-demo:gpu"
echo "  CPU: docker run -p 5000:5000 gpu-demo:cpu"
echo ""
echo "☸️ Deploy to Kubernetes:"
echo "  kubectl apply -f k8s-deployment.yaml"

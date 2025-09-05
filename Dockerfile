# Multi-stage build for GPU support
FROM nvidia/cuda:11.8-devel-ubuntu20.04 as gpu-base

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install Python and system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Create symbolic link for python
RUN ln -s /usr/bin/python3 /usr/bin/python

WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY app.py .

EXPOSE 5000

CMD ["python", "app.py"]

# CPU-only fallback stage
FROM python:3.9-slim as cpu-base

ENV PYTHONUNBUFFERED=1
ENV FORCE_CPU=true

WORKDIR /app

# Install only CPU dependencies
COPY requirements.txt .
RUN grep -v "cupy" requirements.txt > requirements-cpu.txt || echo "Flask==2.3.3\nnumpy==1.24.3\nPillow==10.0.1" > requirements-cpu.txt
RUN pip install --no-cache-dir -r requirements-cpu.txt

COPY app.py .

EXPOSE 5000

CMD ["python", "app.py"]

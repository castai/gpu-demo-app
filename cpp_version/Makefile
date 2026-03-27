IMAGE     ?= gpu-demo-cpp
TAG       ?= latest
REGISTRY  ?= # e.g. docker.io/myorg

PLATFORMS_CPU := linux/amd64,linux/arm64
PLATFORMS_GPU := linux/amd64

# Default image names — overridable via env or make variables
CPU_IMAGE ?= $(if $(REGISTRY),$(REGISTRY)/,)$(IMAGE)-cpu:$(TAG)
GPU_IMAGE ?= $(if $(REGISTRY),$(REGISTRY)/,)$(IMAGE)-gpu:$(TAG)

BUILDER   = buildx-multiarch

.PHONY: all build-cpu build-gpu push-cpu push-gpu push \
        run-cpu run-gpu setup-builder clean help

## Default: build both images locally (no push)
all: build-cpu build-gpu

## Create (or reuse) a buildx builder that supports multiarch
setup-builder:
	docker buildx inspect $(BUILDER) > /dev/null 2>&1 \
	  || docker buildx create --name $(BUILDER) --use --bootstrap
	docker buildx use $(BUILDER)

## Build CPU image for linux/amd64 + linux/arm64 (loads into local daemon for amd64)
build-cpu: setup-builder
	docker buildx build \
	  --platform $(PLATFORMS_CPU) \
	  --target cpu-base \
	  --tag $(CPU_IMAGE) \
	  --load \
	  .

## Build GPU image for linux/amd64 only (loads into local daemon)
build-gpu: setup-builder
	docker buildx build \
	  --platform $(PLATFORMS_GPU) \
	  --target gpu-base \
	  --tag $(GPU_IMAGE) \
	  --load \
	  .

## Push CPU multiarch manifest to registry
push-cpu: setup-builder
	docker buildx build \
	  --platform $(PLATFORMS_CPU) \
	  --target cpu-base \
	  --tag $(CPU_IMAGE) \
	  --push \
	  .

## Push GPU image to registry
push-gpu: setup-builder
	docker buildx build \
	  --platform $(PLATFORMS_GPU) \
	  --target gpu-base \
	  --tag $(GPU_IMAGE) \
	  --push \
	  .

## Push both images
push: push-cpu push-gpu

## Run CPU container locally
run-cpu:
	docker run --rm -p 5000:5000 $(CPU_IMAGE)

## Run GPU container locally (requires NVIDIA runtime)
run-gpu:
	docker run --rm --gpus all -p 5000:5000 $(GPU_IMAGE)

## Remove the buildx builder
clean:
	docker buildx rm $(BUILDER) 2>/dev/null || true

help:
	@echo "Targets:"
	@echo "  build-cpu   Build CPU image (amd64+arm64), load into local daemon"
	@echo "  build-gpu   Build GPU image (amd64 only),  load into local daemon"
	@echo "  push-cpu    Push CPU multiarch manifest to registry"
	@echo "  push-gpu    Push GPU image to registry"
	@echo "  push        Push both images"
	@echo "  run-cpu     Run CPU container on port 5000"
	@echo "  run-gpu     Run GPU container on port 5000 (needs NVIDIA runtime)"
	@echo "  clean       Remove the buildx builder"
	@echo ""
	@echo "Variables (override with make <target> VAR=value or env):"
	@echo "  IMAGE=$(IMAGE)   REGISTRY=$(REGISTRY)   TAG=$(TAG)"
	@echo "  GPU_IMAGE=$(GPU_IMAGE)"
	@echo "  CPU_IMAGE=$(CPU_IMAGE)"

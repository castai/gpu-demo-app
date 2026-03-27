IMAGE     ?= gpu-demo-cpp
TAG       ?= latest
REGISTRY  ?= # e.g. docker.io/myorg

PLATFORM := linux/amd64

GPU_IMAGE ?= $(if $(REGISTRY),$(REGISTRY)/,)$(IMAGE):$(TAG)

BUILDER   = buildx-multiarch

.PHONY: all build push run setup-builder clean help

## Default: build image locally (no push)
all: build

## Create (or reuse) a buildx builder that supports multiarch
setup-builder:
	docker buildx inspect $(BUILDER) > /dev/null 2>&1 \
	  || docker buildx create --name $(BUILDER) --use --bootstrap
	docker buildx use $(BUILDER)

## Build GPU image for linux/amd64 (loads into local daemon)
build: setup-builder
	docker buildx build \
	  --platform $(PLATFORM) \
	  --tag $(GPU_IMAGE) \
	  --load \
	  .

## Push GPU image to registry
push: setup-builder
	docker buildx build \
	  --platform $(PLATFORM) \
	  --tag $(GPU_IMAGE) \
	  --push \
	  .

## Run GPU container locally (requires NVIDIA runtime)
run:
	docker run --rm --gpus all -p 5000:5000 $(GPU_IMAGE)

## Remove the buildx builder
clean:
	docker buildx rm $(BUILDER) 2>/dev/null || true

help:
	@echo "Targets:"
	@echo "  build   Build GPU image (amd64), load into local daemon"
	@echo "  push    Push GPU image to registry"
	@echo "  run     Run GPU container on port 5000 (needs NVIDIA runtime)"
	@echo "  clean   Remove the buildx builder"
	@echo ""
	@echo "Variables (override with make <target> VAR=value or env):"
	@echo "  IMAGE=$(IMAGE)   REGISTRY=$(REGISTRY)   TAG=$(TAG)"
	@echo "  GPU_IMAGE=$(GPU_IMAGE)"

// mandelbrot.cu — CUDA kernel for Mandelbrot set computation
// Compiled with nvcc; linked into gpu_demo target only.

#include "mandelbrot.cuh"

#include <cuda_runtime.h>
#include <cstdio>

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

#define CUDA_CHECK(call)                                                        \
    do {                                                                        \
        cudaError_t _e = (call);                                                \
        if (_e != cudaSuccess) {                                                \
            fprintf(stderr, "CUDA error %s:%d — %s\n",                         \
                    __FILE__, __LINE__, cudaGetErrorString(_e));                \
            return false;                                                        \
        }                                                                        \
    } while (0)

// ---------------------------------------------------------------------------
// Kernel
// ---------------------------------------------------------------------------

// Each thread computes one pixel.
__global__ void mandelbrot_kernel(
        int width, int height, int max_iter,
        double x_min, double x_max, double y_min, double y_max,
        int color_scheme,
        RGB* __restrict__ out)
{
    int px = blockIdx.x * blockDim.x + threadIdx.x;
    int py = blockIdx.y * blockDim.y + threadIdx.y;

    if (px >= width || py >= height) return;

    // Map pixel → complex plane
    double cr = x_min + (x_max - x_min) * (double)px / (double)(width  - 1);
    double ci = y_min + (y_max - y_min) * (double)py / (double)(height - 1);

    double zr = 0.0, zi = 0.0;
    int iter = 0;

    // Iterate z = z^2 + c until escape or max_iter
    while (iter < max_iter) {
        double zr2 = zr * zr;
        double zi2 = zi * zi;
        if (zr2 + zi2 > 4.0) break;
        zi = 2.0 * zr * zi + ci;
        zr = zr2 - zi2 + cr;
        ++iter;
    }

    // Normalize iteration count to [0, 1] exactly as the Python version does:
    //   result = (iterations / max_iter * 255)   → uint8
    //   normalized = result / 255.0
    // Combined: t = iter / max_iter   (same value after the two integer round-trips
    // when we keep it as float; small difference vs. Python's cast, acceptable).
    float t = (float)iter / (float)max_iter;

    out[py * width + px] = apply_color_scheme(color_scheme, t);
}

// ---------------------------------------------------------------------------
// Host-callable wrapper
// ---------------------------------------------------------------------------

bool mandelbrot_gpu(const MandelbrotParams& p, RGB* pixels)
{
    const int n = p.width * p.height;

    // Allocate device buffer
    RGB* d_out = nullptr;
    CUDA_CHECK(cudaMalloc(&d_out, n * sizeof(RGB)));

    // Launch kernel — 16×16 tiles work well on most hardware
    dim3 block(16, 16);
    dim3 grid(
        (p.width  + block.x - 1) / block.x,
        (p.height + block.y - 1) / block.y
    );

    mandelbrot_kernel<<<grid, block>>>(
        p.width, p.height, p.max_iter,
        p.x_min, p.x_max, p.y_min, p.y_max,
        p.color_scheme,
        d_out
    );

    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaDeviceSynchronize());

    // Copy result back to host
    CUDA_CHECK(cudaMemcpy(pixels, d_out, n * sizeof(RGB), cudaMemcpyDeviceToHost));

    cudaFree(d_out);
    return true;
}

#pragma once

#include <cstdint>

// Parameters for a single Mandelbrot generation
struct MandelbrotParams {
    int width;
    int height;
    int max_iter;
    double x_min;
    double x_max;
    double y_min;
    double y_max;
    int color_scheme;  // 1..8
};

// Pixel color (R, G, B)
struct RGB {
    uint8_t r, g, b;
};

// Apply a color scheme to a normalized value t in [0,1].
// Inline so it can be called from both host and device code.
#ifdef __CUDACC__
__host__ __device__
#endif
inline RGB apply_color_scheme(int scheme, float t) {
    float r_f, g_f, b_f;
    const float pi = 3.14159265358979f;

    switch (scheme) {
        case 1:  // Rainbow spectrum
            r_f = 128.0f + 127.0f * sinf(t * 2.0f * pi);
            g_f = 128.0f + 127.0f * sinf(t * 2.0f * pi + 2.0f);
            b_f = 128.0f + 127.0f * sinf(t * 2.0f * pi + 4.0f);
            break;
        case 2:  // Fire theme (red-orange-yellow)
            r_f = 255.0f * t;
            g_f = 255.0f * sqrtf(t);
            b_f = 255.0f * t * t;
            break;
        case 3:  // Ocean theme (blue-cyan-white)
            r_f = 255.0f * t * t;
            g_f = 255.0f * powf(t, 0.7f);
            b_f = 255.0f * t;
            break;
        case 4:  // Electric theme (purple-pink-cyan)
            r_f = 255.0f * (0.5f + 0.5f * sinf(t * 4.0f * pi));
            g_f = 255.0f * powf(t, 0.3f);
            b_f = 255.0f * (0.7f + 0.3f * cosf(t * 3.0f * pi));
            break;
        case 5:  // Sunset theme (orange-red-purple)
            r_f = 255.0f * (0.8f + 0.2f * t);
            g_f = 255.0f * powf(t, 1.5f);
            b_f = 255.0f * sqrtf(t);
            break;
        case 6:  // Forest theme (green-yellow-brown)
            r_f = 255.0f * powf(t, 1.2f);
            g_f = 255.0f * (0.3f + 0.7f * t);
            b_f = 255.0f * powf(t, 3.0f);
            break;
        case 7:  // Galaxy theme (deep purple-blue-white)
            r_f = 255.0f * (0.2f + 0.8f * powf(t, 0.8f));
            g_f = 255.0f * powf(t, 1.5f);
            b_f = 255.0f * (0.6f + 0.4f * t);
            break;
        default:  // case 8: Neon theme (bright cycling colors)
            r_f = 255.0f * (0.5f + 0.5f * cosf(t * 6.0f * pi));
            g_f = 255.0f * (0.5f + 0.5f * sinf(t * 4.0f * pi));
            b_f = 255.0f * (0.5f + 0.5f * sinf(t * 8.0f * pi + 1.0f));
            break;
    }

    // Clamp to [0, 255] — written as plain conditionals so the function
    // remains valid in __device__ code on all CUDA versions.
    uint8_t r8 = (r_f < 0.0f) ? 0 : (r_f > 255.0f) ? 255 : (uint8_t)r_f;
    uint8_t g8 = (g_f < 0.0f) ? 0 : (g_f > 255.0f) ? 255 : (uint8_t)g_f;
    uint8_t b8 = (b_f < 0.0f) ? 0 : (b_f > 255.0f) ? 255 : (uint8_t)b_f;

    return {r8, g8, b8};
}

// CPU implementation (always available)
void mandelbrot_cpu(const MandelbrotParams& params, RGB* pixels);

#ifndef FORCE_CPU
// GPU implementation (only compiled when CUDA is available)
bool mandelbrot_gpu(const MandelbrotParams& params, RGB* pixels);
#endif

// main.cpp — HTTP server + GPU Mandelbrot + background generation thread
//
// Dependencies (header-only, see README.md for where to obtain them):
//   httplib.h          — cpp-httplib  https://github.com/yhirose/cpp-httplib
//   stb_image_write.h  — stb          https://github.com/nothings/stb

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#include "httplib.h"

#include "mandelbrot.cuh"

static_assert(sizeof(RGB) == 3, "RGB struct must be tightly packed");

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <mutex>
#include <random>
#include <string>
#include <thread>
#include <vector>

// ---------------------------------------------------------------------------
// Image generator
// ---------------------------------------------------------------------------

class ImageGenerator {
public:
    ImageGenerator()
        : rng_(std::random_device{}())
    {
        std::puts("Generator initialized — using CUDA");

        // Generate the first image synchronously so the server has something to serve
        generate_image();

        // Start background thread: new image every 10 seconds
        bg_thread_ = std::thread([this]() {
            while (true) {
                std::this_thread::sleep_for(std::chrono::seconds(10));
                generate_image();
            }
        });
        bg_thread_.detach();

        std::puts("Started background generation — new random image every 10 seconds");
    }

    // Return a PNG-encoded copy of the current image.
    // Returns empty vector if no image is ready yet.
    std::vector<uint8_t> get_png() {
        std::lock_guard<std::mutex> lock(mutex_);
        return png_buf_;
    }

private:
    // Encode pixels → PNG into an in-memory buffer via stb_image_write
    static void stbi_write_callback(void* context, void* data, int size) {
        auto* buf = static_cast<std::vector<uint8_t>*>(context);
        const uint8_t* p = static_cast<const uint8_t*>(data);
        buf->insert(buf->end(), p, p + size);
    }

    MandelbrotParams random_params() {
        std::uniform_int_distribution<int> iter_dist(80, 150);
        std::uniform_real_distribution<double> zoom_dist(0.5, 3.0);
        std::uniform_real_distribution<double> cx_dist(-2.0, 1.0);
        std::uniform_real_distribution<double> cy_dist(-1.5, 1.5);
        std::uniform_int_distribution<int> scheme_dist(1, 8);

        MandelbrotParams p;
        p.width  = 600;
        p.height = 600;
        p.max_iter    = iter_dist(rng_);
        p.color_scheme = scheme_dist(rng_);

        double zoom     = zoom_dist(rng_);
        double center_x = cx_dist(rng_);
        double center_y = cy_dist(rng_);
        double x_range  = 3.0 / zoom;
        double y_range  = 3.0 / zoom;
        p.x_min = center_x - x_range / 2.0;
        p.x_max = center_x + x_range / 2.0;
        p.y_min = center_y - y_range / 2.0;
        p.y_max = center_y + y_range / 2.0;

        return p;
    }

    void generate_image() {
        MandelbrotParams params = random_params();
        const int n = params.width * params.height;
        std::vector<RGB> pixels(n);

        auto t0 = std::chrono::steady_clock::now();

        mandelbrot_gpu(params, pixels.data());

        auto t1 = std::chrono::steady_clock::now();
        double elapsed = std::chrono::duration<double>(t1 - t0).count();

        // Format timestamp HH:MM:SS
        std::time_t now_t = std::time(nullptr);
        char ts[16];
        std::strftime(ts, sizeof(ts), "%H:%M:%S", std::localtime(&now_t));

        std::printf("Generated 600x600 Mandelbrot at %s (%.2fs)\n", ts, elapsed);

        // Encode to PNG
        std::vector<uint8_t> new_png;
        new_png.reserve(n * 3);
        int stride = params.width * 3;

        int result = stbi_write_png_to_func(
            stbi_write_callback,
            &new_png,
            params.width,
            params.height,
            3,  // RGB
            pixels.data(),
            stride
        );

        if (result == 0) {
            std::puts("Error: PNG encoding failed");
            return;
        }

        {
            std::lock_guard<std::mutex> lock(mutex_);
            png_buf_ = std::move(new_png);
        }
    }

    std::mt19937 rng_;
    std::mutex mutex_;
    std::vector<uint8_t> png_buf_;
    std::thread bg_thread_;
};

// ---------------------------------------------------------------------------
// main — HTTP server
// ---------------------------------------------------------------------------

int main()
{
    int port = 5000;
    const char* port_env = std::getenv("PORT");
    if (port_env) port = std::atoi(port_env);

    std::printf("Starting GPU demo app on http://0.0.0.0:%d\n", port);
    std::puts("New image generated every 10 seconds");

    ImageGenerator generator;

    httplib::Server svr;

    svr.Get("/", [&generator](const httplib::Request& /*req*/, httplib::Response& res) {
        std::vector<uint8_t> png = generator.get_png();
        if (png.empty()) {
            res.status = 500;
            res.set_content("No image available", "text/plain");
            return;
        }
        res.set_content(
            reinterpret_cast<const char*>(png.data()),
            png.size(),
            "image/png"
        );
    });

    std::printf("Listening on port %d...\n", port);
    svr.listen("0.0.0.0", port);

    return 0;
}

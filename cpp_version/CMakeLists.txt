cmake_minimum_required(VERSION 3.16)

# CUDA must be listed in project() for CMake 3.16 — enabling it later via
# enable_language() after check_language() causes "Generate step failed" with Ninja.
if(NOT FORCE_CPU_ONLY)
    project(gpu_demo_cpp LANGUAGES CXX CUDA)
else()
    project(gpu_demo_cpp LANGUAGES CXX)
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Threads REQUIRED)

# ---------------------------------------------------------------------------
# GPU target
# ---------------------------------------------------------------------------
if(NOT FORCE_CPU_ONLY AND DEFINED CMAKE_CUDA_COMPILER)
    add_executable(gpu_demo
        main.cpp
        mandelbrot.cu
    )

    set_target_properties(gpu_demo PROPERTIES
        CUDA_ARCHITECTURES "60;70;75;80;86"
        CUDA_SEPARABLE_COMPILATION OFF
    )

    target_include_directories(gpu_demo PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
    target_compile_options(gpu_demo PRIVATE $<$<COMPILE_LANGUAGE:CXX>:-UCPPHTTPLIB_OPENSSL_SUPPORT>)
    target_link_libraries(gpu_demo PRIVATE Threads::Threads dl m)

    message(STATUS "CUDA found — gpu_demo target configured")
else()
    message(STATUS "CUDA not found or FORCE_CPU_ONLY set — skipping gpu_demo target")
endif()

# ---------------------------------------------------------------------------
# CPU target
# ---------------------------------------------------------------------------
add_executable(cpu_demo main.cpp)

target_include_directories(cpu_demo PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
target_compile_definitions(cpu_demo PRIVATE FORCE_CPU)
target_compile_options(cpu_demo PRIVATE -UCPPHTTPLIB_OPENSSL_SUPPORT)
target_link_libraries(cpu_demo PRIVATE Threads::Threads dl m)

message(STATUS "cpu_demo target configured")

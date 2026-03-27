cmake_minimum_required(VERSION 3.16)

project(gpu_demo_cpp LANGUAGES CXX CUDA)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Threads REQUIRED)

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

message(STATUS "gpu_demo target configured")

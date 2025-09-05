#!/usr/bin/env python3
"""
Minimal GPU Demo App - Generates geometric figures every 10 seconds
Simple endpoint that returns only images
"""

import os
import io
import time
import threading
import random
from flask import Flask, send_file
import numpy as np
from PIL import Image

# Try to import CUDA support
try:
    import cupy as cp
    CUDA_AVAILABLE = True
    print("✅ CUDA support available")
except ImportError:
    CUDA_AVAILABLE = False
    print("⚠️  CUDA not available, using CPU")

app = Flask(__name__)

class ImageGenerator:
    def __init__(self):
        self.use_cuda = CUDA_AVAILABLE and not os.environ.get('FORCE_CPU', '').lower() == 'true'
        self.current_image = None
        print(f"🚀 Generator initialized - Using {'CUDA' if self.use_cuda else 'CPU'}")
        self.generate_image()  # Generate first image immediately
        self.start_background_generation()
    
    def generate_mandelbrot(self):
        """Generate bigger, more colorful Mandelbrot set with random parameters"""
        # Bigger image size but balanced for performance
        width, height = 600, 600
        # Adjust iterations based on GPU/CPU for performance
        if self.use_cuda:
            max_iter = random.randint(80, 150)  # More detail with GPU
        else:
            max_iter = random.randint(50, 100)  # Moderate detail with CPU
        
        # Random zoom and center point for different views
        zoom = random.uniform(0.5, 3.0)
        center_x = random.uniform(-2.0, 1.0)
        center_y = random.uniform(-1.5, 1.5)
        
        # Calculate bounds based on zoom and center
        x_range = 3.0 / zoom
        y_range = 3.0 / zoom
        x_min = center_x - x_range / 2
        x_max = center_x + x_range / 2
        y_min = center_y - y_range / 2
        y_max = center_y + y_range / 2
        
        if self.use_cuda:
            # CUDA version with random parameters
            x = cp.linspace(x_min, x_max, width)
            y = cp.linspace(y_min, y_max, height)
            X, Y = cp.meshgrid(x, y)
            C = X + 1j * Y
            Z = cp.zeros_like(C)
            iterations = cp.zeros(C.shape, dtype=int)
            
            for i in range(max_iter):
                mask = cp.abs(Z) <= 2
                Z[mask] = Z[mask] ** 2 + C[mask]
                iterations[mask] = i
            
            # Convert back to CPU and normalize
            result = cp.asnumpy(iterations)
            result = (result / max_iter * 255).astype(np.uint8)
        else:
            # CPU version with random parameters
            x = np.linspace(x_min, x_max, width)
            y = np.linspace(y_min, y_max, height)
            X, Y = np.meshgrid(x, y)
            C = X + 1j * Y
            Z = np.zeros_like(C)
            iterations = np.zeros(C.shape, dtype=int)
            
            for i in range(max_iter):
                mask = np.abs(Z) <= 2
                Z[mask] = Z[mask] ** 2 + C[mask]
                iterations[mask] = i
            
            result = (iterations / max_iter * 255).astype(np.uint8)
        
        # Enhanced colorful schemes with more vibrant colors
        color_scheme = random.randint(1, 8)
        normalized = result / 255.0
        
        # Create smooth color transitions using trigonometric functions for more vibrant results
        if color_scheme == 1:  # Rainbow spectrum
            r = (128 + 127 * np.sin(normalized * 2 * np.pi)).astype(np.uint8)
            g = (128 + 127 * np.sin(normalized * 2 * np.pi + 2)).astype(np.uint8)
            b = (128 + 127 * np.sin(normalized * 2 * np.pi + 4)).astype(np.uint8)
        elif color_scheme == 2:  # Fire theme (red-orange-yellow)
            r = (255 * normalized).astype(np.uint8)
            g = (255 * normalized ** 0.5).astype(np.uint8)
            b = (255 * normalized ** 2).astype(np.uint8)
        elif color_scheme == 3:  # Ocean theme (blue-cyan-white)
            r = (255 * normalized ** 2).astype(np.uint8)
            g = (255 * normalized ** 0.7).astype(np.uint8)
            b = (255 * normalized).astype(np.uint8)
        elif color_scheme == 4:  # Electric theme (purple-pink-cyan)
            r = (255 * (0.5 + 0.5 * np.sin(normalized * 4 * np.pi))).astype(np.uint8)
            g = (255 * normalized ** 0.3).astype(np.uint8)
            b = (255 * (0.7 + 0.3 * np.cos(normalized * 3 * np.pi))).astype(np.uint8)
        elif color_scheme == 5:  # Sunset theme (orange-red-purple)
            r = (255 * (0.8 + 0.2 * normalized)).astype(np.uint8)
            g = (255 * normalized ** 1.5).astype(np.uint8)
            b = (255 * normalized ** 0.5).astype(np.uint8)
        elif color_scheme == 6:  # Forest theme (green-yellow-brown)
            r = (255 * normalized ** 1.2).astype(np.uint8)
            g = (255 * (0.3 + 0.7 * normalized)).astype(np.uint8)
            b = (255 * normalized ** 3).astype(np.uint8)
        elif color_scheme == 7:  # Galaxy theme (deep purple-blue-white)
            r = (255 * (0.2 + 0.8 * normalized ** 0.8)).astype(np.uint8)
            g = (255 * normalized ** 1.5).astype(np.uint8)
            b = (255 * (0.6 + 0.4 * normalized)).astype(np.uint8)
        else:  # Neon theme (bright cycling colors)
            r = (255 * (0.5 + 0.5 * np.cos(normalized * 6 * np.pi))).astype(np.uint8)
            g = (255 * (0.5 + 0.5 * np.sin(normalized * 4 * np.pi))).astype(np.uint8)
            b = (255 * (0.5 + 0.5 * np.sin(normalized * 8 * np.pi + 1))).astype(np.uint8)
        
        rgb_array = np.stack([r, g, b], axis=-1)
        
        return Image.fromarray(rgb_array)
    
    def generate_image(self):
        """Generate and store current image with timeout protection"""
        try:
            start_time = time.time()
            self.current_image = self.generate_mandelbrot()
            gen_time = time.time() - start_time
            
            # Warn if generation is getting slow
            if gen_time > 20:
                print(f"⚠️  Generation took {gen_time:.2f}s - consider reducing parameters")
            elif gen_time > 30:
                print(f"🐌 Generation took {gen_time:.2f}s - too slow!")
            
            print(f"Generated 600x600 colorful Mandelbrot at {time.strftime('%H:%M:%S')} ({gen_time:.2f}s)")
        except Exception as e:
            print(f"Error generating image: {e}")
            # Generate a simple fallback image if there's an error
            try:
                self.current_image = self.generate_simple_fallback()
            except:
                pass
    
    def generate_simple_fallback(self):
        """Generate a simple colorful pattern as fallback"""
        size = 300
        x = np.linspace(-2, 2, size)
        y = np.linspace(-2, 2, size)
        X, Y = np.meshgrid(x, y)
        Z = np.sin(X) * np.cos(Y) * 127 + 128
        
        # Simple rainbow colormap
        r = (Z).astype(np.uint8)
        g = ((Z + 85) % 255).astype(np.uint8)
        b = ((Z + 170) % 255).astype(np.uint8)
        
        rgb_array = np.stack([r, g, b], axis=-1)
        return Image.fromarray(rgb_array)
    
    def start_background_generation(self):
        """Start generating new images every 10 seconds"""
        def generation_loop():
            while True:
                time.sleep(10)
                self.generate_image()
        
        thread = threading.Thread(target=generation_loop, daemon=True)
        thread.start()
        print("Started background generation - new random image every 10 seconds")

# Initialize generator
generator = ImageGenerator()

@app.route('/')
def get_image():
    """Main endpoint - returns current image"""
    if generator.current_image is None:
        return "No image available", 500
    
    img_buffer = io.BytesIO()
    generator.current_image.save(img_buffer, format='PNG')
    img_buffer.seek(0)
    
    return send_file(img_buffer, mimetype='image/png')

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    print(f"🚀 Starting minimal app on http://localhost:{port}")
    print("📸 New image generated every 10 seconds")
    app.run(host='0.0.0.0', port=port)

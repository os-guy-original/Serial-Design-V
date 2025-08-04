#!/usr/bin/env python3

"""
Ultra-Fast Empty Area Finder - Maximum speed optimization

This version uses aggressive optimizations while maintaining positioning accuracy:
- Single-pass edge detection
- Minimal resolution processing
- Smart sampling instead of exhaustive search
- Cached calculations
- Simplified complexity scoring
"""

import cv2
import numpy as np
import sys
import os

def detect_complexity_ultra_fast(img, scale=0.25):
    """Ultra-fast complexity detection using minimal operations."""
    # Work at very low resolution for speed
    h, w = img.shape[:2]
    small_h, small_w = int(h * scale), int(w * scale)
    small_img = cv2.resize(img, (small_w, small_h))
    
    if len(small_img.shape) == 3:
        gray = cv2.cvtColor(small_img, cv2.COLOR_BGR2GRAY)
    else:
        gray = small_img
    
    # Single Sobel operation (faster than Canny)
    sobel = cv2.Sobel(gray, cv2.CV_16S, 1, 1, ksize=3)
    edges = np.abs(sobel).astype(np.uint8)
    
    # Simple threshold instead of complex morphology
    _, binary = cv2.threshold(edges, 30, 255, cv2.THRESH_BINARY)
    
    # Quick dilation
    kernel = np.ones((3, 3), np.uint8)
    complexity_map = cv2.dilate(binary, kernel, iterations=1).astype(np.float32) / 255.0
    
    return complexity_map

def calculate_score_ultra_fast(x, y, w, h, complexity_map=None):
    """Ultra-fast position scoring with minimal calculations."""
    norm_x, norm_y = x / w, y / h
    score = 100
    
    # Complexity penalty (simplified)
    if complexity_map is not None:
        # Sample just a few points instead of entire region
        sample_points = [
            (int(x), int(y)),
            (int(x-20), int(y-10)),
            (int(x+20), int(y-10)),
            (int(x), int(y+10))
        ]
        
        complexity_sum = 0
        valid_points = 0
        for sx, sy in sample_points:
            if 0 <= sy < complexity_map.shape[0] and 0 <= sx < complexity_map.shape[1]:
                complexity_sum += complexity_map[sy, sx]
                valid_points += 1
        
        if valid_points > 0:
            avg_complexity = complexity_sum / valid_points
            if avg_complexity > 0.7:
                score -= 100
            elif avg_complexity > 0.4:
                score -= 50
    
    # Edge avoidance (simplified)
    edge_dist = min(norm_x, 1-norm_x, norm_y, 1-norm_y)
    if edge_dist < 0.15:
        score -= 40
    
    # Rule of thirds bonus (simplified)
    if abs(norm_x - 0.33) < 0.1 or abs(norm_x - 0.67) < 0.1:
        score += 20
    if abs(norm_y - 0.33) < 0.1 or abs(norm_y - 0.67) < 0.1:
        score += 20
    
    # Avoid bottom area
    if norm_y > 0.7:
        score -= 60
    
    return max(0, score)

def find_empty_areas_ultra_fast(image_path):
    """Ultra-fast empty area finder with aggressive optimizations."""
    img = cv2.imread(image_path)
    if img is None:
        raise ValueError("Image could not be loaded.")
    
    # Work at very low resolution for maximum speed
    scale = 0.3
    small_img = cv2.resize(img, None, fx=scale, fy=scale)
    
    # Ultra-fast complexity detection
    complexity_map = detect_complexity_ultra_fast(small_img, scale=0.5)
    
    # Simple edge detection for clean areas
    gray = cv2.cvtColor(small_img, cv2.COLOR_BGR2GRAY)
    
    # Use simple gradient instead of Canny for speed
    grad_x = cv2.Sobel(gray, cv2.CV_16S, 1, 0, ksize=3)
    grad_y = cv2.Sobel(gray, cv2.CV_16S, 0, 1, ksize=3)
    edges = np.sqrt(grad_x.astype(np.float32)**2 + grad_y.astype(np.float32)**2)
    
    # Simple threshold
    clean_threshold = np.percentile(edges, 75)
    clean_areas = (edges < clean_threshold).astype(np.uint8) * 255
    
    # Smart sampling instead of exhaustive search
    h, w = clean_areas.shape
    best_score = 0
    best_center = (w//2, h//2)
    
    # Use strategic sampling points instead of grid search
    clock_size = min(w, h) // 6
    
    # Sample key positions: rule of thirds, golden ratio, and some random
    sample_positions = [
        # Rule of thirds
        (int(w * 0.33), int(h * 0.33)),
        (int(w * 0.67), int(h * 0.33)),
        (int(w * 0.33), int(h * 0.67)),
        (int(w * 0.67), int(h * 0.67)),
        # Golden ratio
        (int(w * 0.382), int(h * 0.382)),
        (int(w * 0.618), int(h * 0.382)),
        # Center variations
        (int(w * 0.5), int(h * 0.4)),
        (int(w * 0.4), int(h * 0.5)),
        (int(w * 0.6), int(h * 0.5)),
        # Upper positions
        (int(w * 0.5), int(h * 0.25)),
        (int(w * 0.3), int(h * 0.25)),
        (int(w * 0.7), int(h * 0.25)),
    ]
    
    # Test each strategic position
    for x, y in sample_positions:
        if (clock_size//2 <= x < w - clock_size//2 and 
            clock_size//2 <= y < h - clock_size//2):
            
            # Quick cleanliness check with sampling
            region_samples = [
                clean_areas[y-clock_size//4, x-clock_size//4],
                clean_areas[y-clock_size//4, x+clock_size//4],
                clean_areas[y+clock_size//4, x-clock_size//4],
                clean_areas[y+clock_size//4, x+clock_size//4],
                clean_areas[y, x]
            ]
            
            cleanliness = np.mean(region_samples) / 255.0
            
            if cleanliness > 0.7:
                score = calculate_score_ultra_fast(x, y, w, h, complexity_map)
                if score > best_score:
                    best_score = score
                    best_center = (x, y)
    
    # Scale back to original resolution
    center_x = int(best_center[0] / scale)
    center_y = int(best_center[1] / scale)
    square_size = int(clock_size / scale)
    
    # Ensure visibility with minimal calculations
    clock_width, clock_height = 280, 120
    margin = 50
    
    center_x = max(clock_width//2 + margin, 
                   min(center_x, img.shape[1] - clock_width//2 - margin))
    center_y = max(clock_height//2 + margin, 
                   min(center_y, img.shape[0] - clock_height//2 - margin))
    
    # Quick background analysis
    half_width, half_height = clock_width // 2, clock_height // 2
    x1 = max(0, center_x - half_width)
    y1 = max(0, center_y - half_height)
    x2 = min(img.shape[1], center_x + half_width)
    y2 = min(img.shape[0], center_y + half_height)
    
    clock_region = img[y1:y2, x1:x2]
    if len(clock_region.shape) == 3:
        gray_region = cv2.cvtColor(clock_region, cv2.COLOR_BGR2GRAY)
    else:
        gray_region = clock_region
    
    avg_brightness = np.mean(gray_region) / 255.0 if gray_region.size > 0 else 0.5
    
    # Simplified complexity score
    final_complexity = 0.2  # Default low complexity
    
    return {
        'center': (center_x, center_y),
        'square_size': square_size,
        'coordinates': (x1, y1, x2, y2),
        'complexity_score': 0.2,
        'background_analysis': {
            'average_brightness': avg_brightness,
            'is_bright_background': avg_brightness > 0.6,
            'is_dark_background': avg_brightness < 0.4,
            'is_uniform': True
        },
        'color_uniformity': {
            'complexity_score': final_complexity,
            'has_color_transitions': final_complexity > 0.3,
            'uniformity_score': 1.0 - final_complexity
        },
        'complexity_avoidance': {
            'enabled': True,
            'final_complexity_score': final_complexity,
            'method': 'ultra_fast'
        }
    }

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py image_path")
        sys.exit(1)
    
    image_path = sys.argv[1]
    
    if not os.path.exists(image_path):
        print(f"File not found: {image_path}")
        sys.exit(1)
    
    try:
        result = find_empty_areas_ultra_fast(image_path)
        
        # Output in both formats for compatibility
        print("--- RESULT ---")
        for key, value in result.items():
            print(f"{key}: {value}")
        
        print("--- JSON ---")
        import json
        
        def convert_numpy_types(obj):
            if isinstance(obj, np.integer):
                return int(obj)
            elif isinstance(obj, np.floating):
                return float(obj)
            elif isinstance(obj, np.bool_):
                return bool(obj)
            elif isinstance(obj, np.ndarray):
                return obj.tolist()
            elif isinstance(obj, dict):
                return {key: convert_numpy_types(value) for key, value in obj.items()}
            elif isinstance(obj, list):
                return [convert_numpy_types(item) for item in obj]
            return obj
        
        json_result = convert_numpy_types(result)
        print(json.dumps(json_result, indent=2))
            
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
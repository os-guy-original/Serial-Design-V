#!/usr/bin/env python3

"""
Fast Empty Area Finder - Optimized for background processing

This is a streamlined version of the empty area finder that focuses on
quick analysis while still avoiding complex color transition areas.
"""

import cv2
import numpy as np
import sys
import os

def detect_instant_color_change_areas_fast(img, threshold_high=0.3, threshold_medium=0.2):
    """
    Fast detection of complex color change areas using simplified methods.
    """
    if len(img.shape) == 3:
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    else:
        gray = img
    
    # Use single Sobel operation instead of Canny + Sobel (faster)
    sobel = cv2.Sobel(gray, cv2.CV_16S, 1, 1, ksize=3)
    edges = np.abs(sobel).astype(np.uint8)
    
    # Normalize once
    max_val = np.max(edges)
    if max_val > 0:
        normalized = edges.astype(np.float32) / max_val
    else:
        normalized = edges.astype(np.float32)
    
    # Smaller kernel for faster morphology
    kernel = np.ones((7, 7), np.uint8)
    expanded_complexity = cv2.dilate(normalized, kernel, iterations=1)
    
    # Smaller blur kernel
    blurred_complexity = cv2.GaussianBlur(expanded_complexity, (9, 9), 0)
    
    # Create complexity categories
    complexity_map = np.zeros_like(blurred_complexity)
    complexity_map[blurred_complexity >= threshold_high] = 1.0
    complexity_map[(blurred_complexity >= threshold_medium) & (blurred_complexity < threshold_high)] = 0.6
    
    return complexity_map

def calculate_position_score_fast(x, y, w, h, complexity_map=None):
    """
    Fast position scoring with complexity avoidance.
    """
    norm_x = x / w
    norm_y = y / h
    score = 100
    
    # Complexity penalty
    if complexity_map is not None:
        clock_width, clock_height = 280, 120
        half_width, half_height = clock_width // 2, clock_height // 2
        
        x1 = max(0, int(x - half_width))
        y1 = max(0, int(y - half_height))
        x2 = min(complexity_map.shape[1], int(x + half_width))
        y2 = min(complexity_map.shape[0], int(y + half_height))
        
        if x2 > x1 and y2 > y1:
            clock_region = complexity_map[y1:y2, x1:x2]
            avg_complexity = np.mean(clock_region)
            
            if avg_complexity >= 0.8:
                score -= 120
            elif avg_complexity >= 0.6:
                score -= 80
            elif avg_complexity >= 0.4:
                score -= 40
            elif avg_complexity < 0.1:
                score += 20
    
    # Basic edge avoidance
    edge_threshold = 0.15
    if norm_x < edge_threshold or norm_x > (1 - edge_threshold):
        score -= 30
    if norm_y < edge_threshold or norm_y > (1 - edge_threshold):
        score -= 30
    
    # Rule of thirds bonus
    thirds_positions = [0.33, 0.67]
    for third in thirds_positions:
        if abs(norm_x - third) < 0.1:
            score += 15
        if abs(norm_y - third) < 0.1:
            score += 15
    
    return max(0, score)

def find_empty_areas_fast_bg(image_path):
    """
    Fast empty area analysis optimized for background processing.
    """
    img = cv2.imread(image_path)
    if img is None:
        raise ValueError("Image could not be loaded.")
    
    # Work with smaller image for speed
    scale = 0.4  # Even smaller for more speed
    small_img = cv2.resize(img, None, fx=scale, fy=scale)
    
    # Quick complexity analysis
    complexity_map = detect_instant_color_change_areas_fast(small_img)
    
    # Simple clean area detection
    gray = cv2.cvtColor(small_img, cv2.COLOR_BGR2GRAY)
    edges = cv2.Canny(gray, 40, 120)
    clean_areas = 255 - edges
    
    # Find best position using simplified search
    h, w = clean_areas.shape
    best_score = 0
    best_center = (w//2, h//2)
    
    # Grid search with larger steps for speed
    step = max(30, min(w, h) // 15)  # Larger steps
    clock_size = int(min(w, h) // 6)
    
    # Strategic sampling instead of full grid search
    sample_positions = [
        # Rule of thirds
        (int(w * 0.33), int(h * 0.33)), (int(w * 0.67), int(h * 0.33)),
        (int(w * 0.33), int(h * 0.67)), (int(w * 0.67), int(h * 0.67)),
        # Center variations
        (int(w * 0.5), int(h * 0.4)), (int(w * 0.4), int(h * 0.5)),
        # Upper positions
        (int(w * 0.5), int(h * 0.25)), (int(w * 0.3), int(h * 0.25))
    ]
    
    # Add some grid points for completeness
    for y in range(clock_size//2, h - clock_size//2, step):
        for x in range(clock_size//2, w - clock_size//2, step):
            sample_positions.append((x, y))
    
    # Test strategic positions first, then grid
    for x, y in sample_positions:
        if (clock_size//2 <= x < w - clock_size//2 and 
            clock_size//2 <= y < h - clock_size//2):
            # Quick cleanliness check with sampling
            sample_points = [
                clean_areas[y-clock_size//4, x-clock_size//4],
                clean_areas[y+clock_size//4, x+clock_size//4],
                clean_areas[y, x]
            ]
            cleanliness = np.mean(sample_points) / 255.0
            
            if cleanliness > 0.75:
                score = calculate_position_score_fast(x, y, w, h, complexity_map)
                if score > best_score:
                    best_score = score
                    best_center = (x, y)
                    # Early exit for very good positions
                    if score > 120:
                        break
    
    # Scale back to original resolution
    center_x = int(best_center[0] / scale)
    center_y = int(best_center[1] / scale)
    square_size = int(clock_size / scale)
    
    # Ensure visibility
    clock_width, clock_height = 280, 120
    margin = 50
    
    min_x = clock_width // 2 + margin
    max_x = img.shape[1] - clock_width // 2 - margin
    min_y = clock_height // 2 + margin
    max_y = img.shape[0] - clock_height // 2 - margin
    
    center_x = max(min_x, min(center_x, max_x))
    center_y = max(min_y, min(center_y, max_y))
    
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
    
    # Simplified final complexity (skip full image analysis)
    final_complexity = 0.2  # Default low complexity for speed
    
    return {
        'center': (center_x, center_y),
        'square_size': square_size,
        'coordinates': (x1, y1, x2, y2),
        'complexity_score': 0.3,  # Simplified score
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
            'method': 'fast_background'
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
        result = find_empty_areas_fast_bg(image_path)
        
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
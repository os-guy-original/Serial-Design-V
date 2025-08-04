import cv2
import numpy as np
import sys
import os

def analyze_image_complexity(edges, binary_map):
    """
    Analyzes the complexity level of the image.
    """
    h, w = edges.shape
    
    edge_density = np.sum(edges > 0) / (h * w)
    clean_area_ratio = np.sum(binary_map > 0) / (h * w)
    
    grid_size = 4
    cell_h, cell_w = h // grid_size, w // grid_size
    edge_densities = []
    
    for i in range(grid_size):
        for j in range(grid_size):
            y1, y2 = i * cell_h, (i + 1) * cell_h
            x1, x2 = j * cell_w, (j + 1) * cell_w
            cell = edges[y1:y2, x1:x2]
            cell_density = np.sum(cell > 0) / cell.size
            edge_densities.append(cell_density)
    
    edge_distribution_std = np.std(edge_densities)
    
    complexity_score = 0
    complexity_score += edge_density * 0.6
    complexity_score += (1 - clean_area_ratio) * 0.25
    complexity_score += min(edge_distribution_std * 2, 1) * 0.15
    complexity_score = min(1, max(0, complexity_score))
    
    return complexity_score, {
        'edge_density': edge_density,
        'clean_area_ratio': clean_area_ratio,
        'edge_distribution_std': edge_distribution_std
    }

def find_largest_square_adaptive(binary_map, complexity_score, complexity_map=None):
    """
    Adaptive square finding based on complexity level.
    Now includes complexity map for avoiding instant color change areas.
    """
    h, w = binary_map.shape
    integral = cv2.integral(binary_map.astype(np.float32))
    
    # Always try aesthetics first for better positioning
    size_aesthetic, center_aesthetic = find_square_by_aesthetics(binary_map, integral, complexity_map)
    
    # If aesthetic approach gives a reasonable result, use it
    min_acceptable_size = min(h, w) // 10
    if size_aesthetic >= min_acceptable_size:
        return size_aesthetic, center_aesthetic
    
    # Otherwise fall back to size-based approach
    return find_largest_square_by_size(binary_map, integral)

def find_largest_square_by_size(binary_map, integral):
    """
    Size-focused - finds the largest square.
    """
    h, w = binary_map.shape
    max_size = 0
    best_center = (w//2, h//2)
    
    left, right = 20, min(h, w)
    
    while left <= right:
        size = (left + right) // 2
        found = False
        
        step = max(1, size // 8)
        
        for y in range(0, h - size + 1, step):
            for x in range(0, w - size + 1, step):
                area_sum = (integral[y+size, x+size] - 
                            integral[y, x+size] - 
                            integral[y+size, x] + 
                            integral[y, x])
                
                expected_sum = size * size * 255
                
                if abs(area_sum - expected_sum) < size * 3:
                    max_size = size
                    best_center = (x + size//2, y + size//2)
                    found = True
                    break
            if found:
                break
        
        if found:
            left = size + 1
        else:
            right = size - 1
    
    return max_size, best_center

def find_square_by_aesthetics(binary_map, integral, complexity_map=None):
    """
    Enhanced aesthetics-focused algorithm for better clock positioning.
    Now avoids complex instant color change areas.
    """
    h, w = binary_map.shape
    
    # Improved center logo detection with multiple regions
    center_region = binary_map[h//3:2*h//3, w//3:2*w//3]
    center_density = np.sum(center_region == 0) / center_region.size
    
    # Also check for logos in upper center (common for wallpapers)
    upper_center = binary_map[h//6:h//2, w//3:2*w//3]
    upper_center_density = np.sum(upper_center == 0) / upper_center.size
    
    has_center_logo = center_density > 0.12 or upper_center_density > 0.15
    
    best_score = 0
    best_size = 0
    best_center = (w//2, h//2)
    
    # Better size range - prioritize clock-appropriate sizes
    min_size = int(min(h, w) // 15)  # Smaller minimum for more flexibility
    max_size = int(min(h, w) // 2.5)  # Reasonable maximum
    
    # Create a more focused search pattern
    preferred_sizes = []
    
    # Add some specific good sizes for clocks
    clock_optimal_sizes = [
        int(min(h, w) // 6),   # Small but readable
        int(min(h, w) // 5),   # Medium
        int(min(h, w) // 4),   # Large
        int(min(h, w) // 3.5), # Extra large
    ]
    
    for size in clock_optimal_sizes:
        if min_size <= size <= max_size:
            preferred_sizes.append(size)
    
    # Add a range of other sizes
    step_size = max(1, int((max_size - min_size) // 20))
    for size in range(max_size, min_size, -step_size):
        if size not in preferred_sizes:
            preferred_sizes.append(size)
    
    # Search with better positioning strategy
    for size in preferred_sizes:
        # Use smaller steps for more thorough search
        step = max(1, int(size // 8))
        
        # Create a grid of candidate positions
        positions_to_try = []
        
        # Add rule of thirds positions first (these are usually best)
        thirds_x = [int(w * 0.33), int(w * 0.67)]
        thirds_y = [int(h * 0.33), int(h * 0.67)]
        
        for tx in thirds_x:
            for ty in thirds_y:
                if (size//2 <= tx <= w - size//2 and 
                    size//2 <= ty <= h - size//2):
                    positions_to_try.append((int(tx - size//2), int(ty - size//2)))
        
        # Add golden ratio positions
        golden_x = [int(w * 0.382), int(w * 0.618)]
        golden_y = [int(h * 0.382), int(h * 0.618)]
        
        for gx in golden_x:
            for gy in golden_y:
                if (size//2 <= gx <= w - size//2 and 
                    size//2 <= gy <= h - size//2):
                    positions_to_try.append((int(gx - size//2), int(gy - size//2)))
        
        # Add systematic grid search
        for y in range(0, int(h * 0.7) - size + 1, step):
            for x in range(0, w - size + 1, step):
                positions_to_try.append((x, y))
        
        # Remove duplicates while preserving order
        seen = set()
        unique_positions = []
        for pos in positions_to_try:
            if pos not in seen:
                seen.add(pos)
                unique_positions.append(pos)
        
        # Test each position
        for x, y in unique_positions:
            area_sum = (integral[y+size, x+size] - 
                        integral[y, x+size] - 
                        integral[y+size, x] + 
                        integral[y, x])
            
            expected_sum = size * size * 255
            
            # More sophisticated clean area check
            cleanliness_ratio = area_sum / expected_sum
            if cleanliness_ratio > 0.85:  # At least 85% clean
                center_x, center_y = x + size//2, y + size//2
                position_score = calculate_position_score(center_x, center_y, w, h, has_center_logo, complexity_map)
                
                # Enhanced scoring system
                size_score = (size / max_size) * 40
                cleanliness_score = (cleanliness_ratio - 0.85) / 0.15 * 20  # Bonus for very clean areas
                
                # Bonus for rule of thirds or golden ratio positions
                aesthetic_bonus = 0
                norm_x, norm_y = center_x / w, center_y / h
                
                # Rule of thirds bonus
                if (abs(norm_x - 0.33) < 0.05 or abs(norm_x - 0.67) < 0.05 or
                    abs(norm_y - 0.33) < 0.05 or abs(norm_y - 0.67) < 0.05):
                    aesthetic_bonus += 15
                
                # Golden ratio bonus
                if (abs(norm_x - 0.382) < 0.05 or abs(norm_x - 0.618) < 0.05 or
                    abs(norm_y - 0.382) < 0.05 or abs(norm_y - 0.618) < 0.05):
                    aesthetic_bonus += 10
                
                total_score = position_score * 0.6 + size_score * 0.2 + cleanliness_score * 0.1 + aesthetic_bonus * 0.1
                
                if total_score > best_score:
                    best_score = total_score
                    best_size = size
                    best_center = (center_x, center_y)
        
        # If we found a really good position, we can stop early
        if best_score > 120:  # High threshold for excellent positions
            break
    
    return best_size, best_center

def calculate_position_score(x, y, w, h, has_center_logo, complexity_map=None):
    """
    Enhanced position scoring for better clock placement.
    Now includes complexity avoidance for instant color change areas.
    """
    norm_x = x / w
    norm_y = y / h
    
    score = 100
    
    # NEW: Heavy penalty for complex color transition areas
    complexity_penalty = 0
    if complexity_map is not None:
        # Define clock area
        clock_width, clock_height = 280, 120
        half_width, half_height = clock_width // 2, clock_height // 2
        
        # Calculate region bounds
        x1 = max(0, int(x - half_width))
        y1 = max(0, int(y - half_height))
        x2 = min(complexity_map.shape[1], int(x + half_width))
        y2 = min(complexity_map.shape[0], int(y + half_height))
        
        if x2 > x1 and y2 > y1:
            clock_complexity_region = complexity_map[y1:y2, x1:x2]
            avg_complexity = np.mean(clock_complexity_region)
            max_complexity = np.max(clock_complexity_region)
            
            # Very heavy penalty for high complexity areas
            if avg_complexity >= 0.8:
                complexity_penalty += 150  # Extremely high penalty
            elif avg_complexity >= 0.6:
                complexity_penalty += 100  # High penalty
            elif avg_complexity >= 0.4:
                complexity_penalty += 60   # Moderate penalty
            elif avg_complexity >= 0.2:
                complexity_penalty += 30   # Light penalty
            
            # Additional penalty if any part of the clock area is very complex
            if max_complexity >= 1.0:
                complexity_penalty += 80  # Extra penalty for any high-complexity pixels
            
            # Bonus for very uniform areas
            if avg_complexity < 0.1:
                score += 25  # Bonus for very clean areas
    
    score -= complexity_penalty
    
    # Strong penalty for positions too close to edges
    edge_penalty = 0
    edge_threshold = 0.12
    
    if norm_x < edge_threshold:
        edge_penalty += 40 * (edge_threshold - norm_x) / edge_threshold
    elif norm_x > (1 - edge_threshold):
        edge_penalty += 40 * (norm_x - (1 - edge_threshold)) / edge_threshold
        
    if norm_y < edge_threshold:
        edge_penalty += 40 * (edge_threshold - norm_y) / edge_threshold
    elif norm_y > (1 - edge_threshold):
        edge_penalty += 40 * (norm_y - (1 - edge_threshold)) / edge_threshold
    
    score -= edge_penalty
    
    # Penalty for being too low on the screen
    low_position_penalty = 0
    if norm_y > 0.6: # Penalize starting from 60% of the way down
        low_position_penalty = 250 * (norm_y - 0.6) / 0.4 # Penalize from 0 to 250 in the bottom 40%
    score -= low_position_penalty

    # Handle center logo scenarios
    if has_center_logo:
        # Strongly prefer top and bottom areas, avoid center
        if norm_y < 0.3:  # Top area
            score += 50 * (0.3 - norm_y) / 0.3  # More bonus for higher positions
        elif 0.35 < norm_y < 0.65:  # Center area (logo zone)
            score -= 60  # Strong penalty for logo area
        
        # Prefer horizontal center when avoiding logo
        horizontal_center_bonus = 30 * (1 - abs(norm_x - 0.5) * 2)
        score += horizontal_center_bonus
    else:
        # No center logo - use sophisticated positioning
        
        # Rule of thirds positions (photography composition rule)
        thirds_bonus = 0
        thirds_positions = [0.33, 0.67]
        
        for third in thirds_positions:
            if abs(norm_x - third) < 0.08:
                thirds_bonus += 25
            if abs(norm_y - third) < 0.08:
                thirds_bonus += 25
        
        score += thirds_bonus
        
        # Golden ratio positions (even better aesthetically)
        golden_bonus = 0
        golden_positions = [0.382, 0.618]
        
        for golden in golden_positions:
            if abs(norm_x - golden) < 0.06:
                golden_bonus += 30
            if abs(norm_y - golden) < 0.06:
                golden_bonus += 30
        
        score += golden_bonus
        
        # Slight preference for upper-left quadrant (natural reading pattern)
        if norm_x < 0.5 and norm_y < 0.5:
            score += 15
    
    # Clock-specific preferences
    
    # Prefer positions that aren't too centered (clocks look better offset)
    center_distance = ((norm_x - 0.5)**2 + (norm_y - 0.5)**2)**0.5
    if 0.15 < center_distance < 0.4:  # Sweet spot - not too centered, not too far
        score += 20
    elif center_distance < 0.1:  # Too centered
        score -= 25
    
    # Prefer upper half slightly (clocks are often in upper areas)
    if norm_y < 0.55:
        score += 8
    
    # Avoid extreme corners more strongly
    corner_penalty = 0
    corner_threshold = 0.2
    
    corners = [(0, 0), (1, 0), (0, 1), (1, 1)]
    for corner_x, corner_y in corners:
        corner_dist = ((norm_x - corner_x)**2 + (norm_y - corner_y)**2)**0.5
        if corner_dist < corner_threshold:
            corner_penalty += 35 * (corner_threshold - corner_dist) / corner_threshold
    
    score -= corner_penalty
    
    return max(0, score)

def detect_instant_color_change_areas(img, threshold_high=0.25, threshold_medium=0.15):
    """
    Detect areas with instant/complex color changes that should be avoided for clock placement.
    Returns a map where higher values indicate more complex color transition areas.
    """
    if len(img.shape) == 3:
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    else:
        gray = img
    
    # Multiple edge detection methods for comprehensive analysis
    
    # 1. Canny edge detection for sharp transitions
    canny_edges = cv2.Canny(gray, 50, 150)
    
    # 2. Sobel gradients for directional changes
    sobel_x = cv2.Sobel(gray, cv2.CV_64F, 1, 0, ksize=3)
    sobel_y = cv2.Sobel(gray, cv2.CV_64F, 0, 1, ksize=3)
    sobel_magnitude = np.sqrt(sobel_x**2 + sobel_y**2)
    sobel_normalized = (sobel_magnitude / np.max(sobel_magnitude) * 255).astype(np.uint8)
    
    # 3. Laplacian for detecting rapid intensity changes
    laplacian = cv2.Laplacian(gray, cv2.CV_64F)
    laplacian_abs = np.abs(laplacian)
    laplacian_normalized = (laplacian_abs / np.max(laplacian_abs) * 255).astype(np.uint8)
    
    # 4. Color-based analysis if image is colored
    color_complexity = np.zeros_like(gray, dtype=np.float32)
    if len(img.shape) == 3:
        # Convert to LAB for perceptual color differences
        lab_img = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
        
        # Calculate color gradients in LAB space
        for channel in range(3):
            grad_x = cv2.Sobel(lab_img[:, :, channel], cv2.CV_64F, 1, 0, ksize=3)
            grad_y = cv2.Sobel(lab_img[:, :, channel], cv2.CV_64F, 0, 1, ksize=3)
            color_grad = np.sqrt(grad_x**2 + grad_y**2)
            color_complexity += color_grad
        
        color_complexity = (color_complexity / np.max(color_complexity) * 255).astype(np.uint8)
    
    # Combine all detection methods
    combined_complexity = np.maximum.reduce([
        canny_edges.astype(np.float32) / 255.0,
        sobel_normalized.astype(np.float32) / 255.0,
        laplacian_normalized.astype(np.float32) / 255.0,
        color_complexity.astype(np.float32) / 255.0
    ])
    
    # Apply morphological operations to expand complex areas
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (15, 15))
    expanded_complexity = cv2.dilate(combined_complexity, kernel, iterations=1)
    
    # Apply Gaussian blur to create smooth transition zones
    blurred_complexity = cv2.GaussianBlur(expanded_complexity, (21, 21), 0)
    
    # Create complexity categories
    complexity_map = np.zeros_like(blurred_complexity)
    complexity_map[blurred_complexity >= threshold_high] = 1.0  # High complexity - avoid strongly
    complexity_map[(blurred_complexity >= threshold_medium) & (blurred_complexity < threshold_high)] = 0.6  # Medium complexity - avoid moderately
    complexity_map[blurred_complexity < threshold_medium] = 0.0  # Low complexity - safe areas
    
    return complexity_map, {
        'high_complexity_ratio': np.sum(complexity_map >= 1.0) / complexity_map.size,
        'medium_complexity_ratio': np.sum((complexity_map >= 0.6) & (complexity_map < 1.0)) / complexity_map.size,
        'safe_area_ratio': np.sum(complexity_map < 0.6) / complexity_map.size,
        'average_complexity': np.mean(blurred_complexity)
    }

def analyze_color_uniformity(img, center_x, center_y, clock_width=280, clock_height=120):
    """
    Analyze color uniformity and detect instant color change areas.
    Enhanced to work with the new complexity detection system.
    """
    # Define the area where the clock will be placed
    half_width = clock_width // 2
    half_height = clock_height // 2
    
    # Calculate the region bounds
    x1 = max(0, center_x - half_width)
    y1 = max(0, center_y - half_height)
    x2 = min(img.shape[1], center_x + half_width)
    y2 = min(img.shape[0], center_y + half_height)
    
    # Extract the region where the clock will be
    clock_region = img[y1:y2, x1:x2]
    
    if clock_region.size == 0:
        return {
            'color_variance': 1.0,
            'has_color_transitions': True,
            'uniformity_score': 0.0,
            'gradient_strength': 1.0,
            'complexity_score': 1.0
        }
    
    # Get complexity map for the entire image
    complexity_map, complexity_stats = detect_instant_color_change_areas(img)
    
    # Extract complexity for the clock region
    clock_complexity = complexity_map[y1:y2, x1:x2]
    region_complexity_score = np.mean(clock_complexity)
    
    # Convert to different color spaces for analysis
    if len(clock_region.shape) == 3:
        # RGB analysis
        rgb_std = np.std(clock_region, axis=(0, 1))
        rgb_variance = np.mean(rgb_std) / 255.0
        
        # Convert to LAB for better perceptual uniformity analysis
        lab_region = cv2.cvtColor(clock_region, cv2.COLOR_BGR2LAB)
        lab_std = np.std(lab_region, axis=(0, 1))
        lab_variance = np.mean(lab_std) / 255.0
        
        # HSV analysis for hue transitions
        hsv_region = cv2.cvtColor(clock_region, cv2.COLOR_BGR2HSV)
        hue_std = np.std(hsv_region[:, :, 0]) / 180.0  # Hue is 0-180 in OpenCV
        
        gray_region = cv2.cvtColor(clock_region, cv2.COLOR_BGR2GRAY)
    else:
        gray_region = clock_region
        rgb_variance = np.std(gray_region) / 255.0
        lab_variance = rgb_variance
        hue_std = 0.0
    
    # Detect gradient/transition areas using Sobel operators
    sobel_x = cv2.Sobel(gray_region, cv2.CV_64F, 1, 0, ksize=3)
    sobel_y = cv2.Sobel(gray_region, cv2.CV_64F, 0, 1, ksize=3)
    gradient_magnitude = np.sqrt(sobel_x**2 + sobel_y**2)
    gradient_strength = np.mean(gradient_magnitude) / 255.0
    
    # Detect sharp color transitions using Laplacian
    laplacian = cv2.Laplacian(gray_region, cv2.CV_64F)
    edge_strength = np.mean(np.abs(laplacian)) / 255.0
    
    # Calculate local color variance in small patches
    patch_size = min(20, clock_region.shape[0]//4, clock_region.shape[1]//4)
    if patch_size > 5:
        patch_variances = []
        for y in range(0, gray_region.shape[0] - patch_size, patch_size//2):
            for x in range(0, gray_region.shape[1] - patch_size, patch_size//2):
                patch = gray_region[y:y+patch_size, x:x+patch_size]
                patch_var = np.std(patch) / 255.0
                patch_variances.append(patch_var)
        
        local_variance_std = np.std(patch_variances) if patch_variances else 0.0
    else:
        local_variance_std = 0.0
    
    # Combine metrics to determine uniformity
    color_variance = max(rgb_variance, lab_variance)
    
    # Enhanced detection of instant color changes using complexity score
    has_color_transitions = (
        region_complexity_score > 0.3 or  # High complexity from new detection
        gradient_strength > 0.15 or       # Strong gradients
        edge_strength > 0.2 or            # Sharp edges
        hue_std > 0.3 or                  # Hue variations
        local_variance_std > 0.1          # Inconsistent local patches
    )
    
    # Calculate uniformity score (higher = more uniform)
    # Factor in the complexity score heavily
    uniformity_score = 1.0 - min(1.0, 
        color_variance * 2 + 
        gradient_strength + 
        edge_strength * 0.5 + 
        region_complexity_score * 3  # Heavy penalty for complex areas
    )
    uniformity_score = max(0.0, uniformity_score)
    
    return {
        'color_variance': color_variance,
        'has_color_transitions': has_color_transitions,
        'uniformity_score': uniformity_score,
        'gradient_strength': gradient_strength,
        'edge_strength': edge_strength,
        'hue_variance': hue_std,
        'local_variance_std': local_variance_std,
        'complexity_score': region_complexity_score,
        'complexity_stats': complexity_stats
    }

def analyze_background_brightness(img, center_x, center_y, clock_width=280, clock_height=120):
    """
    Analyze the background brightness at the clock position.
    """
    # Define the area where the clock will be placed
    half_width = clock_width // 2
    half_height = clock_height // 2
    
    # Calculate the region bounds
    x1 = max(0, center_x - half_width)
    y1 = max(0, center_y - half_height)
    x2 = min(img.shape[1], center_x + half_width)
    y2 = min(img.shape[0], center_y + half_height)
    
    # Extract the region where the clock will be
    clock_region = img[y1:y2, x1:x2]
    
    # Convert to grayscale for brightness analysis
    if len(clock_region.shape) == 3:
        gray_region = cv2.cvtColor(clock_region, cv2.COLOR_BGR2GRAY)
    else:
        gray_region = clock_region
    
    # Calculate average brightness (0-1 scale)
    avg_brightness = np.mean(gray_region) / 255.0
    
    # Calculate brightness distribution for more accurate analysis
    brightness_std = np.std(gray_region) / 255.0
    
    # Get brightness percentiles for better understanding
    brightness_25 = np.percentile(gray_region, 25) / 255.0
    brightness_75 = np.percentile(gray_region, 75) / 255.0
    
    return {
        'average_brightness': avg_brightness,
        'brightness_std': brightness_std,
        'brightness_25': brightness_25,
        'brightness_75': brightness_75,
        'is_bright_background': avg_brightness > 0.6,
        'is_dark_background': avg_brightness < 0.4,
        'is_uniform': brightness_std < 0.1
    }

def find_empty_areas_fast(image_path):
    """
    Finds completely clean areas and returns the coordinates and size of the largest square.
    Enhanced to avoid complex instant color change areas.
    """
    img = cv2.imread(image_path)
    if img is None:
        raise ValueError("Image could not be loaded.")
    
    print(f"Analyzing wallpaper for empty areas, avoiding complex color transitions...")
    
    # Generate complexity map for the full-resolution image first
    complexity_map, complexity_stats = detect_instant_color_change_areas(img)
    print(f"Complexity analysis: {complexity_stats['safe_area_ratio']:.1%} safe areas, "
          f"{complexity_stats['high_complexity_ratio']:.1%} high complexity areas")
    
    original_size = max(img.shape[:2])
    if original_size > 1000:
        scale = 800 / original_size
    else:
        scale = 0.7
    
    small_img = cv2.resize(img, None, fx=scale, fy=scale)
    
    # Scale down the complexity map to match the working resolution
    small_complexity_map = cv2.resize(complexity_map, (small_img.shape[1], small_img.shape[0]))
    
    gray = cv2.cvtColor(small_img, cv2.COLOR_BGR2GRAY)
    gray = cv2.GaussianBlur(gray, (3, 3), 0)
    
    edges = cv2.Canny(gray, 40, 120)
    
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (4, 4))
    edges = cv2.dilate(edges, kernel, iterations=1)
    
    if np.sum(edges) < edges.size * 0.05:
        sobel_x = cv2.Sobel(gray, cv2.CV_16S, 1, 0, ksize=3)
        sobel_y = cv2.Sobel(gray, cv2.CV_16S, 0, 1, ksize=3)
        sobel_combined = np.sqrt(sobel_x.astype(np.float32)**2 + sobel_y.astype(np.float32)**2)
        sobel_thresh = (sobel_combined > np.percentile(sobel_combined, 85)).astype(np.uint8) * 255
        combined_edges = cv2.bitwise_or(edges, sobel_thresh)
    else:
        combined_edges = edges
    
    combined_edges = cv2.morphologyEx(combined_edges, cv2.MORPH_CLOSE,
                                      cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3)))
    
    clean_areas = 255 - combined_edges
    
    complexity_score, complexity_details = analyze_image_complexity(combined_edges, clean_areas)
    square_size, (center_x, center_y) = find_largest_square_adaptive(clean_areas, complexity_score, small_complexity_map)
    
    # Scale back to original resolution
    center_x = int(center_x / scale)
    center_y = int(center_y / scale)
    square_size = int(square_size / scale)
    
    min_size = min(img.shape[:2]) // 20
    if square_size < min_size:
        square_size = min_size
        center_x = img.shape[1] // 2
        center_y = img.shape[0] // 2
    
    # Ensure position is visible on screen with margin for clock widget
    clock_width = 280
    clock_height = 120
    margin = 50
    
    # Calculate bounds to keep clock fully visible
    min_x = clock_width // 2 + margin
    max_x = img.shape[1] - clock_width // 2 - margin
    min_y = clock_height // 2 + margin
    max_y = img.shape[0] - clock_height // 2 - margin
    
    # Clamp position to visible area
    if center_x < min_x:
        center_x = min_x
    elif center_x > max_x:
        center_x = max_x
        
    if center_y < min_y:
        center_y = min_y
    elif center_y > max_y:
        center_y = max_y
    
    # Final check: if the chosen position is still in a high complexity area,
    # try to find a nearby safer position
    final_complexity = analyze_color_uniformity(img, center_x, center_y, clock_width, clock_height)
    if final_complexity['complexity_score'] > 0.7:
        print(f"Warning: Selected position has high complexity ({final_complexity['complexity_score']:.2f}), "
              f"searching for safer nearby position...")
        
        # Try positions in a small radius around the current position
        best_alt_score = final_complexity['complexity_score']
        best_alt_pos = (center_x, center_y)
        
        search_radius = min(100, min(img.shape[:2]) // 10)
        for dx in range(-search_radius, search_radius + 1, 20):
            for dy in range(-search_radius, search_radius + 1, 20):
                alt_x = center_x + dx
                alt_y = center_y + dy
                
                # Check bounds
                if (min_x <= alt_x <= max_x and min_y <= alt_y <= max_y):
                    alt_analysis = analyze_color_uniformity(img, alt_x, alt_y, clock_width, clock_height)
                    if alt_analysis['complexity_score'] < best_alt_score:
                        best_alt_score = alt_analysis['complexity_score']
                        best_alt_pos = (alt_x, alt_y)
        
        if best_alt_pos != (center_x, center_y):
            center_x, center_y = best_alt_pos
            print(f"Found better position with complexity {best_alt_score:.2f}")
            final_complexity = analyze_color_uniformity(img, center_x, center_y, clock_width, clock_height)
    
    # Analyze background brightness at the final clock position
    background_analysis = analyze_background_brightness(img, center_x, center_y, clock_width, clock_height)
    
    half_size = square_size // 2
    x1 = max(0, center_x - half_size)
    y1 = max(0, center_y - half_size)
    x2 = min(img.shape[1], center_x + half_size)
    y2 = min(img.shape[0], center_y + half_size)
    
    print(f"Final position: ({center_x}, {center_y}) with complexity score {final_complexity['complexity_score']:.2f}")
    
    return {
        'center': (center_x, center_y),
        'square_size': square_size,
        'coordinates': (x1, y1, x2, y2),
        'complexity_score': complexity_score,
        'complexity_details': complexity_details,
        'background_analysis': background_analysis,
        'color_uniformity': final_complexity,
        'complexity_avoidance': {
            'enabled': True,
            'global_stats': complexity_stats,
            'final_complexity_score': final_complexity['complexity_score']
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
        # Pass the image path to the function and get the result dictionary
        result = find_empty_areas_fast(image_path)
        
        # Output in both formats for compatibility
        # First, the structured format for easy parsing
        print("--- RESULT ---")
        for key, value in result.items():
            print(f"{key}: {value}")
        
        # Then output as JSON for easier parsing by shell scripts
        print("--- JSON ---")
        import json
        
        # Convert numpy types to native Python types for JSON serialization
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
        print("Required: pip install opencv-python")
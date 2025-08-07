import cv2
import numpy as np
import sys
import os
import json

def analyze_image_complexity(cost_map, permissible_map):
    """
    Analyzes the complexity level of the image based on the cost map.
    This mimics the logic of the original script but uses the new cost map.
    """
    h, w = cost_map.shape
    
    # Edge density is analogous to the average cost
    edge_density = np.mean(cost_map) / 255.0
    
    # Clean area ratio from the permissible map
    clean_area_ratio = np.sum(permissible_map > 0) / (h * w)
    
    # Grid-based distribution analysis
    grid_size = 4
    cell_h, cell_w = h // grid_size, w // grid_size
    cost_densities = []
    
    for i in range(grid_size):
        for j in range(grid_size):
            cell = cost_map[i*cell_h:(i+1)*cell_h, j*cell_w:(j+1)*cell_w]
            cell_density = np.mean(cell) / 255.0 if cell.size > 0 else 0
            cost_densities.append(cell_density)
    
    cost_distribution_std = np.std(cost_densities)
    
    # Recreate the original complexity score formula
    complexity_score = 0
    complexity_score += edge_density * 0.6
    complexity_score += (1 - clean_area_ratio) * 0.25
    complexity_score += min(cost_distribution_std * 2, 1) * 0.15
    complexity_score = min(1, max(0, complexity_score))
    
    return complexity_score, {
        'edge_density': edge_density,
        'clean_area_ratio': clean_area_ratio,
        'edge_distribution_std': cost_distribution_std
    }

def detect_potential_logos(cost_map, h, w):
    """
    Detects potential logo-like regions by finding contours in the high-cost areas.
    Filters contours based on size, aspect ratio, and solidity.
    """
    # Threshold the cost map to get a binary image of "interesting" regions
    cost_threshold = np.percentile(cost_map, 90) # Look at the top 10% most complex regions
    _, binary_map = cv2.threshold(cost_map, cost_threshold, 255, cv2.THRESH_BINARY)
    binary_map = binary_map.astype(np.uint8)

    contours, _ = cv2.findContours(binary_map, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    detected_logos = []
    min_area = (h * w) * 0.001 # Logo must be at least 0.1% of the image area
    max_area = (h * w) * 0.15   # Logo must be less than 15% of the image area

    for cnt in contours:
        area = cv2.contourArea(cnt)
        if min_area < area < max_area:
            x, y, w, h = cv2.boundingRect(cnt)
            aspect_ratio = w / float(h)
            
            # Filter out shapes that are too long or too tall
            if 0.2 < aspect_ratio < 5.0:
                 # Calculate solidity: area of contour / area of its convex hull
                 # Logos are often solid shapes
                hull = cv2.convexHull(cnt)
                hull_area = cv2.contourArea(hull)
                if hull_area > 0:
                    solidity = float(area) / hull_area
                    if solidity > 0.4:
                        detected_logos.append({'box': (x, y, w, h), 'solidity': solidity})
    
    return detected_logos

def create_aesthetic_map(h, w, gray_img, logos):
    """
    Generates a map where pixel values represent aesthetic desirability.
    If logos are detected, it strongly prefers areas above and below them.
    Otherwise, it falls back to compositional rules.
    It always prefers darker areas.
    """
    y_coords, x_coords = np.mgrid[0:h, 0:w]
    norm_y, norm_x = y_coords / h, x_coords / w

    aesthetic_map = np.full((h, w), 0.5, dtype=np.float32)

    # --- Penalize edges ---
    edge_threshold = 0.10
    x_edge_penalty = np.minimum(norm_x / edge_threshold, (1 - norm_x) / edge_threshold)
    y_edge_penalty = np.minimum(norm_y / edge_threshold, (1 - norm_y) / edge_threshold)
    aesthetic_map *= np.clip(np.minimum(x_edge_penalty, y_edge_penalty), 0, 1)

    # --- Penalize bottom area ---
    aesthetic_map *= (1.0 - np.clip((norm_y - 0.7) / 0.3, 0, 1) * 0.8)

    # --- Apply composition rules based on logo detection ---
    if logos:
        # If logos are found, create bonus zones above and below them
        logo_bonus_map = np.zeros_like(aesthetic_map)
        for logo in logos:
            lx, ly, lw, lh = logo['box']
            center_x, center_y = lx + lw / 2, ly + lh / 2

            # Define areas above and below the logo
            # We create a gaussian bonus centered vertically above/below the logo
            # The vertical distance is proportional to the logo height
            above_y = center_y - lh * 1.2
            below_y = center_y + lh * 1.2
            
            # Use logo width as the standard deviation for the gaussian falloff
            sigma_x = lw * 1.5 
            sigma_y = lh * 0.8

            # Create Gaussian bonus for the area above
            dist_sq_above = (x_coords - center_x)**2 / (2 * sigma_x**2) + (y_coords - above_y)**2 / (2 * sigma_y**2)
            bonus_above = np.exp(-dist_sq_above)
            
            # Create Gaussian bonus for the area below
            dist_sq_below = (x_coords - center_x)**2 / (2 * sigma_x**2) + (y_coords - below_y)**2 / (2 * sigma_y**2)
            bonus_below = np.exp(-dist_sq_below)

            logo_bonus_map += bonus_above + bonus_below
            
        aesthetic_map += logo_bonus_map * 2.0 # Apply a strong bonus
    else:
        # Fallback to general composition rules if no logos are found
        thirds_x = np.minimum(abs(norm_x - 1/3), abs(norm_x - 2/3))
        thirds_y = np.minimum(abs(norm_y - 1/3), abs(norm_y - 2/3))
        thirds_bonus = 0.3 * (1 - np.hypot(thirds_x, thirds_y) * 2)
        
        gr = 0.618
        golden_x = np.minimum(abs(norm_x - (1-gr)), abs(norm_x - gr))
        golden_y = np.minimum(abs(norm_y - (1-gr)), abs(norm_y - gr))
        golden_bonus = 0.5 * (1 - np.hypot(golden_x, golden_y) * 2)
        
        aesthetic_map += np.clip(thirds_bonus + golden_bonus, 0, 1)

    # --- Add strong preference for darker areas ---
    # Invert the grayscale image so dark areas have high values.
    # The power (1.5) makes the preference non-linear and stronger.
    darkness_bonus = (1.0 - (gray_img.astype(np.float32) / 255.0))**1.5
    aesthetic_map *= darkness_bonus

    # --- Final normalization ---
    if aesthetic_map.max() > 0:
        aesthetic_map /= aesthetic_map.max()

    return aesthetic_map

def create_cost_map(img):
    """
    Analyzes the image to create a 'cost map' where high values
    indicate visually complex areas to be avoided. This version is more
    aggressive against structured complexity but tolerates uniform noise.
    """
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY).astype(np.float32)
    
    # --- 1. Sharp, Structured Edges (High Penalty) ---
    canny_edges = cv2.Canny(img, 60, 180, L2gradient=True)

    # --- 2. Structured Color Complexity (High Penalty) ---
    lab_img = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
    lab_planes = cv2.split(lab_img)
    color_complexity = np.zeros_like(gray, dtype=np.float32)
    for plane in lab_planes:
        plane_sobel_x = cv2.Sobel(plane, cv2.CV_32F, 1, 0, ksize=5)
        plane_sobel_y = cv2.Sobel(plane, cv2.CV_32F, 0, 1, ksize=5)
        color_complexity += np.hypot(plane_sobel_x, plane_sobel_y)
    
    if color_complexity.max() > 0:
      color_complexity = (color_complexity / color_complexity.max() * 255)

    # --- 3. Texture Uniformity Analysis (Moderate Penalty) ---
    sobel_x = cv2.Sobel(gray, cv2.CV_32F, 1, 0, ksize=3)
    sobel_y = cv2.Sobel(gray, cv2.CV_32F, 0, 1, ksize=3)
    sobel_mag = np.hypot(sobel_x, sobel_y)

    ksize = 15
    mean_of_mag = cv2.boxFilter(sobel_mag, -1, (ksize, ksize))
    mean_of_sq_mag = cv2.boxFilter(sobel_mag**2, -1, (ksize, ksize))
    local_variance = np.sqrt(np.maximum(0, mean_of_sq_mag - mean_of_mag**2))

    if local_variance.max() > 0:
      texture_variance_cost = (local_variance / local_variance.max() * 255)
    else:
      texture_variance_cost = np.zeros_like(gray)

    # --- 4. Combine the maps with new weights ---
    combined_cost = cv2.addWeighted(canny_edges.astype(np.float32), 0.5, color_complexity, 0.4, 0)
    combined_cost = cv2.addWeighted(combined_cost, 1.0, texture_variance_cost, 0.3, 0)

    # --- 5. Post-processing to create "keep-out" zones ---
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (9, 9))
    dilated_cost = cv2.dilate(combined_cost, kernel, iterations=2)
    blurred_cost = cv2.GaussianBlur(dilated_cost, (25, 25), 0)

    return blurred_cost.astype(np.float32)

def analyze_final_properties(img, center_x, center_y, clock_width=280, clock_height=120):
    """
    Analyzes brightness and color uniformity at the final chosen clock position.
    This combines the logic of the two original analysis functions.
    """
    h, w = img.shape[:2]
    x1 = max(0, center_x - clock_width // 2)
    y1 = max(0, center_y - clock_height // 2)
    x2 = min(w, center_x + clock_width // 2)
    y2 = min(h, center_y + clock_height // 2)

    clock_region = img[y1:y2, x1:x2]
    if clock_region.size == 0:
        return {
            'background_analysis': {'average_brightness': 0.5}, 
            'color_uniformity': {'color_variance': 1.0, 'has_color_transitions': True}
        }

    # Brightness Analysis
    gray_region = cv2.cvtColor(clock_region, cv2.COLOR_BGR2GRAY)
    avg_brightness = np.mean(gray_region) / 255.0
    brightness_std = np.std(gray_region) / 255.0
    
    background_analysis = {
        'average_brightness': avg_brightness,
        'brightness_std': brightness_std,
        'is_bright_background': avg_brightness > 0.6,
        'is_dark_background': avg_brightness < 0.4,
        'is_uniform': brightness_std < 0.1
    }

    # Uniformity Analysis
    lab_region = cv2.cvtColor(clock_region, cv2.COLOR_BGR2LAB)
    l_std, a_std, b_std = np.std(lab_region[:,:,0]), np.std(lab_region[:,:,1]), np.std(lab_region[:,:,2])
    color_variance = np.mean([l_std / 100.0, a_std / 128.0, b_std / 128.0])
    
    has_color_transitions = color_variance > 0.15

    color_uniformity = {
        'color_variance': color_variance,
        'has_color_transitions': has_color_transitions,
        'uniformity_score': max(0.0, 1.0 - color_variance * 3)
    }
    
    return background_analysis, color_uniformity

def find_empty_areas(image_path):
    """
    Finds the best position for a widget using distance transform and aesthetic
    scoring, but formats the output to match the original script's structure.
    """
    img = cv2.imread(image_path)
    if img is None:
        raise ValueError(f"Image could not be loaded from: {image_path}")

    original_h, original_w = img.shape[:2]
    
    scale = 800 / max(original_h, original_w)
    small_img = cv2.resize(img, (0, 0), fx=scale, fy=scale, interpolation=cv2.INTER_AREA)
    h, w = small_img.shape[:2]

    cost_map = create_cost_map(small_img)
    
    cost_threshold = np.percentile(cost_map, 75)
    _, permissible_map = cv2.threshold(cost_map, cost_threshold, 255, cv2.THRESH_BINARY_INV)
    permissible_map = permissible_map.astype(np.uint8)

    complexity_score, complexity_details = analyze_image_complexity(cost_map, permissible_map)

    dist_map = cv2.distanceTransform(permissible_map, cv2.DIST_L2, cv2.DIST_MASK_5)
    
    # Create grayscale version for aesthetic analysis
    gray_small_img = cv2.cvtColor(small_img, cv2.COLOR_BGR2GRAY)

    # ** NEW: Detect potential logos from the cost map **
    logos = detect_potential_logos(cost_map, h, w)
    
    # Pass grayscale image and logos to the aesthetic map function
    aesthetic_map = create_aesthetic_map(h, w, gray_small_img, logos)

    if dist_map.max() > 0:
        dist_map_norm = dist_map / dist_map.max()
    else:
        dist_map_norm = dist_map

    final_score_map = (dist_map_norm**2) * aesthetic_map

    _, _, _, max_loc = cv2.minMaxLoc(final_score_map)
    center_x, center_y = max_loc

    radius = dist_map[center_y, center_x]
    square_size = int(radius * 2 / np.sqrt(2))

    final_center_x = int(center_x / scale)
    final_center_y = int(center_y / scale)
    final_square_size = int(square_size / scale)

    # Convert detected logo boxes back to original image coordinates
    final_logos = []
    for logo in logos:
        x, y, lw, lh = logo['box']
        final_logos.append({
            'box': (int(x/scale), int(y/scale), int(lw/scale), int(lh/scale)),
            'solidity': logo['solidity']
        })

    min_size = min(original_h, original_w) // 20
    if final_square_size < min_size:
        final_square_size = min_size

    background_analysis, color_uniformity = analyze_final_properties(img, final_center_x, final_center_y)

    final_complexity_score = cost_map[center_y, center_x] / 255.0
    color_uniformity['complexity_score'] = final_complexity_score

    half_size = final_square_size // 2
    x1 = max(0, final_center_x - half_size)
    y1 = max(0, final_center_y - half_size)
    x2 = min(original_w, final_center_x + half_size)
    y2 = min(original_h, final_center_y + half_size)

    return {
        'center': (final_center_x, final_center_y),
        'square_size': final_square_size,
        'coordinates': (x1, y1, x2, y2),
        'detected_logos': final_logos, # New field in the output
        'complexity_score': complexity_score,
        'complexity_details': complexity_details,
        'background_analysis': background_analysis,
        'color_uniformity': color_uniformity,
        'complexity_avoidance': {
            'enabled': True,
            'global_stats': {
                'safe_area_ratio': complexity_details['clean_area_ratio'],
                'average_complexity': complexity_details['edge_density']
            },
            'final_complexity_score': final_complexity_score
        }
    }

def convert_numpy_types(obj):
    """
    Recursively converts numpy types in a dictionary to native Python types
    for JSON serialization.
    """
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

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <path_to_image>")
        sys.exit(1)

    image_path = sys.argv[1]

    if not os.path.exists(image_path):
        print(f"Error: File not found at '{image_path}'")
        sys.exit(1)

    try:
        print(f"Analyzing '{image_path}'...")
        result = find_empty_areas(image_path)
        
        json_result = convert_numpy_types(result)

        print("\n--- RESULT ---")
        for key, value in json_result.items():
            if key == 'detected_logos' and value:
                print(f"detected_logos:")
                for i, logo in enumerate(value):
                    print(f"  - Logo {i+1}: {logo}")
            else:
                print(f"{key}: {value}")
        
        print("\n--- JSON ---")
        print(json.dumps(json_result, indent=2))

    except Exception as e:
        print(f"\nAn error occurred: {e}")
        print("Please ensure OpenCV is installed (`pip install opencv-python numpy`)")
        sys.exit(1)
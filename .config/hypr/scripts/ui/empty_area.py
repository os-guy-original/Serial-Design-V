#!/usr/bin/env python3
"""
Widget Area Finder - Finds the best area for widget placement on an image.
This version introduces a hard margin constraint, ensuring the widget is never placed
too close to the screen edges or corners. The scoring is a weighted product of
uniformity, position, saturation, and visual saliency.
"""

import cv2
import numpy as np
import subprocess
import sys
import argparse
from pathlib import Path

def get_screen_size():
    """
    Get screen size from Hyprland.
    Falls back to a default resolution if hyprctl fails.
    """
    try:
        # Get monitor info from hyprctl
        result = subprocess.run(['hyprctl', 'monitors', '-j'],
                              capture_output=True, text=True, check=True)
        
        import json
        monitors = json.loads(result.stdout)
        
        if not monitors:
            raise ValueError("No monitors found")
        
        # Use the first monitor (primary)
        monitor = monitors[0]
        width = monitor['width']
        height = monitor['height']
        
        return width, height
        
    except (subprocess.CalledProcessError, json.JSONDecodeError, KeyError) as e:
        print(f"Warning: Could not get screen size from hyprctl. Falling back to 1920x1080. Error: {e}", file=sys.stderr)
        return 1920, 1080

def resize_image_to_screen(image, screen_width, screen_height):
    """
    Resize and crop an image to match the screen's dimensions while
    maintaining the aspect ratio as much as possible.
    """
    img_height, img_width = image.shape[:2]
    
    # Calculate new height when width matches screen width
    aspect_ratio = img_height / img_width
    new_height = int(screen_width * aspect_ratio)
    
    # Resize image to match screen width
    resized = cv2.resize(image, (screen_width, new_height), interpolation=cv2.INTER_AREA)
    
    if new_height > screen_height:
        # Crop from top and bottom to fit screen height
        crop_amount = (new_height - screen_height) // 2
        final_image = resized[crop_amount:crop_amount + screen_height, :]
    elif new_height < screen_height:
        # Scale up to match screen height using a different interpolation
        final_image = cv2.resize(resized, (screen_width, screen_height), interpolation=cv2.INTER_CUBIC)
    else:
        final_image = resized
    
    return final_image

def calculate_uniformity_score(region):
    """
    Calculate a uniformity score for a given image region.
    A higher score indicates a more uniform area with fewer details.
    This score is normalized to be between 0 and 1.
    """
    if region.size == 0:
        return 0
    
    region_float = region.astype(np.float32)
    
    color_variance = np.var(region_float)
    
    if len(region.shape) == 3:
        gray_region = cv2.cvtColor(region, cv2.COLOR_BGR2GRAY)
    else:
        gray_region = region
    
    grad_x = cv2.Scharr(gray_region, cv2.CV_64F, 1, 0)
    grad_y = cv2.Scharr(gray_region, cv2.CV_64F, 0, 1)
    gradient_magnitude = np.sqrt(grad_x**2 + grad_y**2)
    edge_density = np.mean(gradient_magnitude)
    
    # Normalize metrics to a 0-1 range
    normalized_variance = color_variance / (255**2 * 3)
    normalized_edge_density = edge_density / 255
    
    uniformity_score = 1.0 / (1.0 + normalized_variance + normalized_edge_density)
    
    return uniformity_score

def calculate_saturation_score(region):
    """
    Calculate a color saturation score for a given image region.
    A higher score indicates a more desaturated (muted) area, which is
    often better for placing widgets. The score is normalized to be between 0 and 1.
    """
    if region.size == 0:
        return 0
    
    # Convert BGR to HSV color space to get saturation channel
    hsv_region = cv2.cvtColor(region, cv2.COLOR_BGR2HSV)
    saturation = hsv_region[:, :, 1]
    
    mean_saturation = np.mean(saturation)
    
    # Invert the score so that a higher value is better (more muted)
    saturation_score = 1.0 - (mean_saturation / 255.0)
    
    return saturation_score

def calculate_saliency_score(region):
    """
    Calculate a visual saliency score for a given image region.
    This method uses a simple but effective technique based on local
    contrast. A higher score indicates a more salient (visually interesting) area.
    This score is inverted to find areas of low visual interest.
    """
    if region.size == 0:
        return 0
    
    # Convert to grayscale
    if len(region.shape) == 3:
        gray_region = cv2.cvtColor(region, cv2.COLOR_BGR2GRAY)
    else:
        gray_region = region
    
    # Calculate a simple saliency map using difference of Gaussians
    small_blur = cv2.GaussianBlur(gray_region, (5, 5), 0)
    large_blur = cv2.GaussianBlur(gray_region, (21, 21), 0)
    
    saliency_map = cv2.absdiff(small_blur, large_blur)
    
    # Normalize saliency map and calculate mean saliency
    saliency_score = np.mean(saliency_map) / 255.0
    
    # Invert the score so that higher value is better (less salient)
    return 1.0 - saliency_score

def find_best_widget_area(image, widget_width, widget_height, margin, step_size=20, downscale_factor=4,
                          uniformity_weight=0.5, position_weight=0.2, saturation_weight=0.3, saliency_weight=0.0):
    """
    Find the best area for widget placement using a multi-resolution approach
    and a configurable weighted scoring system.
    
    Args:
        image (np.array): The full-resolution image.
        widget_width (int): The width of the widget.
        widget_height (int): The height of the widget.
        margin (int): A minimum distance from the screen edges.
        step_size (int): The step size for the search grid.
        downscale_factor (int): The factor to downscale the image for the coarse search.
        uniformity_weight (float): The weight for the uniformity score.
        position_weight (float): The weight for the position score.
        saturation_weight (float): The weight for the saturation score.
        saliency_weight (float): The weight for the saliency score.
    
    Returns:
        tuple: A tuple containing the best position (x, y) and the final combined score.
    """
    img_height, img_width = image.shape[:2]

    # --- Phase 1: Coarse search on downscaled image ---
    small_width = img_width // downscale_factor
    small_height = img_height // downscale_factor
    small_widget_width = max(1, widget_width // downscale_factor)
    small_widget_height = max(1, widget_height // downscale_factor)
    small_margin = max(1, margin // downscale_factor)
    
    small_image = cv2.resize(image, (small_width, small_height), interpolation=cv2.INTER_AREA)
    
    best_coarse_score = -1.0
    best_coarse_position = (small_margin, small_margin)
    
    coarse_step = max(1, step_size // downscale_factor)
    
    # Search within the defined margins
    search_x_range = range(small_margin, small_width - small_widget_width - small_margin + 1, coarse_step)
    search_y_range = range(small_margin, small_height - small_widget_height - small_margin + 1, coarse_step)
    
    if not search_x_range or not search_y_range:
        print("Error: Widget size or margin too large for the image. Please reduce widget size or margin.", file=sys.stderr)
        return (-1, -1), -1.0

    for y in search_y_range:
        for x in search_x_range:
            region = small_image[y:y + small_widget_height, x:x + small_widget_width]
            uniformity_score = calculate_uniformity_score(region)
            
            # Use only uniformity for the coarse search to keep it fast
            if uniformity_score > best_coarse_score:
                best_coarse_score = uniformity_score
                best_coarse_position = (x, y)

    # --- Phase 2: Fine search around best coarse position on full resolution ---
    coarse_x, coarse_y = best_coarse_position
    full_res_x = coarse_x * downscale_factor
    full_res_y = coarse_y * downscale_factor
    
    search_radius = downscale_factor * 2
    
    # Fine search bounds with margin
    min_x = max(margin, full_res_x - search_radius)
    max_x = min(img_width - widget_width - margin, full_res_x + search_radius)
    min_y = max(margin, full_res_y - search_radius)
    max_y = min(img_height - widget_height - margin, full_res_y + search_radius)
        
    best_fine_score = -1.0
    best_fine_position = (full_res_x, full_res_y)
    
    fine_step = max(1, step_size // 2)
    
    for y in range(min_y, max_y + 1, fine_step):
        for x in range(min_x, max_x + 1, fine_step):
            region = image[y:y + widget_height, x:x + widget_width]
            
            # Calculate all four scores
            uniformity_score = calculate_uniformity_score(region)
            saturation_score = calculate_saturation_score(region)
            saliency_score = calculate_saliency_score(region)
            
            # Position score encourages placement away from the center
            center_x = img_width / 2
            center_y = img_height / 2
            dist_x = abs(x + widget_width / 2 - center_x)
            dist_y = abs(y + widget_height / 2 - center_y)
            normalized_dist_x = dist_x / (img_width / 2)
            normalized_dist_y = dist_y / (img_height / 2)
            position_score = (normalized_dist_x + normalized_dist_y) / 2
            
            # Combine scores with user-defined weighting using a product
            combined_score = (uniformity_score ** uniformity_weight) * \
                             (saturation_score ** saturation_weight) * \
                             (saliency_score ** saliency_weight) * \
                             (position_score ** position_weight)

            if combined_score > best_fine_score:
                best_fine_score = combined_score
                best_fine_position = (x, y)
    
    return best_fine_position, best_fine_score

def main():
    parser = argparse.ArgumentParser(description="Find best widget placement area on an image")
    parser.add_argument("input_image", help="Path to input image")
    parser.add_argument("widget_width", type=int, help="Widget width in pixels")
    parser.add_argument("widget_height", type=int, help="Widget height in pixels")
    parser.add_argument("-m", "--margin", type=int, default=50,
                       help="Minimum distance from screen edges in pixels (default: 50)")
    parser.add_argument("-s", "--step", type=int, default=20, 
                       help="Step size for search grid (default: 20)")
    parser.add_argument("-d", "--downscale", type=int, default=4,
                       help="Downscale factor for initial search (default: 4)")
    parser.add_argument("-q", "--quiet", action="store_true",
                       help="Only output final result")
    parser.add_argument("--uniformity-weight", type=float, default=0.5,
                       help="Weight for uniformity score (default: 0.5)")
    parser.add_argument("--position-weight", type=float, default=0.2,
                       help="Weight for position score (default: 0.2)")
    parser.add_argument("--saturation-weight", type=float, default=0.3,
                       help="Weight for color saturation score (default: 0.3)")
    parser.add_argument("--saliency-weight", type=float, default=0.0,
                       help="Weight for saliency score (default: 0.0). Higher weight favors less visually prominent areas.")
    
    args = parser.parse_args()

    # Validate weights
    total_weight = args.uniformity_weight + args.position_weight + args.saturation_weight + args.saliency_weight
    if not 0.99 <= total_weight <= 1.01:
        print(f"Error: The sum of weights must be approximately 1.0 (currently {total_weight:.2f})", file=sys.stderr)
        sys.exit(1)
    
    # Validate input file
    input_path = Path(args.input_image)
    if not input_path.exists():
        if not args.quiet:
            print(f"Error: Input image '{args.input_image}' not found", file=sys.stderr)
        sys.exit(1)
    
    # Load image
    image = cv2.imread(str(input_path))
    if image is None:
        if not args.quiet:
            print(f"Error: Could not load image '{args.input_image}'", file=sys.stderr)
        sys.exit(1)
    
    # Get screen size
    screen_width, screen_height = get_screen_size()
    
    # Resize image to screen dimensions
    processed_image = resize_image_to_screen(image, screen_width, screen_height)
    
    # Validate widget size
    if args.widget_width + 2 * args.margin > screen_width or args.widget_height + 2 * args.margin > screen_height:
        if not args.quiet:
            print(f"Error: Widget size ({args.widget_width}x{args.widget_height}) with margin ({args.margin}) "
                  f"is larger than screen size ({screen_width}x{screen_height}). Please reduce widget size or margin.", file=sys.stderr)
        sys.exit(1)
    
    # Find best widget area with configurable weights and a hard margin
    best_position, score = find_best_widget_area(
        processed_image, args.widget_width, args.widget_height, args.margin,
        args.step, args.downscale,
        args.uniformity_weight, args.position_weight, args.saturation_weight, args.saliency_weight
    )

    if best_position == (-1, -1):
        if not args.quiet:
            print("Could not find a suitable area with the given constraints.", file=sys.stderr)
        sys.exit(1)
    
    # Calculate center position
    x, y = best_position
    center_x = x + args.widget_width // 2
    center_y = y + args.widget_height // 2
    
    # Output format: x y center_x center_y width height score
    print(f"{x} {y} {center_x} {center_y} {args.widget_width} {args.widget_height} {score:.6f}")

if __name__ == "__main__":
    main()

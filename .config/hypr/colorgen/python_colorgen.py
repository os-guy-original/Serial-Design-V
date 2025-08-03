#!/usr/bin/env python3

"""
Python Color Generation System for Material You
Replaces shell-based color processing with better gray and purple detection
"""

import sys
import json
import os
import subprocess
import colorsys
from PIL import Image
import numpy as np
from pathlib import Path
import argparse

class MaterialYouColorGen:
    def __init__(self, wallpaper_path, colorgen_dir):
        self.wallpaper_path = wallpaper_path
        self.colorgen_dir = Path(colorgen_dir)
        self.colors_json = self.colorgen_dir / "colors.json"
        self.colors_conf = self.colorgen_dir / "colors.conf"
        self.colors_css = self.colorgen_dir / "colors.css"
        
    def hex_to_rgb(self, hex_color):
        """Convert hex color to RGB tuple"""
        hex_color = hex_color.lstrip('#')
        return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))
    
    def rgb_to_hex(self, r, g, b):
        """Convert RGB values to hex string"""
        return f"#{int(r):02x}{int(g):02x}{int(b):02x}"
    
    def rgb_to_hsl(self, r, g, b):
        """Convert RGB to HSL"""
        return colorsys.rgb_to_hls(r/255.0, g/255.0, b/255.0)
    
    def hsl_to_rgb(self, h, s, l):
        """Convert HSL to RGB"""
        r, g, b = colorsys.hls_to_rgb(h, l, s)
        return int(r * 255), int(g * 255), int(b * 255)
    
    def is_gray_dominant(self, image_path, threshold=0.35):
        """Check if image is gray-dominant with improved detection"""
        try:
            img = Image.open(image_path).convert('RGB')
            img.thumbnail((200, 200))  # Resize for performance
            
            pixels = np.array(img).reshape(-1, 3)
            gray_count = 0
            total_samples = 0
            
            for pixel in pixels[::8]:  # Sample every 8th pixel for better coverage
                r, g, b = pixel
                total_samples += 1
                
                # Improved gray detection: check if all RGB components are similar
                rg_diff = abs(r - g)
                gb_diff = abs(g - b)
                rb_diff = abs(r - b)
                max_diff = max(rg_diff, gb_diff, rb_diff)
                
                # Consider it gray if the maximum difference is small
                if max_diff < 25:  # Slightly more lenient threshold
                    gray_count += 1
            
            gray_ratio = gray_count / total_samples if total_samples > 0 else 0
            print(f"Gray analysis: {gray_count}/{total_samples} pixels are gray-like (ratio: {gray_ratio:.2f})", file=sys.stderr)
            return gray_ratio > threshold
            
        except Exception as e:
            print(f"Error analyzing image: {e}", file=sys.stderr)
            return False
    
    def enhance_gray_colors(self, colors_data):
        """Enhance gray color detection and prevent blue tinting"""
        if not self.is_gray_dominant(self.wallpaper_path):
            return colors_data
        
        print("Gray-dominant image detected, enhancing colors...", file=sys.stderr)
        
        dark_colors = colors_data.get('colors', {}).get('dark', {})
        primary_hex = dark_colors.get('primary', '#000000')
        
        r, g, b = self.hex_to_rgb(primary_hex)
        h, s, l = self.rgb_to_hsl(r, g, b)
        
        print(f"Primary color analysis: {primary_hex} -> HSL({h:.2f}, {s:.2f}, {l:.2f})", file=sys.stderr)
        
        # Check if primary is blue-tinted (more precise range)
        blue_hue_range = (210/360, 250/360)  # Narrower blue range
        if blue_hue_range[0] <= h <= blue_hue_range[1] and s > 0.15:
            print(f"Neutralizing blue-tinted primary: {primary_hex} (hue: {h:.2f}, saturation: {s:.2f})", file=sys.stderr)
            
            # Create neutral warm gray with slight warmth
            base_lightness = l * 255
            warm_r = min(255, int(base_lightness * 1.03))  # Slightly warmer
            warm_g = int(base_lightness)
            warm_b = max(0, int(base_lightness * 0.97))    # Slightly cooler
            warm_gray = self.rgb_to_hex(warm_r, warm_g, warm_b)
            
            dark_colors['primary'] = warm_gray
            
            # Update related colors consistently
            if 'primary_container' in dark_colors:
                container_l = max(0.1, l * 0.4)
                container_base = container_l * 255
                dark_colors['primary_container'] = self.rgb_to_hex(
                    min(255, int(container_base * 1.03)),
                    int(container_base),
                    max(0, int(container_base * 0.97))
                )
            
            print(f"Enhanced primary: {primary_hex} -> {warm_gray}", file=sys.stderr)
        else:
            print(f"Primary color is acceptable: {primary_hex} (hue: {h:.2f}, saturation: {s:.2f})", file=sys.stderr)
        
        return colors_data
    
    def run_matugen(self):
        """Run matugen to generate base colors"""
        try:
            cmd = [
                'matugen', '--mode', 'dark', '-t', 'scheme-tonal-spot', 
                '--json', 'hex', 'image', self.wallpaper_path
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode != 0:
                print(f"Matugen failed: {result.stderr}", file=sys.stderr)
                return None
            
            return json.loads(result.stdout)
            
        except Exception as e:
            print(f"Error running matugen: {e}", file=sys.stderr)
            return None
    
    def hex_to_rgba(self, hex_color, alpha=1.0):
        """Convert hex to rgba format for Hyprland"""
        r, g, b = self.hex_to_rgb(hex_color)
        return f"rgba({r:02x}{g:02x}{b:02x}{int(alpha*255):02x})"
    
    def generate_colors_conf(self, colors_data):
        """Generate colors.conf file"""
        dark_colors = colors_data.get('colors', {}).get('dark', {})
        
        primary = dark_colors.get('primary', '#6750a4')
        secondary = dark_colors.get('secondary', '#625b71')
        tertiary = dark_colors.get('tertiary', '#7d5260')
        
        # Create tonal palette
        surface = dark_colors.get('surface', '#141218')
        surface_bright = dark_colors.get('surface_bright', '#3b383e')
        surface_container = dark_colors.get('surface_container', '#211f26')
        surface_container_high = dark_colors.get('surface_container_high', '#2b2930')
        surface_container_highest = dark_colors.get('surface_container_highest', '#36343b')
        surface_container_low = dark_colors.get('surface_container_low', '#1d1b20')
        surface_container_lowest = dark_colors.get('surface_container_lowest', '#0f0d13')
        
        on_primary = dark_colors.get('on_primary', '#381e72')
        on_primary_container = dark_colors.get('on_primary_container', '#eaddff')
        on_surface = dark_colors.get('on_surface', '#e6e0e9')
        
        # Get accent colors
        primary_container = dark_colors.get('primary_container', '#4f378b')
        accent_dark = primary_container
        accent_light = on_surface
        
        conf_content = f"""# Material You color scheme from {self.wallpaper_path}
# Generated on {subprocess.run(['date', '+%Y-%m-%d'], capture_output=True, text=True).stdout.strip()}
# Using Python Material You color generation

primary = {primary}

# Tonal palette
primary-0 = {surface_container_lowest}
primary-10 = {surface_container_low}
primary-20 = {surface_container}
primary-30 = {surface_container_high}
primary-40 = {surface_container_highest}
primary-50 = {surface}
primary-60 = {surface_bright}
primary-80 = {primary}
primary-90 = {on_primary_container}
primary-95 = {on_surface}
primary-99 = #ffffff
primary-100 = #ffffff

secondary = {secondary}
tertiary = {tertiary}

accent = {primary}
accent_dark = {accent_dark}
accent_light = {accent_light}

# Legacy color mapping
color0 = {surface_container_lowest}
color1 = {surface_container_low}
color2 = {surface_container}
color3 = {surface_container_high}
color4 = {primary_container}
color5 = {primary}
color6 = {on_primary_container}
color7 = {on_surface}
"""
        
        with open(self.colors_conf, 'w') as f:
            f.write(conf_content)
    
    def generate_colors_css(self, colors_data):
        """Generate colors.css file"""
        dark_colors = colors_data.get('colors', {}).get('dark', {})
        
        css_content = f"""/* Material You color scheme from {self.wallpaper_path} */
/* Generated on {subprocess.run(['date', '+%Y-%m-%d'], capture_output=True, text=True).stdout.strip()} */
/* Using Python Material You color generation */

:root {{
"""
        
        # Add all dark colors as CSS variables
        for key, value in dark_colors.items():
            css_content += f"  --{key.replace('_', '-')}: {value};\n"
        
        # Add standard variables
        primary = dark_colors.get('primary', '#6750a4')
        primary_container = dark_colors.get('primary_container', '#4f378b')
        on_surface = dark_colors.get('on_surface', '#e6e0e9')
        
        css_content += f"""
  /* Standard CSS variables */
  --accent: {primary};
  --accent-dark: {primary_container};
  --accent-light: {on_surface};
  
  /* Legacy color variables */
  --color0: {dark_colors.get('surface_container_lowest', '#000000')};
  --color1: {dark_colors.get('surface_container_low', '#1a1a1a')};
  --color2: {dark_colors.get('surface_container', '#303030')};
  --color3: {dark_colors.get('surface_container_high', '#505050')};
  --color4: {dark_colors.get('primary_container', '#707070')};
  --color5: {primary};
  --color6: {dark_colors.get('on_primary_container', '#b0b0b0')};
  --color7: {on_surface};
}}
"""
        
        with open(self.colors_css, 'w') as f:
            f.write(css_content)
    
    def generate_border_color(self, colors_data):
        """Generate border color for Hyprland"""
        dark_colors = colors_data.get('colors', {}).get('dark', {})
        light_colors = colors_data.get('colors', {}).get('light', {})
        
        # Try to get a light color for borders
        border_hex = dark_colors.get('on_surface', '#ffffff')
        
        # Check if it's light enough
        r, g, b = self.hex_to_rgb(border_hex)
        if max(r, g, b) < 192:  # If not light enough
            border_hex = light_colors.get('on_primary', '#ffffff')
        
        # Convert to rgba for Hyprland
        border_rgba = self.hex_to_rgba(border_hex)
        
        with open(self.colorgen_dir / "border_color.txt", 'w') as f:
            f.write(border_rgba)
        
        return border_hex, border_rgba
    
    def generate(self):
        """Main generation function"""
        print(f"Generating Material You colors for: {self.wallpaper_path}")
        
        # Run matugen
        colors_data = self.run_matugen()
        if not colors_data:
            print("Failed to generate colors with matugen", file=sys.stderr)
            return False
        
        # Enhance gray colors if needed
        colors_data = self.enhance_gray_colors(colors_data)
        
        # Save enhanced colors.json
        with open(self.colors_json, 'w') as f:
            json.dump(colors_data, f, indent=2)
        
        # Generate separate palette files
        with open(self.colorgen_dir / "dark_colors.json", 'w') as f:
            json.dump(colors_data.get('colors', {}).get('dark', {}), f, indent=2)
        
        with open(self.colorgen_dir / "light_colors.json", 'w') as f:
            json.dump(colors_data.get('colors', {}).get('light', {}), f, indent=2)
        
        # Generate config files
        self.generate_colors_conf(colors_data)
        self.generate_colors_css(colors_data)
        
        # Generate border color
        border_hex, border_rgba = self.generate_border_color(colors_data)
        
        print(f"Colors generated successfully!")
        print(f"Primary color: {colors_data.get('colors', {}).get('dark', {}).get('primary', 'N/A')}")
        print(f"Border color: {border_hex} ({border_rgba})")
        
        return True

def main():
    parser = argparse.ArgumentParser(description='Python Material You Color Generator')
    parser.add_argument('wallpaper', help='Path to wallpaper image')
    parser.add_argument('--colorgen-dir', default=os.path.expanduser('~/.config/hypr/colorgen'),
                       help='Colorgen directory path')
    parser.add_argument('--debug', action='store_true', help='Enable debug output')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.wallpaper):
        print(f"Error: Wallpaper file not found: {args.wallpaper}", file=sys.stderr)
        return 1
    
    # Create colorgen directory if it doesn't exist
    os.makedirs(args.colorgen_dir, exist_ok=True)
    
    # Generate colors
    colorgen = MaterialYouColorGen(args.wallpaper, args.colorgen_dir)
    
    if colorgen.generate():
        return 0
    else:
        return 1

if __name__ == "__main__":
    sys.exit(main())
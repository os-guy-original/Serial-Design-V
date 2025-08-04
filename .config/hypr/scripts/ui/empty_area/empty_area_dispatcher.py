#!/usr/bin/env python3

"""
Empty Area Dispatcher - Routes to the configured algorithm
"""

import os
import sys
import subprocess

def load_config():
    """Load configuration from config.conf"""
    config_path = os.path.join(os.path.dirname(__file__), "config.conf")
    config = {
        'ALGORITHM': 'ultra_fast',
        'ENABLE_COMPLEXITY_AVOIDANCE': True,
        'ENABLE_BACKGROUND_ANALYSIS': True,
        'ENABLE_POSITION_CACHING': False,
        'PREFER_UPPER_POSITIONS': True,
        'AVOID_CENTER_LOGO': True,
        'USE_RULE_OF_THIRDS': True,
        'ENABLE_DEBUG_OUTPUT': False,
        'SAVE_DEBUG_IMAGES': False
    }
    
    if os.path.exists(config_path):
        try:
            with open(config_path, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        key = key.strip()
                        value = value.strip()
                        
                        if value.lower() in ('true', 'false'):
                            config[key] = value.lower() == 'true'
                        else:
                            config[key] = value
        except Exception as e:
            print(f"Warning: Error reading config: {e}", file=sys.stderr)
    
    return config

def main():
    if len(sys.argv) != 2:
        print("Usage: python empty_area_dispatcher.py image_path")
        sys.exit(1)
    
    image_path = sys.argv[1]
    config = load_config()
    
    # Map algorithm names to script files
    algorithm_map = {
        'original': 'empty_area.py',
        'fast': 'empty_area_fast.py',
        'ultra_fast': 'empty_area_ultra_fast.py'
    }
    
    algorithm = config.get('ALGORITHM', 'ultra_fast')
    script_name = algorithm_map.get(algorithm, 'empty_area_ultra_fast.py')
    script_path = os.path.join(os.path.dirname(__file__), script_name)
    
    if not os.path.exists(script_path):
        print(f"Error: Algorithm script not found: {script_path}", file=sys.stderr)
        sys.exit(1)
    
    # Execute the selected algorithm
    try:
        result = subprocess.run([sys.executable, script_path, image_path], 
                              capture_output=False, text=True)
        sys.exit(result.returncode)
    except Exception as e:
        print(f"Error executing algorithm: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
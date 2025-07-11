#!/usr/bin/env python3

import subprocess
import sys
import argparse
import os
import signal

def set_volume(percentage):
    """Set the volume to the specified percentage."""
    if percentage < 0:
        percentage = 0
    elif percentage > 100:
        percentage = 100
    
    subprocess.run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{percentage}%"])
    print(f"Volume set to {percentage}%")

def increase_volume(step=5):
    """Increase volume by the specified step."""
    subprocess.run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"+{step}%"])
    print(f"Volume increased by {step}%")

def decrease_volume(step=5):
    """Decrease volume by the specified step."""
    subprocess.run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"-{step}%"])
    print(f"Volume decreased by {step}%")

def toggle_mute():
    """Toggle mute status."""
    subprocess.run(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"])
    print("Mute toggled")

def set_brightness(percentage):
    """Set the brightness to the specified percentage."""
    if percentage < 0:
        percentage = 0
    elif percentage > 100:
        percentage = 100
    
    subprocess.run(["brightnessctl", "set", f"{percentage}%"])
    print(f"Brightness set to {percentage}%")

def increase_brightness(step=5):
    """Increase brightness by the specified step."""
    subprocess.run(["brightnessctl", "set", f"{step}%+"])
    print(f"Brightness increased by {step}%")

def decrease_brightness(step=5):
    """Decrease brightness by the specified step."""
    subprocess.run(["brightnessctl", "set", f"{step}%-"])
    print(f"Brightness decreased by {step}%")

def start_osd_manager():
    """Start the OSD manager service."""
    # Get the path to osd_manager.py
    script_dir = os.path.dirname(os.path.abspath(__file__))
    manager_script = os.path.join(script_dir, "osd_manager.py")
    
    # Check if manager is already running
    lock_file = "/tmp/osd-manager.lock"
    if os.path.exists(lock_file):
        try:
            with open(lock_file, 'r') as f:
                pid = int(f.read().strip())
            
            # Check if process is running
            os.kill(pid, 0)
            print("OSD Manager is already running")
            return
        except (OSError, ValueError):
            # Process not running or invalid PID
            # Remove stale lock file
            try:
                os.remove(lock_file)
            except OSError:
                pass
    
    # Start the manager process
    subprocess.Popen([sys.executable, manager_script])
    print("OSD Manager started")

def stop_osd_manager():
    """Stop the OSD manager service."""
    lock_file = "/tmp/osd-manager.lock"
    manager_stopped = False
    
    # First try using the lock file
    if os.path.exists(lock_file):
        try:
            # Read PID from lock file
            with open(lock_file, 'r') as f:
                pid = int(f.read().strip())
            
            # Send SIGTERM to the process
            os.kill(pid, signal.SIGTERM)
            print(f"Stopped OSD Manager with PID {pid}")
            manager_stopped = True
            
            # Remove lock file
            try:
                os.remove(lock_file)
            except OSError:
                pass
        except (OSError, ValueError) as e:
            print(f"Error stopping OSD Manager via lock file: {e}")
            # Remove stale lock file
            try:
                os.remove(lock_file)
            except OSError:
                pass
    
    # If lock file approach failed, try finding the process by name
    if not manager_stopped:
        try:
            # Find processes with osd_manager.py in the command
            result = subprocess.run(
                ["pgrep", "-f", "osd_manager.py"],
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0 and result.stdout.strip():
                pids = result.stdout.strip().split('\n')
                for pid_str in pids:
                    try:
                        pid = int(pid_str)
                        os.kill(pid, signal.SIGTERM)
                        print(f"Stopped OSD Manager with PID {pid}")
                        manager_stopped = True
                    except (OSError, ValueError) as e:
                        print(f"Error stopping OSD Manager process {pid_str}: {e}")
            
            if not manager_stopped:
                print("No running OSD Manager found")
        except Exception as e:
            print(f"Error searching for OSD Manager processes: {e}")
            if not manager_stopped:
                print("No running OSD Manager found")
    
    # Also make sure to clean up any stale container lock file
    container_lock_file = "/tmp/osd-container.lock"
    if os.path.exists(container_lock_file):
        try:
            with open(container_lock_file, 'r') as f:
                pid = int(f.read().strip())
            
            # Try to terminate the process
            try:
                os.kill(pid, signal.SIGTERM)
                print(f"Stopped OSD Container with PID {pid}")
            except OSError:
                pass
                
            # Remove the lock file
            try:
                os.remove(container_lock_file)
            except OSError:
                pass
        except (OSError, ValueError):
            # Remove stale lock file
            try:
                os.remove(container_lock_file)
            except OSError:
                pass

def reload_theme():
    """Send a signal to the OSD to reload its theme."""
    # Check for lock file
    lock_file = "/tmp/osd-container.lock"
    
    if os.path.exists(lock_file):
        try:
            # Read PID from lock file
            with open(lock_file, 'r') as f:
                pid = int(f.read().strip())
            
            # Send SIGUSR1 to the process to trigger theme reload
            os.kill(pid, signal.SIGUSR1)
            print(f"Sent theme reload signal to OSD process with PID {pid}")
            return True
        except (OSError, ValueError) as e:
            print(f"Error sending reload signal: {e}")
            # Remove stale lock file
            try:
                os.remove(lock_file)
            except OSError:
                pass
    
    print("No running OSD process found")
    return False

def main():
    parser = argparse.ArgumentParser(description='Control OSD for volume and brightness')
    subparsers = parser.add_subparsers(dest='command', help='Command to execute')
    
    # Volume commands
    volume_parser = subparsers.add_parser('volume', help='Volume control commands')
    volume_subparsers = volume_parser.add_subparsers(dest='volume_command', help='Volume command')
    
    set_vol_parser = volume_subparsers.add_parser('set', help='Set volume to a specific percentage')
    set_vol_parser.add_argument('value', type=int, help='Volume percentage (0-100)')
    
    up_vol_parser = volume_subparsers.add_parser('up', help='Increase volume')
    up_vol_parser.add_argument('step', type=int, nargs='?', default=5, help='Step percentage (default: 5)')
    
    down_vol_parser = volume_subparsers.add_parser('down', help='Decrease volume')
    down_vol_parser.add_argument('step', type=int, nargs='?', default=5, help='Step percentage (default: 5)')
    
    volume_subparsers.add_parser('mute', help='Toggle mute')
    
    # Brightness commands
    brightness_parser = subparsers.add_parser('brightness', help='Brightness control commands')
    brightness_subparsers = brightness_parser.add_subparsers(dest='brightness_command', help='Brightness command')
    
    set_bright_parser = brightness_subparsers.add_parser('set', help='Set brightness to a specific percentage')
    set_bright_parser.add_argument('value', type=int, help='Brightness percentage (0-100)')
    
    up_bright_parser = brightness_subparsers.add_parser('up', help='Increase brightness')
    up_bright_parser.add_argument('step', type=int, nargs='?', default=5, help='Step percentage (default: 5)')
    
    down_bright_parser = brightness_subparsers.add_parser('down', help='Decrease brightness')
    down_bright_parser.add_argument('step', type=int, nargs='?', default=5, help='Step percentage (default: 5)')
    
    # OSD Manager commands
    subparsers.add_parser('start', help='Start OSD service via manager')
    subparsers.add_parser('stop', help='Stop OSD service via manager')
    subparsers.add_parser('reload-theme', help='Reload the OSD theme without restarting')
    
    args = parser.parse_args()
    
    if args.command == 'volume':
        if args.volume_command == 'set':
            set_volume(args.value)
        elif args.volume_command == 'up':
            increase_volume(args.step)
        elif args.volume_command == 'down':
            decrease_volume(args.step)
        elif args.volume_command == 'mute':
            toggle_mute()
        else:
            volume_parser.print_help()
    
    elif args.command == 'brightness':
        if args.brightness_command == 'set':
            set_brightness(args.value)
        elif args.brightness_command == 'up':
            increase_brightness(args.step)
        elif args.brightness_command == 'down':
            decrease_brightness(args.step)
        else:
            brightness_parser.print_help()
    
    elif args.command == 'start':
        # Start the OSD manager which will handle starting the OSD
        start_osd_manager()
    
    elif args.command == 'stop':
        # Stop the OSD manager which will handle stopping the OSD
        stop_osd_manager()
    
    elif args.command == 'reload-theme':
        reload_theme()
    
    else:
        parser.print_help()

if __name__ == "__main__":
    main() 
#!/usr/bin/env python3

import os
import sys
import signal
import subprocess
import time
import gi
import logging
from pathlib import Path
import threading

gi.require_version('Gio', '2.0')
from gi.repository import Gio, GLib

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger("OSDManager")

class ConfigFileMonitor:
    """Monitor GTK configuration files for changes."""
    def __init__(self, callback):
        self.callback = callback
        self.file_monitors = []
        self.monitored_paths = []
        
    def start(self):
        """Start monitoring GTK config directories."""
        # Get the user's home directory
        home_dir = os.path.expanduser("~")
        
        # Paths to monitor
        gtk3_config_dir = os.path.join(home_dir, ".config", "gtk-3.0")
        gtk4_config_dir = os.path.join(home_dir, ".config", "gtk-4.0")
        
        # Monitor the GTK3 config directory
        self.add_monitor(gtk3_config_dir)
        
        # Monitor the GTK4 config directory
        self.add_monitor(gtk4_config_dir)
        
        # Monitor specific files
        gtk3_settings = os.path.join(gtk3_config_dir, "settings.ini")
        self.add_monitor(gtk3_settings)
        
        gtk3_css = os.path.join(gtk3_config_dir, "gtk.css")
        self.add_monitor(gtk3_css)
        
        gtk4_settings = os.path.join(gtk4_config_dir, "settings.ini")
        self.add_monitor(gtk4_settings)
        
        gtk4_css = os.path.join(gtk4_config_dir, "gtk.css")
        self.add_monitor(gtk4_css)
        
        # Log monitored paths
        if self.monitored_paths:
            logger.info(f"Monitoring GTK config files: {', '.join(self.monitored_paths)}")
        else:
            logger.warning("No GTK config files found to monitor")
            
        return len(self.file_monitors) > 0
    
    def add_monitor(self, path):
        """Add a file or directory to monitor."""
        if not os.path.exists(path):
            logger.debug(f"Path does not exist, skipping: {path}")
            return False
            
        try:
            file = Gio.File.new_for_path(path)
            monitor = file.monitor(Gio.FileMonitorFlags.NONE, None)
            monitor.connect("changed", self.on_file_changed)
            self.file_monitors.append(monitor)
            self.monitored_paths.append(path)
            logger.debug(f"Added monitor for: {path}")
            return True
        except Exception as e:
            logger.error(f"Error setting up monitor for {path}: {e}")
            return False
    
    def on_file_changed(self, monitor, file, other_file, event_type):
        """Handle file change events."""
        if event_type in [Gio.FileMonitorEvent.CHANGED, 
                         Gio.FileMonitorEvent.CREATED,
                         Gio.FileMonitorEvent.DELETED]:
            path = file.get_path()
            logger.info(f"GTK config file changed: {path}")
            self.callback()
    
    def stop(self):
        """Stop all file monitors."""
        for monitor in self.file_monitors:
            monitor.cancel()
        self.file_monitors = []
        self.monitored_paths = []
        logger.info("Config file monitors stopped")

class OSDManager:
    def __init__(self):
        self.osd_process = None
        self.theme_monitor = None
        self.config_monitor = None
        self.current_theme = None
        self.lock_file = "/tmp/osd-manager.lock"
        self.osd_lock_file = "/tmp/osd-container.lock"
        self.running = True
        self.restart_pending = False
        
        # Set up signal handling for clean shutdown
        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGTERM, self.signal_handler)
        
    def signal_handler(self, sig, frame):
        """Handle signals for clean shutdown."""
        logger.info(f"Received signal {sig}, shutting down...")
        self.stop()
        sys.exit(0)
        
    def start_theme_monitor(self):
        """Start monitoring GTK theme changes."""
        success = False
        
        # Start GSettings-based theme monitor
        try:
            self.settings = Gio.Settings.new("org.gnome.desktop.interface")
            self.current_theme = self.settings.get_string("gtk-theme")
            self.handler_id = self.settings.connect("changed::gtk-theme", self.on_theme_changed)
            logger.info(f"Theme monitor started. Current theme: {self.current_theme}")
            success = True
        except Exception as e:
            logger.error(f"Could not initialize GSettings theme monitor: {e}")
        
        # Start file-based config monitor
        try:
            self.config_monitor = ConfigFileMonitor(self.on_config_changed)
            if self.config_monitor.start():
                logger.info("File-based config monitor started")
                success = True
        except Exception as e:
            logger.error(f"Could not initialize file-based config monitor: {e}")
        
        # Start a GLib main loop in a separate thread
        self.main_loop = GLib.MainLoop()
        self.loop_thread = threading.Thread(target=self.main_loop.run, daemon=True)
        self.loop_thread.start()
        
        return success
    
    def on_theme_changed(self, settings, key):
        """Handle theme changes by restarting the OSD."""
        try:
            # Avoid multiple restarts
            if self.restart_pending:
                return
                
            self.restart_pending = True
            new_theme = settings.get_string(key)
            logger.info(f"Theme changed from {self.current_theme} to {new_theme}")
            self.current_theme = new_theme
            
            # Schedule restart in the main thread
            threading.Thread(target=self.restart_osd).start()
        except Exception as e:
            logger.error(f"Error handling theme change: {e}")
            self.restart_pending = False
    
    def on_config_changed(self):
        """Handle GTK config file changes."""
        try:
            # Avoid multiple restarts
            if self.restart_pending:
                return
                
            self.restart_pending = True
            logger.info("GTK config files changed, restarting OSD")
            
            # Schedule restart in the main thread
            threading.Thread(target=self.restart_osd).start()
        except Exception as e:
            logger.error(f"Error handling config file change: {e}")
            self.restart_pending = False
            
    def restart_osd(self):
        """Restart the OSD process."""
        try:
            logger.info("Restarting OSD due to theme/config change...")
            
            # Kill the current OSD process
            self.stop_osd()
            
            # Wait a moment for the process to fully terminate
            time.sleep(1)
            
            # Start a new OSD process
            self.start_osd()
            
            # Reset restart pending flag
            self.restart_pending = False
            
            logger.info("OSD restarted successfully")
        except Exception as e:
            logger.error(f"Error restarting OSD: {e}")
            self.restart_pending = False
            
    def start_osd(self):
        """Start the OSD process."""
        try:
            # Check if OSD is already running
            if self.is_osd_running():
                logger.info("OSD is already running")
                return
                
            # Get the path to osd.py relative to this script
            script_dir = os.path.dirname(os.path.abspath(__file__))
            osd_script = os.path.join(script_dir, "osd.py")
            
            # Start the OSD process
            self.osd_process = subprocess.Popen(
                [sys.executable, osd_script],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            logger.info(f"Started OSD process with PID {self.osd_process.pid}")
            
            # Start a thread to monitor the OSD process output
            threading.Thread(target=self.monitor_osd_output, daemon=True).start()
            
            return True
        except Exception as e:
            logger.error(f"Error starting OSD: {e}")
            return False
            
    def monitor_osd_output(self):
        """Monitor and log output from the OSD process."""
        if not self.osd_process:
            return
            
        while self.running:
            # Check if process is still running
            if self.osd_process.poll() is not None:
                if not self.restart_pending:
                    logger.warning(f"OSD process exited with code {self.osd_process.returncode}")
                    # Automatically restart if not a planned shutdown
                    if self.running:
                        logger.info("Automatically restarting OSD...")
                        self.start_osd()
                break
                
            # Read output
            try:
                stdout_line = self.osd_process.stdout.readline()
                if stdout_line:
                    logger.info(f"OSD: {stdout_line.strip()}")
                    
                stderr_line = self.osd_process.stderr.readline()
                if stderr_line:
                    logger.error(f"OSD error: {stderr_line.strip()}")
            except Exception:
                # Process might have terminated
                time.sleep(0.1)
                
    def stop_osd(self):
        """Stop the OSD process."""
        # First try to terminate gracefully using the lock file
        if os.path.exists(self.osd_lock_file):
            try:
                # Read PID from lock file
                with open(self.osd_lock_file, 'r') as f:
                    pid = int(f.read().strip())
                
                # Send SIGTERM to the process
                os.kill(pid, signal.SIGTERM)
                logger.info(f"Sent SIGTERM to OSD process with PID {pid}")
                
                # Wait for process to terminate
                for _ in range(10):  # Wait up to 1 second
                    try:
                        os.kill(pid, 0)  # Check if process exists
                        time.sleep(0.1)
                    except OSError:
                        # Process has terminated
                        break
                else:
                    # Process still exists, send SIGKILL
                    try:
                        os.kill(pid, signal.SIGKILL)
                        logger.info(f"Sent SIGKILL to OSD process with PID {pid}")
                    except OSError:
                        pass
                
                # Remove lock file if it still exists
                if os.path.exists(self.osd_lock_file):
                    os.remove(self.osd_lock_file)
                    
                return True
            except (OSError, ValueError) as e:
                logger.error(f"Error stopping OSD via lock file: {e}")
                # Remove stale lock file
                try:
                    if os.path.exists(self.osd_lock_file):
                        os.remove(self.osd_lock_file)
                except OSError:
                    pass
        
        # If we have a process object, terminate it directly
        if self.osd_process and self.osd_process.poll() is None:
            try:
                self.osd_process.terminate()
                self.osd_process.wait(timeout=1)
                logger.info(f"Terminated OSD process with PID {self.osd_process.pid}")
                return True
            except subprocess.TimeoutExpired:
                # Force kill if it doesn't terminate
                self.osd_process.kill()
                logger.info(f"Killed OSD process with PID {self.osd_process.pid}")
                return True
            except Exception as e:
                logger.error(f"Error stopping OSD process: {e}")
                
        return False
        
    def is_osd_running(self):
        """Check if the OSD process is running."""
        # Check if we have a running process
        if self.osd_process and self.osd_process.poll() is None:
            return True
            
        # Check for lock file
        if os.path.exists(self.osd_lock_file):
            try:
                # Read PID from lock file
                with open(self.osd_lock_file, 'r') as f:
                    pid = int(f.read().strip())
                
                # Check if process is running
                os.kill(pid, 0)
                return True
            except (OSError, ValueError):
                # Process not running or invalid PID
                # Remove stale lock file
                try:
                    os.remove(self.osd_lock_file)
                except OSError:
                    pass
                
        return False
        
    def create_lock_file(self):
        """Create a lock file to prevent multiple instances."""
        if os.path.exists(self.lock_file):
            try:
                # Check if the process is still running
                with open(self.lock_file, 'r') as f:
                    pid = int(f.read().strip())
                
                # Try to send a signal to the process
                os.kill(pid, 0)
                logger.error("OSD Manager is already running")
                return False
            except (OSError, ValueError):
                # Process is not running or invalid PID
                # Remove stale lock file
                try:
                    os.remove(self.lock_file)
                except OSError:
                    pass
        
        # Create lock file with current PID
        try:
            with open(self.lock_file, 'w') as f:
                f.write(str(os.getpid()))
            return True
        except OSError as e:
            logger.error(f"Could not create lock file: {e}")
            return False
            
    def remove_lock_file(self):
        """Remove the lock file."""
        try:
            if os.path.exists(self.lock_file):
                os.remove(self.lock_file)
        except OSError as e:
            logger.error(f"Could not remove lock file: {e}")
            
    def run(self):
        """Run the OSD manager."""
        # Create lock file
        if not self.create_lock_file():
            return False
            
        # Start theme monitor
        if not self.start_theme_monitor():
            self.remove_lock_file()
            return False
            
        # Start OSD
        if not self.start_osd():
            self.remove_lock_file()
            return False
            
        logger.info("OSD Manager started successfully")
        
        # Keep running until stopped
        try:
            while self.running:
                time.sleep(1)
        except KeyboardInterrupt:
            logger.info("Keyboard interrupt received, shutting down...")
        finally:
            self.stop()
            
        return True
        
    def stop(self):
        """Stop the OSD manager."""
        self.running = False
        
        # Stop the OSD process
        self.stop_osd()
        
        # Stop the theme monitor
        if hasattr(self, 'main_loop') and self.main_loop.is_running():
            self.main_loop.quit()
            
        # Stop the config file monitor
        if self.config_monitor:
            self.config_monitor.stop()
            
        # Remove lock file
        self.remove_lock_file()
        
        logger.info("OSD Manager stopped")

def main():
    manager = OSDManager()
    manager.run()

if __name__ == "__main__":
    main() 
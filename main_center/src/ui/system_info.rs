use std::process::Command;
use std::thread;
use std::time::Duration;
use glib;
use std::sync::Once;
use std::sync::OnceLock;

pub struct SystemInfo {
    pub hyprland_version: String,
    pub kernel_version: String,
    pub hostname: String,
    pub cpu_info: String,
    pub memory_total: String,
    pub memory_used: String,
    pub memory_percent: f64,
    pub cpu_usage: f64,
    pub disk_usage: f64,
    pub disk_total: String,
    // Add last update timestamp to limit frequent updates
    last_update: std::time::Instant,
}

// Static values that won't change during runtime
struct StaticInfo {
    hyprland_version: String,
    kernel_version: String,
    hostname: String,
    cpu_info: String,
}

// Store static info in a global variable so we don't need to reload it every time
static STATIC_INFO: OnceLock<StaticInfo> = OnceLock::new();
static INIT: Once = Once::new();

impl SystemInfo {
    pub fn new() -> Self {
        // Initialize static information once
        INIT.call_once(|| {
            let _ = STATIC_INFO.set(StaticInfo {
                hyprland_version: Self::get_hyprland_version(),
                kernel_version: Self::get_kernel_version(),
                hostname: Self::get_hostname(),
                cpu_info: Self::get_cpu_info(),
            });
        });
        
        let static_info = STATIC_INFO.get().unwrap();
        let mem_info = Self::get_memory_info();
        let disk_info = Self::get_disk_usage();
        
        SystemInfo {
            hyprland_version: static_info.hyprland_version.clone(),
            kernel_version: static_info.kernel_version.clone(),
            hostname: static_info.hostname.clone(),
            cpu_info: static_info.cpu_info.clone(),
            memory_total: mem_info.0,
            memory_used: mem_info.1,
            memory_percent: mem_info.2,
            cpu_usage: Self::get_cpu_usage(),
            disk_usage: disk_info.0,
            disk_total: disk_info.1,
            last_update: std::time::Instant::now(),
        }
    }

    // Update only dynamic information (for performance)
    pub fn update_dynamic_info(&mut self) {
        // Skip if last update was very recent (avoid CPU spikes)
        let now = std::time::Instant::now();
        if now.duration_since(self.last_update) < Duration::from_millis(800) {
            return;
        }
        
        let mem_info = Self::get_memory_info();
        self.memory_total = mem_info.0;
        self.memory_used = mem_info.1;
        self.memory_percent = mem_info.2;
        self.cpu_usage = Self::get_cpu_usage();
        
        // Only update disk usage every 10 seconds as it rarely changes
        static mut LAST_DISK_UPDATE: Option<std::time::Instant> = None;
        let update_disk = unsafe {
            if let Some(last) = LAST_DISK_UPDATE {
                if now.duration_since(last) > Duration::from_secs(10) {
                    LAST_DISK_UPDATE = Some(now);
                    true
                } else {
                    false
                }
            } else {
                LAST_DISK_UPDATE = Some(now);
                true
            }
        };
        
        if update_disk {
            let disk_info = Self::get_disk_usage();
            self.disk_usage = disk_info.0;
            self.disk_total = disk_info.1;
        }
        
        self.last_update = now;
    }

    fn get_hyprland_version() -> String {
        // Try using hyprctl version
        let hyprctl_result = Command::new("hyprctl")
            .arg("version")
            .output();
        
        if let Ok(output) = hyprctl_result {
            let output_str = String::from_utf8_lossy(&output.stdout).trim().to_string();
            
            // Example: "Hyprland 0.49.0 built from branch at commit 9958d297641b5c84dcff93f9039d80a5ad37ab00 (version: bump to 0.49.0)."
            // We want to extract "0.49.0"
            
            // Look for "Hyprland" prefix and extract the version number that follows
            if output_str.starts_with("Hyprland ") {
                let parts: Vec<&str> = output_str.split_whitespace().collect();
                if parts.len() >= 2 {
                    // The version number should be the second part after splitting by whitespace
                    return parts[1].to_string();
                }
            }
            
            // If we couldn't extract the version in the expected format, return the full string
            if !output_str.is_empty() {
                return output_str;
            }
        }
        
        // Fallback to checking environment variable
        if let Ok(_) = std::env::var("HYPRLAND_INSTANCE_SIGNATURE") {
            return "Hyprland".to_string();
        }
        
        "Not detected".to_string()
    }

    fn get_kernel_version() -> String {
        Command::new("uname")
            .arg("-r")
            .output()
            .map(|output| String::from_utf8_lossy(&output.stdout).trim().to_string())
            .unwrap_or_else(|_| "Unknown".to_string())
    }

    fn get_hostname() -> String {
        // Try using hostname command
        let hostname_result = Command::new("hostname")
            .output();
        
        if let Ok(output) = hostname_result {
            let hostname = String::from_utf8_lossy(&output.stdout).trim().to_string();
            if !hostname.is_empty() {
                return hostname;
            }
        }
        
        // Fallback to reading from /etc/hostname
        if let Ok(hostname) = std::fs::read_to_string("/etc/hostname") {
            let hostname = hostname.trim();
            if !hostname.is_empty() {
                return hostname.to_string();
            }
        }
        
        // Second fallback to using sys_info crate
        "Unknown".to_string()
    }

    fn get_cpu_info() -> String {
        if let Ok(contents) = std::fs::read_to_string("/proc/cpuinfo") {
            if let Some(model_line) = contents.lines().find(|line| line.starts_with("model name")) {
                if let Some(model) = model_line.split(':').nth(1) {
                    return model.trim().to_string();
                }
            }
        }
        "Unknown".to_string()
    }

    // Return (total_mem, used_mem, percentage)
    fn get_memory_info() -> (String, String, f64) {
        if let Ok(contents) = std::fs::read_to_string("/proc/meminfo") {
            let lines: Vec<&str> = contents.lines().collect();
            
            let mut total_kb = 0;
            let mut free_kb = 0;
            let mut buffers_kb = 0;
            let mut cached_kb = 0;
            
            for line in lines {
                if line.starts_with("MemTotal:") {
                    if let Some(value) = line.split_whitespace().nth(1) {
                        total_kb = value.parse::<i64>().unwrap_or(0);
                    }
                } else if line.starts_with("MemFree:") {
                    if let Some(value) = line.split_whitespace().nth(1) {
                        free_kb = value.parse::<i64>().unwrap_or(0);
                    }
                } else if line.starts_with("Buffers:") {
                    if let Some(value) = line.split_whitespace().nth(1) {
                        buffers_kb = value.parse::<i64>().unwrap_or(0);
                    }
                } else if line.starts_with("Cached:") && !line.starts_with("CachedSwap:") {
                    if let Some(value) = line.split_whitespace().nth(1) {
                        cached_kb = value.parse::<i64>().unwrap_or(0);
                    }
                }
            }
            
            let used_kb = total_kb - free_kb - buffers_kb - cached_kb;
            let total_mb = total_kb / 1024;
            let used_mb = used_kb / 1024;
            let percentage = if total_kb > 0 { (used_kb as f64 / total_kb as f64) * 100.0 } else { 0.0 };
            
            return (
                format!("{} MB", total_mb),
                format!("{} MB", used_mb),
                percentage
            );
        }
        
        ("Unknown".to_string(), "Unknown".to_string(), 0.0)
    }

    // CPU usage calculation with static cache to avoid sleep during UI operations
    fn get_cpu_usage() -> f64 {
        // Store previous reading in static variables to avoid sleeping in each call
        static mut LAST_IDLE: i64 = 0;
        static mut LAST_TOTAL: i64 = 0;
        static mut LAST_USAGE: f64 = 0.0;
        
        if let Ok(stat) = std::fs::read_to_string("/proc/stat") {
            if let Some(line) = stat.lines().next() {
                let values: Vec<i64> = line.split_whitespace()
                    .skip(1) // Skip "cpu" prefix
                    .take(7) // Take user, nice, system, idle, iowait, irq, softirq
                    .filter_map(|val| val.parse::<i64>().ok())
                    .collect();
                
                if values.len() >= 4 {
                    unsafe {
                        let idle = values[3];
                        let total: i64 = values.iter().sum();
                        
                        // Calculate the differences from last reading
                        let idle_diff = idle - LAST_IDLE;
                        let total_diff = total - LAST_TOTAL;
                        
                        // Update the static values for next call
                        LAST_IDLE = idle;
                        LAST_TOTAL = total;
                        
                        if total_diff > 0 {
                            // Calculate CPU usage percentage
                            LAST_USAGE = 100.0 * (1.0 - (idle_diff as f64 / total_diff as f64));
                        }
                        
                        return LAST_USAGE;
                    }
                }
            }
        }
        
        0.0
    }
    
    // Returns (usage percentage, total space)
    fn get_disk_usage() -> (f64, String) {
        // Use df to get disk usage
        if let Ok(output) = Command::new("df")
            .args(["-h", "/"])
            .output() {
            
            let output_str = String::from_utf8_lossy(&output.stdout);
            let lines: Vec<&str> = output_str.lines().collect();
            
            if lines.len() > 1 {
                let parts: Vec<&str> = lines[1].split_whitespace().collect();
                if parts.len() >= 5 {
                    let total = parts[1].to_string();
                    
                    // Parse percentage without the % sign
                    if let Some(percent_str) = parts[4].strip_suffix('%') {
                        if let Ok(percent) = percent_str.parse::<f64>() {
                            return (percent, total);
                        }
                    }
                }
            }
        }
        
        (0.0, "Unknown".to_string())
    }
    
    // Creates a timer that updates system info and triggers a callback
    pub fn create_updater<F: Fn() + 'static>(callback: F) -> glib::SourceId {
        // Reduce update frequency to save resources - 3 seconds is plenty for system metrics
        glib::timeout_add_seconds_local(3, move || {
            // Call the callback to trigger UI update
            callback();
            // Continue the timer
            glib::Continue(true)
        })
    }
} 
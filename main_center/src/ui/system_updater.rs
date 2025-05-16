use std::process::{Command, Stdio};
use std::io::{BufReader, BufRead};
use std::path::Path;
use std::fs::File;

pub enum UpdateResult {
    Success(String),
    Error(String),
    NotInstalled,
}

// Function to check if a command exists
pub fn command_exists(command: &str) -> bool {
    Command::new("which")
        .arg(command)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .map(|status| status.success())
        .unwrap_or(false)
}

// Function to detect AUR helper
pub fn detect_aur_helper() -> Option<String> {
    let aur_helpers = ["yay", "paru", "trizen", "pamac"];
    
    for helper in &aur_helpers {
        if command_exists(helper) {
            return Some(helper.to_string());
        }
    }
    
    None
}

// Get basic system info for debugging
pub fn get_debug_info() -> String {
    let mut info = String::new();
    
    // Check kernel
    if let Ok(output) = Command::new("uname").arg("-r").output() {
        let kernel = String::from_utf8_lossy(&output.stdout);
        info.push_str(&format!("Kernel: {}", kernel.trim()));
    }
    
    // Check release info
    if Path::new("/etc/os-release").exists() {
        if let Ok(file) = File::open("/etc/os-release") {
            let reader = BufReader::new(file);
            for line in reader.lines().filter_map(Result::ok) {
                if line.starts_with("NAME=") || line.starts_with("VERSION=") {
                    info.push_str(&format!("{}\n", line));
                }
            }
        }
    }
    
    info
}

// Helper function to run a command in an external terminal
fn run_in_terminal(command: &str) -> std::io::Result<std::process::Child> {
    // Find the preferred terminal
    let terminal = find_terminal().unwrap_or_else(|| {
        // Fallback to common terminals
        ["kitty", "alacritty", "foot", "gnome-terminal", "konsole", "xterm"]
            .iter()
            .find(|&term| command_exists(term))
            .map(|&term| term.to_string())
            .unwrap_or_default()
    });

    if terminal.is_empty() {
        return Err(std::io::Error::new(
            std::io::ErrorKind::NotFound,
            "No suitable terminal found"
        ));
    }

    // Create the command string once
    let cmd_str = format!("{} && echo 'Press Enter to close' && read", command);
    
    // Format command based on terminal type
    let args = match terminal.as_str() {
        "gnome-terminal" => vec!["--", "bash", "-c", &cmd_str],
        "kitty" => vec!["bash", "-c", &cmd_str],
        "foot" => vec!["bash", "-c", &cmd_str],
        _ => vec!["-e", "bash", "-c", &cmd_str],
    };

    Command::new(&terminal).args(args).spawn()
}

// Simplified function to find the user's preferred terminal
fn find_terminal() -> Option<String> {
    // Try environment variable first
    if let Ok(terminal) = std::env::var("TERMINAL") {
        if !terminal.is_empty() && command_exists(&terminal) {
            return Some(terminal);
        }
    }

    // Check Hyprland config
    let home = std::env::var("HOME").unwrap_or_else(|_| String::from("/home/user"));
    let config_paths = [
        format!("{}/.config/hypr/hyprland.conf", home),
        format!("{}/.config/hypr/conf/keybinds.conf", home),
    ];
    
    for config_path in &config_paths {
        if let Ok(content) = std::fs::read_to_string(config_path) {
            // Common terminals to look for
            let terminals = ["kitty", "alacritty", "foot", "konsole", "gnome-terminal", "xterm", "termite"];
            
            for line in content.lines() {
                let line = line.trim();
                if line.starts_with('#') || line.is_empty() {
                    continue;
                }
                
                // Check for terminal env definition
                if line.contains("TERMINAL") && line.contains('=') {
                    let parts: Vec<&str> = line.split('=').collect();
                    if parts.len() >= 2 {
                        let term = parts[1].trim().trim_matches(|c| c == '"' || c == ',');
                        if command_exists(term) {
                            return Some(term.to_string());
                        }
                    }
                }
                
                // Check for terminal in exec or bind lines
                if (line.contains("exec") || line.contains("bind")) && !line.starts_with('#') {
                    for terminal in &terminals {
                        if line.contains(terminal) && command_exists(terminal) {
                            return Some(terminal.to_string());
                        }
                    }
                }
            }
        }
    }
    
    None
}

// Update Pacman packages
pub fn update_pacman() -> UpdateResult {
    if !command_exists("pacman") {
        return UpdateResult::NotInstalled;
    }
    
    match run_in_terminal("sudo pacman -Syu") {
        Ok(_) => UpdateResult::Success(String::from("Started pacman update in external terminal")),
        Err(e) => UpdateResult::Error(format!("Failed to launch terminal: {}", e))
    }
}

// Update AUR packages
pub fn update_aur(helper: &str) -> UpdateResult {
    if !command_exists(helper) {
        return UpdateResult::NotInstalled;
    }
    
    // For AUR helpers, some might need root, others don't
    let needs_sudo = matches!(helper, "pamac");
    let cmd = if needs_sudo {
        format!("sudo {} -Syu", helper)
    } else {
        format!("{} -Syu", helper)
    };
    
    match run_in_terminal(&cmd) {
        Ok(_) => UpdateResult::Success(format!("Started {} update in external terminal", helper)),
        Err(e) => UpdateResult::Error(format!("Failed to launch terminal: {}", e))
    }
}

// Update Flatpak packages
pub fn update_flatpak() -> UpdateResult {
    if !command_exists("flatpak") {
        return UpdateResult::NotInstalled;
    }
    
    match run_in_terminal("flatpak update -y") {
        Ok(_) => UpdateResult::Success(String::from("Started flatpak update in external terminal")),
        Err(e) => UpdateResult::Error(format!("Failed to launch terminal: {}", e))
    }
}

// Update Snap packages
pub fn update_snap() -> UpdateResult {
    if !command_exists("snap") {
        return UpdateResult::NotInstalled;
    }
    
    match run_in_terminal("sudo snap refresh") {
        Ok(_) => UpdateResult::Success(String::from("Started snap update in external terminal")),
        Err(e) => UpdateResult::Error(format!("Failed to launch terminal: {}", e))
    }
} 
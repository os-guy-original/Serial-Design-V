use std::collections::HashMap;
use std::fs::{self, File};
use std::io::{self, Read, Write};
use std::path::{Path, PathBuf};
use std::process::Command;

pub struct HyprlandConfig {
    config_path: PathBuf,
    config_dir: PathBuf,
    parsed_settings: HashMap<String, String>,
    category_files: HashMap<String, PathBuf>,
    pending_changes: HashMap<String, String>,
}

impl HyprlandConfig {
    pub fn new() -> io::Result<Self> {
        let home_dir = dirs::home_dir().expect("Could not find home directory");
        let config_path = home_dir.join(".config").join("hypr").join("hyprland.conf");
        let config_dir = home_dir.join(".config").join("hypr");

        if !config_path.exists() {
            return Err(io::Error::new(
                io::ErrorKind::NotFound,
                "Hyprland config file not found",
            ));
        }

        let mut config = HyprlandConfig {
            config_path,
            config_dir,
            parsed_settings: HashMap::new(),
            category_files: HashMap::new(),
            pending_changes: HashMap::new(),
        };

        config.parse_config()?;
        Ok(config)
    }

    fn parse_config(&mut self) -> io::Result<()> {
        // Read the main config file
        let content = fs::read_to_string(&self.config_path)?;

        // First, detect source files
        for line in content.lines() {
            let line = line.trim();
            if line.starts_with("source") {
                let parts: Vec<&str> = line.split('=').collect();
                if parts.len() == 2 {
                    let path = parts[1].trim();
                    if path.starts_with("~/") {
                        // Handle ~ expansion
                        let expanded_path = dirs::home_dir()
                            .unwrap()
                            .join(path.trim_start_matches("~/"));
                        self.process_source_file(&expanded_path)?;
                    } else {
                        // Handle relative paths
                        let source_path = Path::new(path);
                        let full_path = if source_path.is_absolute() {
                            source_path.to_path_buf()
                        } else {
                            self.config_dir.join(source_path)
                        };
                        self.process_source_file(&full_path)?;
                    }
                }
            }
        }

        // Parse main file for any direct settings
        self.parse_file_content(&content)?;

        Ok(())
    }

    fn process_source_file(&mut self, path: &Path) -> io::Result<()> {
        if !path.exists() {
            return Err(io::Error::new(
                io::ErrorKind::NotFound,
                format!("Source file not found: {:?}", path),
            ));
        }

        // Get the category from the filename
        if let Some(file_name) = path.file_stem() {
            let category = file_name.to_string_lossy().to_string();
            self.category_files.insert(category.clone(), path.to_path_buf());
        }

        // Parse the file content
        let content = fs::read_to_string(path)?;
        self.parse_file_content(&content)?;

        Ok(())
    }

    fn parse_file_content(&mut self, content: &str) -> io::Result<()> {
        let mut current_section = String::new();

        for line in content.lines() {
            let line = line.trim();
            
            // Skip comments and empty lines
            if line.is_empty() || line.starts_with("#") {
                continue;
            }

            // Check for section headers
            if line.ends_with("{") {
                current_section = line.trim_end_matches(" {").trim().to_string();
                continue;
            }

            // Check for section end
            if line == "}" {
                current_section.clear();
                continue;
            }

            // Look for key-value pairs
            if let Some(equals_pos) = line.find('=') {
                let key = line[..equals_pos].trim().to_string();
                let value = line[equals_pos + 1..].trim().to_string();
                
                let setting_key = if current_section.is_empty() {
                    key
                } else {
                    format!("{}.{}", current_section, key)
                };
                
                self.parsed_settings.insert(setting_key, value);
            }
        }

        Ok(())
    }

    pub fn get_setting(&self, name: &str) -> Option<&String> {
        // Check pending changes first
        if let Some(value) = self.pending_changes.get(name) {
            Some(value)
        } else {
            self.parsed_settings.get(name)
        }
    }

    pub fn get_bool_setting(&self, name: &str) -> bool {
        match self.get_setting(name) {
            Some(value) => {
                let value = value.trim().to_lowercase();
                match value.as_str() {
                    "true" | "1" | "yes" | "on" => true,
                    _ => false,
                }
            }
            None => false,
        }
    }

    // Update a setting in memory only
    pub fn update_setting_in_memory(&mut self, name: &str, value: &str) {
        self.pending_changes.insert(name.to_string(), value.to_string());
    }

    // Save all pending changes to disk
    pub fn save_changes(&mut self) -> io::Result<()> {
        // Group changes by the file they belong to
        let mut changes_by_file: HashMap<PathBuf, Vec<(String, String)>> = HashMap::new();
        
        for (setting_name, value) in &self.pending_changes {
            // Determine which file to modify
            if let Some(dot_pos) = setting_name.find('.') {
                let category = &setting_name[..dot_pos];
                if let Some(file_path) = self.category_files.get(category) {
                    let changes = changes_by_file.entry(file_path.clone()).or_insert_with(Vec::new);
                    changes.push((setting_name.clone(), value.clone()));
                }
            }
        }
        
        // Process each file that needs changes
        for (file_path, changes) in changes_by_file {
            // Read the file content
            let content = fs::read_to_string(&file_path)?;
            let mut lines: Vec<String> = content.lines().map(|s| s.to_string()).collect();
            
            // Apply each change to this file
            for (name, value) in changes {
                let section_name = name.split('.').next().unwrap_or("");
                let setting_name = name.split('.').nth(1).unwrap_or(&name);
                
                let mut inside_section = false;
                let mut found = false;
                
                // Find and update the appropriate setting
                for i in 0..lines.len() {
                    let line = lines[i].trim();
                    
                    // Check for section start
                    if !section_name.is_empty() && line.starts_with(section_name) && line.ends_with("{") {
                        inside_section = true;
                        continue;
                    }
                    
                    // Check for section end
                    if line == "}" {
                        inside_section = false;
                        continue;
                    }
                    
                    // If we're in the right section, look for the setting
                    if (section_name.is_empty() || inside_section) && line.starts_with(setting_name) {
                        if let Some(equals_pos) = line.find('=') {
                            // Update the line
                            lines[i] = format!("{} = {}", setting_name, value);
                            found = true;
                            break;
                        }
                    }
                }
                
                if found {
                    // Update the in-memory setting
                    self.parsed_settings.insert(name.clone(), value.clone());
                }
            }
            
            // Write the updated content back to the file
            let mut file = File::create(&file_path)?;
            for line in &lines {
                writeln!(file, "{}", line)?;
            }
        }
        
        // Clear pending changes
        self.pending_changes.clear();
        
        // Reload Hyprland config
        let _ = Command::new("pkexec")
            .args(&["hyprctl", "reload"])
            .output();
        
        Ok(())
    }

    // Check if there are any pending changes
    pub fn has_pending_changes(&self) -> bool {
        !self.pending_changes.is_empty()
    }

    // Get all available settings
    pub fn get_all_settings(&self) -> &HashMap<String, String> {
        &self.parsed_settings
    }
    
    // Get a specific category of settings
    pub fn get_category_settings(&self, category: &str) -> HashMap<String, String> {
        let mut result = HashMap::new();
        let prefix = format!("{}.", category);
        
        for (key, value) in &self.parsed_settings {
            if key.starts_with(&prefix) {
                let short_key = key[prefix.len()..].to_string();
                result.insert(short_key, value.clone());
            }
        }
        
        // Apply any pending changes
        for (key, value) in &self.pending_changes {
            if key.starts_with(&prefix) {
                let short_key = key[prefix.len()..].to_string();
                result.insert(short_key, value.clone());
            }
        }
        
        result
    }
} 
use anyhow::{Context, Result};
use log::{debug, info};
use regex::Regex;
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};

/// Represents a keybind in Hyprland config
#[derive(Debug, Clone, PartialEq)]
pub struct Keybind {
    pub key: String,
    pub modifiers: Vec<String>,
    pub action: String,
    pub description: Option<String>,
}

/// Parser for Hyprland config files
pub struct ConfigParser {
    config_paths: Vec<PathBuf>,
    processed_files: Vec<PathBuf>,
    variables: HashMap<String, String>,
}

impl ConfigParser {
    pub fn new() -> Self {
        Self {
            config_paths: Self::find_config_paths(),
            processed_files: Vec::new(),
            variables: HashMap::new(),
        }
    }

    /// Find possible Hyprland config file paths
    fn find_config_paths() -> Vec<PathBuf> {
        let mut paths = Vec::new();
        
        // Check XDG_CONFIG_HOME
        if let Ok(config_home) = std::env::var("XDG_CONFIG_HOME") {
            paths.push(PathBuf::from(config_home).join("hypr/hyprland.conf"));
        }
        
        // Check HOME/.config
        if let Ok(home) = std::env::var("HOME") {
            paths.push(PathBuf::from(home).join(".config/hypr/hyprland.conf"));
        }
        
        // Check for alternative config paths
        // TODO: Add more paths as needed
        
        debug!("Potential config paths: {:?}", paths);
        paths
    }
    
    /// Parse keybinds from Hyprland config
    pub fn parse_keybinds(&mut self) -> Result<Vec<Keybind>> {
        let mut keybinds = Vec::new();
        
        for path in self.config_paths.clone() {
            if path.exists() {
                info!("Found config file: {:?}", path);
                self.process_config_file(&path, &mut keybinds)?;
            }
        }
        
        Ok(keybinds)
    }
    
    /// Process a config file including source statements
    fn process_config_file(&mut self, path: &Path, keybinds: &mut Vec<Keybind>) -> Result<()> {
        // Avoid processing the same file multiple times
        let path_buf = path.to_path_buf();
        if self.processed_files.contains(&path_buf) {
            return Ok(());
        }
        
        self.processed_files.push(path_buf);
        
        let content = fs::read_to_string(path)
            .with_context(|| format!("Failed to read config file: {:?}", path))?;
        
        // Process source statements to include other files
        let source_regex = Regex::new(r"(?m)^\s*source\s*=\s*(.+)$")?;
        for cap in source_regex.captures_iter(&content) {
            if let Some(source_path_str) = cap.get(1) {
                let source_path_str = source_path_str.as_str().trim();
                let source_path = if source_path_str.starts_with("~/") {
                    if let Ok(home) = std::env::var("HOME") {
                        PathBuf::from(home).join(&source_path_str[2..])
                    } else {
                        continue;
                    }
                } else if source_path_str.starts_with("/") {
                    PathBuf::from(source_path_str)
                } else {
                    // Relative to the current file
                    let parent = path.parent().unwrap_or(Path::new(""));
                    parent.join(source_path_str)
                };
                
                info!("Processing sourced file: {:?}", source_path);
                if source_path.exists() {
                    self.process_config_file(&source_path, keybinds)?;
                }
            }
        }
        
        // Parse variable definitions
        let var_regex = Regex::new(r"(?m)^\s*\$(\w+)\s*=\s*(.+)$")?;
        for cap in var_regex.captures_iter(&content) {
            if cap.len() >= 3 {
                let var_name = cap[1].trim();
                let var_value = cap[2].trim();
                self.variables.insert(format!("${}", var_name), var_value.to_string());
                debug!("Found variable: ${} = {}", var_name, var_value);
            }
        }
        
        // Parse keybinds
        self.parse_keybinds_in_content(&content, keybinds)?;
        
        Ok(())
    }
    
    /// Parse keybinds from file content
    fn parse_keybinds_in_content(&self, content: &str, keybinds: &mut Vec<Keybind>) -> Result<()> {
        // Parse keyboard bindings with regex - Hyprland format: bind = MOD, KEY, ACTION
        let bind_regex = Regex::new(r"(?m)^\s*bind\s*=\s*([^,]+),\s*([^,]+),?\s*(.*)$")?;
        
        for cap in bind_regex.captures_iter(content) {
            if cap.len() >= 3 {
                let mod_combo = cap[1].trim();
                let key = cap[2].trim();
                let action = if cap.len() >= 4 { cap[3].trim() } else { "" };
                
                // Expand variables in the mod combo
                let expanded_mods = self.expand_variables(mod_combo);
                debug!("Processing keybind: '{}' -> '{}', key: '{}', action: '{}'", 
                       mod_combo, expanded_mods, key, action);
                
                // Parse modifiers
                let modifiers: Vec<String> = if expanded_mods.is_empty() {
                    Vec::new()
                } else {
                    expanded_mods.split_whitespace()
                       .map(|s| s.to_string())
                       .collect()
                };
                
                debug!("  Parsed as key: '{}', modifiers: '{:?}'", key, modifiers);
                
                keybinds.push(Keybind {
                    key: key.to_string(),
                    modifiers,
                    action: action.to_string(),
                    description: None,
                });
            }
        }
        
        Ok(())
    }
    
    /// Expand variables in a string
    fn expand_variables(&self, input: &str) -> String {
        let mut result = input.to_string();
        
        for (var_name, var_value) in &self.variables {
            result = result.replace(var_name, var_value);
        }
        
        result
    }
} 
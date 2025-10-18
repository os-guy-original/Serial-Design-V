#!/usr/bin/env fish

# Fish Shell Configuration - Modular & Dynamic
# Organized for better maintainability and performance

# Core system configuration (load first)
for module in env paths aliases functions
    set -l module_file "$__fish_config_dir/modules/$module.fish"
    if test -f "$module_file"
        source "$module_file"
    end
end

# Load all custom functions BEFORE conf.d (plugins need these)
# Load from top-level functions directory
for func_file in "$__fish_config_dir/functions"/*.fish
    if test -f "$func_file"
        source "$func_file"
    end
end

# Load from function subdirectories (core, ui, md3, etc.)
for func_dir in "$__fish_config_dir/functions"/*
    if test -d "$func_dir"
        for func_file in "$func_dir"/*.fish
            if test -f "$func_file"
                source "$func_file"
            end
        end
    end
end

# Plugin and theme configurations (load AFTER functions)
for config_file in "$__fish_config_dir/conf.d"/*.fish
    if test -f "$config_file"
        source "$config_file"
    end
end

# Development environment integrations
for integration in pyenv conda android java kiro
    set -l integration_file "$__fish_config_dir/integrations/$integration.fish"
    if test -f "$integration_file"
        source "$integration_file"
    end
end

# Custom key bindings
bind \e\cf find_n_run  # Ctrl+Alt+F for find_n_run
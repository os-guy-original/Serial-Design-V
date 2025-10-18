#!/usr/bin/env fish

# Fish Configuration Validator
# Checks the modular fish configuration for issues

function validate_config --description "Validate fish configuration structure"
    set -l config_dir "$HOME/.config/fish"
    set -l errors 0
    
    echo "🐟 Fish Configuration Validator"
    echo "================================"
    echo
    
    # Check main config file
    if test -f "$config_dir/config.fish"
        echo "✅ Main config file exists"
    else
        echo "❌ Main config file missing"
        set errors (math $errors + 1)
    end
    
    # Check modules directory
    if test -d "$config_dir/modules"
        echo "✅ Modules directory exists"
        
        # Check individual modules
        for module in env paths aliases functions
            if test -f "$config_dir/modules/$module.fish"
                echo "  ✅ Module: $module.fish"
            else
                echo "  ❌ Module missing: $module.fish"
                set errors (math $errors + 1)
            end
        end
    else
        echo "❌ Modules directory missing"
        set errors (math $errors + 1)
    end
    
    # Check integrations directory
    if test -d "$config_dir/integrations"
        echo "✅ Integrations directory exists"
        
        set -l integration_count (count "$config_dir/integrations"/*.fish)
        echo "  📦 Found $integration_count integration files"
    else
        echo "⚠️  Integrations directory missing (optional)"
    end
    
    # Check conf.d directory
    if test -d "$config_dir/conf.d"
        echo "✅ Plugin configuration directory exists"
        
        set -l plugin_count (count "$config_dir/conf.d"/*.fish)
        echo "  🔌 Found $plugin_count plugin configuration files"
    else
        echo "❌ Plugin configuration directory missing"
        set errors (math $errors + 1)
    end
    
    # Check functions directory
    if test -d "$config_dir/functions"
        echo "✅ Functions directory exists"
        
        set -l function_count (count "$config_dir/functions"/*.fish)
        echo "  ⚙️  Found $function_count function files"
    else
        echo "❌ Functions directory missing"
        set errors (math $errors + 1)
    end
    
    echo
    
    # Summary
    if test $errors -eq 0
        echo "🎉 Configuration validation passed!"
        echo "Your fish configuration is properly structured."
    else
        echo "⚠️  Configuration validation failed with $errors errors."
        echo "Please check the missing components above."
        return 1
    end
    
    # Performance check
    echo
    echo "🚀 Performance Check"
    echo "===================="
    
    set -l start_time (date +%s%3N)
    source "$config_dir/config.fish" >/dev/null 2>&1
    set -l end_time (date +%s%3N)
    set -l load_time (math $end_time - $start_time)
    
    echo "Configuration load time: {$load_time}ms"
    
    if test $load_time -lt 500
        echo "✅ Excellent performance!"
    else if test $load_time -lt 1000
        echo "⚠️  Good performance, but could be optimized"
    else
        echo "❌ Slow performance, consider optimizing"
    end
end

# Run validation if script is executed directly
if test (basename (status filename)) = "validate_config.fish"
    validate_config
end
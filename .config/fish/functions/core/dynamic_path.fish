function dynamic_path --description "Convert hardcoded paths to use $HOME dynamically"
    set -l path $argv[1]
    
    # Replace hardcoded home directory with $HOME
    echo (string replace -- "$HOME" '$HOME' $path)
end 
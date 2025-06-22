function file_manager
    # Ensure fzf is available
    if not type -q fzf
        pipe_line "fzf is not installed – cannot open picker"
        return 1
    end

    # Check if we're in interactive mode
    if not status is-interactive
        echo "This function must be run in interactive mode."
        return 1
    end
    
        # Function to find available editors and let user choose with fzf
    function select_editor
        # Create a temporary file for editors list
        set -l editors_file (mktemp)
        
        # Check for common CLI text editors and add them to the list if available
        if command -s ms-edit >/dev/null 2>&1
            echo "ms-edit | Microsoft TUI Text Editor" >> $editors_file
        end
        if command -s nano >/dev/null 2>&1
            echo "nano | nano (simple editor)" >> $editors_file
        end
        if command -s vim >/dev/null 2>&1
            echo "vim | vim (advanced editor)" >> $editors_file
        end
        if command -s nvim >/dev/null 2>&1
            echo "nvim | neovim (modern vim)" >> $editors_file
        end
        if command -s vi >/dev/null 2>&1
            echo "vi | vi (basic editor)" >> $editors_file
        end
        if command -s micro >/dev/null 2>&1
            echo "micro | micro (user-friendly editor)" >> $editors_file
        end
        if command -s emacs >/dev/null 2>&1
            echo "emacs | emacs (powerful editor)" >> $editors_file
            echo "emacs -nw | emacs terminal (no window)" >> $editors_file
        end
        if command -s joe >/dev/null 2>&1
            echo "joe | joe (classic editor)" >> $editors_file
        end
        if command -s ne >/dev/null 2>&1
            echo "ne | ne (nice editor)" >> $editors_file
        end
        if command -s mcedit >/dev/null 2>&1
            echo "mcedit | mcedit (midnight commander editor)" >> $editors_file
        end
        if command -s jed >/dev/null 2>&1
            echo "jed | jed (programmer's editor)" >> $editors_file
        end
        if command -s mg >/dev/null 2>&1
            echo "mg | mg (micro emacs clone)" >> $editors_file
        end
        if command -s zile >/dev/null 2>&1
            echo "zile | zile (emacs clone)" >> $editors_file
        end
        if command -s kak >/dev/null 2>&1
            echo "kak | kakoune (vim-inspired editor)" >> $editors_file
        end
        if command -s amp >/dev/null 2>&1
            echo "amp | amp (terminal editor)" >> $editors_file
        end
        if command -s helix >/dev/null 2>&1
            echo "helix | helix (modern editor)" >> $editors_file
        end
        if command -s dte >/dev/null 2>&1
            echo "dte | dte (small editor)" >> $editors_file
        end
        if command -s ee >/dev/null 2>&1
            echo "ee | ee (easy editor)" >> $editors_file
        end
        if command -s tilde >/dev/null 2>&1
            echo "tilde | tilde (intuitive editor)" >> $editors_file
        end
        
        # Add default editor if it exists and is executable
        if set -q EDITOR
            if command -s $EDITOR >/dev/null 2>&1
                echo "$EDITOR | $EDITOR (default editor)" >> $editors_file
            end
        end
        
        # Check if any editors were found
        if test ! -s $editors_file
            echo "No text editors found. Please install nano, vim, or set the EDITOR environment variable."
            rm -f $editors_file
            return 1
        end
        
        # Create a temporary preview script for editor descriptions
        set -l editor_preview_script (mktemp)
        echo '#!/usr/bin/env bash
editor_cmd=$(echo "$1" | cut -d"|" -f1 | sed "s/ *$//")
editor_info=$(echo "$1" | cut -d"|" -f2 | sed "s/^ *//")
echo "Command: $editor_cmd"
echo "Description: $editor_info"
echo ""
echo "This will open the selected file with this editor."
' > $editor_preview_script
        chmod +x $editor_preview_script
        
        # Use fzf to select an editor
        set -l selected_editor (
            cat $editors_file | \
            fzf --prompt="Select editor> " \
                --height=40% \
                --layout=reverse \
                --border \
                --header="Choose a text editor" \
                --preview="$editor_preview_script {}" \
                --preview-window=down:3 | \
                cut -d"|" -f1 | string trim
        )
        

        
        # Clean up temporary files
        rm -f $editors_file $editor_preview_script
        
        # Return the selected editor command
        if test -n "$selected_editor"
            # Ensure the command is clean and properly formatted
            set -l clean_editor (string trim "$selected_editor")
            echo $clean_editor
            return 0
        else
            # User cancelled selection
            return 1
        end
    end

    # Initialize variables
    set -l current_dir (pwd)
    set -l clipboard ""
    set -l clipboard_op ""
    set -l exit_requested 0
    set -l show_actions_for ""

    # Create a temporary preview script for file browsing
    set -l file_preview_script (mktemp)
    
    # Write the current directory to the script for dynamic updates
    echo "#!/usr/bin/env bash" > $file_preview_script
    echo "current_dir=\"$current_dir\"" >> $file_preview_script
    
    # Append the rest of the script
    echo '
# Always read file content directly to ensure we get the latest content
if [ "$1" = ".." ]; then
    echo "Parent Directory: $(dirname "$current_dir")"
    echo "Size: $(du -sh "$current_dir"/../ 2>/dev/null | cut -f1)"
    echo ""
    echo "--- Contents ---"
    # Use ls with colors if available
    if command -v exa >/dev/null 2>&1; then
        exa -la --color=always "$current_dir"/../ 2>/dev/null
    else
        ls -la --color=always "$current_dir"/../ 2>/dev/null
    fi
else
    if [ -f "$current_dir/$1" ]; then
        # Get file info
        echo "File: $1"
        echo "Type: $(file -b "$current_dir/$1")"
        echo "Size: $(du -h "$current_dir/$1" | cut -f1)"
        echo "Last Modified: $(stat -c %y "$current_dir/$1" 2>/dev/null || stat -f "%Sm" "$current_dir/$1" 2>/dev/null)"
        echo ""
        
        # Force text file detection for small files to ensure content is shown
        file_size=$(stat -c %s "$current_dir/$1" 2>/dev/null || stat -f "%z" "$current_dir/$1" 2>/dev/null)
        mime_type=$(file -b --mime-type "$current_dir/$1")
        
        # For small files or text files, show content
        if [ "$file_size" -lt 1048576 ] || echo "$mime_type" | grep -q "text/"; then
            echo "--- Content Preview ---"
            # Try to use bat for syntax highlighting if available
            if command -v bat >/dev/null 2>&1; then
                bat --color=always --style=plain --line-range :200 "$current_dir/$1" 2>/dev/null
            else
                # Otherwise use cat with line numbers
                cat -n "$current_dir/$1" 2>/dev/null | head -n 200
            fi
        elif echo "$mime_type" | grep -q "image/"; then
            echo "[Image File]"
            # Try to use ASCII art preview if available
            if command -v chafa >/dev/null 2>&1; then
                chafa "$current_dir/$1" 2>/dev/null
            elif command -v img2txt >/dev/null 2>&1; then
                img2txt "$current_dir/$1" 2>/dev/null
            fi
        elif echo "$mime_type" | grep -q "video/"; then
            echo "[Video File]"
            # Show video info if ffprobe is available
            if command -v ffprobe >/dev/null 2>&1; then
                ffprobe -hide_banner "$current_dir/$1" 2>&1 | grep -E "Duration|Stream|Input"
            fi
        elif echo "$mime_type" | grep -q "audio/"; then
            echo "[Audio File]"
            # Show audio info if ffprobe is available
            if command -v ffprobe >/dev/null 2>&1; then
                ffprobe -hide_banner "$current_dir/$1" 2>&1 | grep -E "Duration|Stream|Input"
            fi
        else
            echo "[Binary File]"
            # Try to use hexdump for binary files
            if command -v hexdump >/dev/null 2>&1; then
                hexdump -C "$current_dir/$1" 2>/dev/null | head -n 20
            fi
        fi
    elif [ -d "$current_dir/$1" ]; then
        echo "Directory: $1"
        echo "Items: $(ls -1a "$current_dir/$1" 2>/dev/null | wc -l)"
        echo "Size: $(du -sh "$current_dir/$1" 2>/dev/null | cut -f1)"
        echo ""
        echo "--- Contents ---"
        # Use ls with colors if available
        if command -v exa >/dev/null 2>&1; then
            exa -la --color=always "$current_dir/$1" 2>/dev/null
        else
            ls -la --color=always "$current_dir/$1" 2>/dev/null
        fi
        
        # Show disk usage for subdirectories
        echo ""
        echo "--- Disk Usage ---"
        du -sh "$current_dir/$1"/* 2>/dev/null | sort -hr | head -n 10
    else
        echo "$1"
    fi
fi' >> $file_preview_script
    chmod +x $file_preview_script

    # Create a temporary actions preview script
    set -l actions_preview_script (mktemp)
    echo '#!/usr/bin/env bash
if [ "$1" = "📋 Copy" ]; then
    echo "Copy this item to clipboard"
elif [ "$1" = "✂️ Cut" ]; then
    echo "Move this item to clipboard"
elif [ "$1" = "📌 Paste" ]; then
    echo "Paste clipboard contents here"
elif [ "$1" = "✏️ Edit" ]; then
    echo "Edit this file with text editor"
elif [ "$1" = "🔄 Rename" ]; then
    echo "Rename this file or folder"
elif [ "$1" = "📝 Create File" ]; then
    echo "Create a new file"
elif [ "$1" = "📁 Create Folder" ]; then
    echo "Create a new directory"
elif [ "$1" = "🗑️ Delete" ]; then
    echo "Remove this item"
elif [ "$1" = "🔙 Cancel" ]; then
    echo "Return to browser"
fi
' > $actions_preview_script
    chmod +x $actions_preview_script

    while test $exit_requested -eq 0
        # Check if we need to show actions menu
        if test -n "$show_actions_for"
            # Show actions menu for the selected item
            set -l item_name $show_actions_for
            set show_actions_for ""
            
            # Don't show actions menu for parent directory
            if test "$item_name" = ".."
                continue
            end
            
            # Create temporary file for actions
            set -l actions_file (mktemp)
            echo "📋 Copy" > $actions_file
            echo "✂️ Cut" >> $actions_file
            echo "📌 Paste" >> $actions_file
            echo "✏️ Edit" >> $actions_file
            echo "🔄 Rename" >> $actions_file
            echo "📝 Create File" >> $actions_file
            echo "📁 Create Folder" >> $actions_file
            echo "🗑️ Delete" >> $actions_file
            echo "🔙 Cancel" >> $actions_file
            
            # Show actions menu for the selected item
            set -l action (cat $actions_file | fzf \
                --prompt="action> " \
                --height=40% \
                --layout=reverse \
                --border \
                --header="Select action for: $item_name" \
                --preview="$actions_preview_script {}" \
                --preview-window=down:3)
            
            # Clean up
            rm -f $actions_file
            
            # Handle action selection
            if test -z "$action"; or string match -q "🔙 Cancel" "$action"
                # Do nothing and continue
                continue
            else if string match -q "📋 Copy" "$action"
                # Copy selected file/folder
                set clipboard "$current_dir/$item_name"
                set clipboard_op "copy"
            else if string match -q "✂️ Cut" "$action"
                # Cut selected file/folder
                set clipboard "$current_dir/$item_name"
                set clipboard_op "cut"
            else if string match -q "📌 Paste" "$action"
                # Paste file or directory
                if test -n "$clipboard"
                    set -l target_path "$current_dir/$item_name"
                    # Only paste into directories
                    if test -d "$target_path"
                        if test "$clipboard_op" = "copy"
                            # Copy file or directory
                            if test -d "$clipboard"
                                cp -r "$clipboard" "$target_path/"
                            else
                                cp "$clipboard" "$target_path/"
                            end
                        else if test "$clipboard_op" = "cut"
                            # Move file or directory
                            mv "$clipboard" "$target_path/"
                            set clipboard ""
                            set clipboard_op ""
                        end
                    end
                end
            else if string match -q "✏️ Edit" "$action"
                # Edit the selected file
                set -l file_path "$current_dir/$item_name"
                if test -f "$file_path"
                    # Get user's choice of editor using fzf
                    set -l editor_cmd (select_editor)
                    set -l editor_status $status
                    
                    if test $editor_status -eq 0 -a -n "$editor_cmd"
                        # Use the selected editor
                        echo "Opening file with: $editor_cmd"
                        # Execute the editor directly
                        switch $editor_cmd
                            case "nano"
                                nano "$file_path"
                            case "vim"
                                vim "$file_path"
                            case "nvim"
                                nvim "$file_path"
                            case "micro"
                                micro "$file_path"
                            case "emacs"
                                emacs "$file_path"
                            case "emacs -nw"
                                emacs -nw "$file_path"
                            case "vi"
                                vi "$file_path"
                            case "ms-edit"
                                # Microsoft TUI editor needs special handling
                                command ms-edit "$file_path"
                            case "*"
                                # For other editors, use eval
                                eval "$editor_cmd \"$file_path\""
                        end
                        if test $status -ne 0
                            echo "Error running editor. Press any key to continue."
                            read -p "Press any key to continue" -n 1 confirm
                        end
                    else
                        echo "No editor selected or available. Press any key to continue."
                        read -p "Press any key to continue" -n 1 confirm
                    end
                end
            else if string match -q "🔄 Rename" "$action"
                # Rename the selected item
                set -l old_path "$current_dir/$item_name"
                read -P "Enter new name: " new_name
                
                if test -n "$new_name"
                    set -l new_path "$current_dir/$new_name"
                    
                    # Check if target already exists
                    if test -e "$new_path"
                        read -P "Target already exists. Overwrite? (y/n): " confirm
                        if not string match -q "y" "$confirm"
                            continue
                        end
                    end
                    
                    # Perform the rename using cp + rm to ensure content preservation
                    if test -f "$old_path"
                        # For files, copy content then remove original
                        cp -p "$old_path" "$new_path"
                        set -l cp_status $status
                        
                        if test $cp_status -eq 0
                            rm "$old_path"
                            echo "File renamed to: $new_path"
                        else
                            echo "Error renaming file. Press any key to continue."
                            read -p "Press any key to continue" -n 1 confirm
                        end
                    else if test -d "$old_path"
                        # For directories, use mv
                        mv "$old_path" "$new_path"
                        if test $status -ne 0
                            echo "Error renaming directory. Press any key to continue."
                            read -p "Press any key to continue" -n 1 confirm
                        end
                    end
                end
            else if string match -q "📝 Create File" "$action"
                # Create a new file
                read -P "Enter file name: " new_file
                if test -n "$new_file"
                    # Create file in the selected directory if it's a directory
                    set -l file_path
                    if test -d "$current_dir/$item_name"
                        set file_path "$current_dir/$item_name/$new_file"
                        touch "$file_path"
                        echo "File created: $file_path"
                    else
                        set file_path "$current_dir/$new_file"
                        touch "$file_path"
                        echo "File created: $file_path"
                    end
                    
                    # Ask if user wants to edit the file
                    read -P "Edit this file now? (y/n): " edit_now
                    if string match -q -i "y" "$edit_now"
                        # Get user's choice of editor using fzf
                        set -l editor_cmd (select_editor)
                        set -l editor_status $status
                        
                        if test $editor_status -eq 0 -a -n "$editor_cmd"
                            # Use the selected editor
                            echo "Opening file with: $editor_cmd"
                            # Execute the editor directly
                            switch $editor_cmd
                                case "nano"
                                    nano "$file_path"
                                case "vim"
                                    vim "$file_path"
                                case "nvim"
                                    nvim "$file_path"
                                case "micro"
                                    micro "$file_path"
                                case "emacs"
                                    emacs "$file_path"
                                case "emacs -nw"
                                    emacs -nw "$file_path"
                                case "vi"
                                    vi "$file_path"
                                case "ms-edit"
                                    # Microsoft TUI editor needs special handling
                                    command ms-edit "$file_path"
                                case "*"
                                    # For other editors, use eval
                                    eval "$editor_cmd \"$file_path\""
                            end
                            if test $status -ne 0
                                echo "Error running editor. Press any key to continue."
                                read -p "Press any key to continue" -n 1 confirm
                            end
                        else
                            echo "No editor selected or available. Press any key to continue."
                            read -p "Press any key to continue" -n 1 confirm
                        end
                    end
                end
            else if string match -q "📁 Create Folder" "$action"
                # Create a new directory
                read -P "Enter folder name: " new_dir
                if test -n "$new_dir"
                    # Create directory in the selected directory if it's a directory
                    if test -d "$current_dir/$item_name"
                        mkdir -p "$current_dir/$item_name/$new_dir"
                    else
                        mkdir -p "$current_dir/$new_dir"
                    end
                end
            else if string match -q "🗑️ Delete" "$action"
                # Delete the selected item
                read -P "Delete $item_name? (y/n): " confirm
                if string match -q "y" "$confirm"
                    if test -d "$current_dir/$item_name"
                        rm -rf "$current_dir/$item_name"
                    else
                        rm -f "$current_dir/$item_name"
                    end
                end
            end
            
            continue
        end

        # Get list of files and directories
        set -l items (find $current_dir -maxdepth 1 -not -path "*/\.*" | sort)
        
        # Add parent directory to the list
        set -l all_items
        set -a all_items ".."
        
        # Add files and directories to the list
        for item in $items
            if test "$item" != "$current_dir"
                set -a all_items (string replace "$current_dir/" "" $item)
            end
        end
        
        # Show current clipboard status and help info
        set -l status_line "Current directory: $current_dir"
        if test -n "$clipboard"
            set status_line "$status_line | Clipboard: $clipboard ($clipboard_op)"
        end
        set -l help_line "↑/↓:navigate | Enter:select | Esc:exit | Ctrl+E:actions menu"
        
        # Create a temporary file for storing the selected item
        set -l tmp_file (mktemp)
        
        # Create a temporary file for the list of items
        set -l items_file (mktemp)
        printf "%s\n" $all_items > $items_file
        
        # Update the preview script with the current directory
        sed -i "s|^current_dir=.*|current_dir=\"$current_dir\"|" $file_preview_script
        
        # Use fzf to select an item
        set -l result (
            fzf \
                --prompt="file> " \
                --header="$status_line | $help_line" \
                --height=60% \
                --layout=reverse \
                --border \
                --bind="ctrl-e:execute(echo {+} > $tmp_file)+abort" \
                --bind="ctrl-r:reload(find $current_dir -maxdepth 1 -not -path '*/\\.*' | sort | sed 's|$current_dir/||')" \
                --preview="$file_preview_script {}" \
                --preview-window=down:60% \
                --ansi < $items_file
        )
        
        # Clean up temporary files
        rm -f $items_file
        
        # Check if Ctrl+E was pressed
        if test -f "$tmp_file" -a -s "$tmp_file"
            set show_actions_for (cat "$tmp_file")
            rm -f "$tmp_file"
            continue
        end
        rm -f "$tmp_file"
        
        # Set selected item
        set -l selected $result
        
        # Handle regular selection
        if test -z "$selected"
            # Exit if nothing selected or Escape pressed
            set exit_requested 1
        else if test "$selected" = ".."
            # Go up one directory
            set current_dir (dirname $current_dir)
        else
            # Navigate to selected directory or show file
            set -l full_path "$current_dir/$selected"
            if test -d "$full_path"
                set current_dir "$full_path"
            else if test -f "$full_path"
                # Show file content
                less "$full_path"
            end
        end
    end
    
    # Clean up temporary scripts
    rm -f $file_preview_script $actions_preview_script
    
    # Clean up the select_editor function
    functions -e select_editor
end 
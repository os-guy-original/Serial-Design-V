# Java Development Integration
# Java environment configuration

# Java GTK Theming
set -gx _JAVA_OPTIONS '-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true -Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel'

# Java preferences location (XDG compliance)
set -gx _JAVA_OPTIONS "$_JAVA_OPTIONS -Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java"

# Go configuration (if available)
if type -q go
    set -gx GOPATH "$HOME/go"
    fish_add_path "$GOPATH/bin"
end

# Rust configuration
if test -d "$HOME/.cargo"
    set -gx RUSTUP_HOME "$HOME/.rustup"
    set -gx CARGO_HOME "$HOME/.cargo"
end

# Node.js configuration
if type -q node
    set -gx NODE_OPTIONS "--max-old-space-size=4096"
end
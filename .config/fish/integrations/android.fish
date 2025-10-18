# Android Development Integration
# Android SDK configuration

if test -d "/opt/android-sdk"
    set -gx ANDROID_HOME "/opt/android-sdk"
    set -gx ANDROID_SDK_ROOT "/opt/android-sdk"
    
    fish_add_path "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin"
    fish_add_path "$ANDROID_SDK_ROOT/emulator"
    fish_add_path "$ANDROID_SDK_ROOT/platform-tools"
end
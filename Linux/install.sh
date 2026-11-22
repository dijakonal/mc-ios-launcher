#!/bin/bash
#
# install.sh - Install MC iOS Launcher from Linux
#
# Usage: ./install.sh [path/to/MCiOSLauncher.ipa]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IPA_FILE="${1:-$SCRIPT_DIR/../build/ipa/MCiOSLauncher.ipa}"
BUNDLE_ID="com.mcioslauncher.app"

echo "=== MC iOS Launcher - Linux Installer ==="
echo ""

# Check for required tools
check_tools() {
    local missing=()
    
    for cmd in idevicepair ideviceinstaller ideviceinfo; do
        if ! command -v $cmd &> /dev/null; then
            missing+=($cmd)
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo "ERROR: Missing required tools: ${missing[*]}"
        echo ""
        echo "Install on Arch Linux:"
        echo "  sudo pacman -S libimobiledevice usbmuxd"
        echo ""
        exit 1
    fi
}

# Check services
check_services() {
    if ! systemctl is-active --quiet usbmuxd; then
        echo "Starting usbmuxd..."
        sudo systemctl start usbmuxd
    fi
    
    if ! systemctl is-active --quiet avahi-daemon; then
        echo "Starting avahi-daemon..."
        sudo systemctl start avahi-daemon
    fi
}

# Pair device
pair_device() {
    echo "Step 1: Pairing iPhone..."
    echo ""
    echo "  → Unlock your iPhone and keep it on the home screen"
    echo "  → If prompted, tap 'Trust' and enter your passcode"
    echo ""
    
    if ! idevicepair pair 2>&1; then
        echo ""
        echo "  ERROR: Pairing failed"
        echo "  - Make sure iPhone is unlocked"
        echo "  - Try unplugging and replugging the USB cable"
        exit 1
    fi
    
    echo "  ✓ Paired successfully"
}

# Check connection
check_connection() {
    echo ""
    echo "Step 2: Checking connection..."
    
    local device_info=$(ideviceinfo | grep -E "ProductVersion|DeviceName" 2>&1)
    
    if [ -z "$device_info" ]; then
        echo "  ERROR: No device found"
        exit 1
    fi
    
    echo "  $device_info" | sed 's/^/  → /'
    echo "  ✓ Device connected"
}

# Install IPA
install_ipa() {
    echo ""
    echo "Step 3: Installing IPA..."
    
    if [ ! -f "$IPA_FILE" ]; then
        echo "  ERROR: IPA file not found: $IPA_FILE"
        echo ""
        echo "  Build it first:"
        echo "    cd .. && ./Scripts/build-app.sh"
        echo ""
        echo "  Or download a prebuilt IPA:"
        echo "    https://github.com/FlameLaunchers/FlameLauncher-iOS/releases"
        exit 1
    fi
    
    local file_size=$(stat -c%s "$IPA_FILE" 2>/dev/null || stat -f%z "$IPA_FILE")
    local file_size_mb=$((file_size / 1024 / 1024))
    
    echo "  → File: $IPA_FILE (${file_size_mb}MB)"
    echo ""
    
    # Uninstall previous version if exists
    echo "  → Removing previous version (if any)..."
    ideviceinstaller -u $BUNDLE_ID 2>/dev/null || true
    
    # Install
    echo "  → Installing..."
    if ! ideviceinstaller -i "$IPA_FILE"; then
        echo ""
        echo "  ERROR: Installation failed"
        echo "  - Try: ideviceinstaller -u $BUNDLE_ID && ideviceinstaller -i $IPA_FILE"
        exit 1
    fi
    
    echo "  ✓ Installation complete"
}

# Verify installation
verify_install() {
    echo ""
    echo "Step 4: Verifying installation..."
    
    if ideviceinstaller -l | grep -q "MC iOS Launcher"; then
        echo "  ✓ App installed successfully"
    else
        echo "  WARNING: App not found in installed list"
        echo "  Check your iPhone's home screen"
    fi
}

# JIT instructions
jit_instructions() {
    echo ""
    echo "=== Next Steps ==="
    echo ""
    echo "1. Enable JIT (required for Java to run):"
    echo ""
    echo "   Option A: SideJITServer (recommended for Linux)"
    echo "     yay -S sidejitserver-git"
    echo "     sidejitserver"
    echo "     # On iPhone: Settings → Wi-Fi → Configure SideJITServer IP"
    echo ""
    echo "   Option B: StikDebug"
    echo "     # Install StikDebug IPA, create pairing file, enable JIT"
    echo ""
    echo "2. Open 'MC iOS Launcher' on your iPhone"
    echo ""
    echo "3. Sign in with Microsoft account"
    echo ""
    echo "4. Download Minecraft version and play!"
    echo ""
}

# Main
main() {
    check_tools
    check_services
    pair_device
    check_connection
    install_ipa
    verify_install
    jit_instructions
    
    echo "Done! 🎮"
}

main

#!/bin/bash
#
# download-natives.sh
# Downloads prebuilt SDL3, LWJGL, and OpenJDK for iOS arm64
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
NATIVES_DIR="$PROJECT_DIR/Natives"

echo "=== MC iOS Launcher - Native Downloader ==="
echo "Downloading prebuilt natives to: $NATIVES_DIR"

mkdir -p "$NATIVES_DIR"/{SDL3,LWJGL,OpenJDK,MobileGlues}

# SDL3 for iOS arm64
# Source: libsdl-org/SDL release-3.4.16
download_sdl3() {
    echo "Downloading SDL3..."
    local sdl_url="https://github.com/FlameLaunchers/FlameLauncher-SDL3/releases/download/sdl3-v3.4.16-3/libSDL3-ios-arm64.dylib"
    curl -L -o "$NATIVES_DIR/SDL3/libSDL3.dylib" "$sdl_url"
    echo "  SDL3 downloaded ($(stat -f%z "$NATIVES_DIR/SDL3/libSDL3.dylib" | numfmt --to=iec))"
}

# LWJGL 3.4.3 natives for iOS arm64
download_lwjgl() {
    echo "Downloading LWJGL 3.4.3..."
    local lwjgl_url="https://github.com/FlameLaunchers/FlameLauncher-SDL3/releases/download/lwjgl-v3.4.3-1/lwjgl-ios-arm64.zip"
    local temp_zip="/tmp/lwjgl-ios.zip"
    
    curl -L -o "$temp_zip" "$lwjgl_url"
    unzip -q -o "$temp_zip" -d "$NATIVES_DIR/LWJGL/"
    rm "$temp_zip"
    
    echo "  LWJGL downloaded ($(du -sh "$NATIVES_DIR/LWJGL" | cut -f1))"
}

# MobileGlues renderer (OpenGL -> GLES translator)
download_mobileglues() {
    echo "Downloading MobileGlues..."
    # MobileGlues needs to be built from source for now
    # TODO: Add prebuilt release to FlameLauncher-SDL3
    echo "  MobileGlues: building from source (see build-mobileglues.sh)"
}

# OpenJDK for iOS arm64 (Temurin-based)
download_openjdk() {
    echo "Downloading OpenJDK..."
    # Using a prebuilt iOS OpenJDK port
    # Source: adoptium/temurin or custom iOS build
    local jdk_url="https://github.com/AngelAuraMC/Amethyst-iOS/releases/download/java25-ios/Java25-iOS-arm64.tar.gz"
    
    # Try Amethyst's Java 25 build first
    if curl -fL -o "/tmp/java25.tar.gz" "$jdk_url" 2>/dev/null; then
        tar -xzf "/tmp/java25.tar.gz" -C "$NATIVES_DIR/OpenJDK/" --strip-components=1
        rm "/tmp/java25.tar.gz"
        echo "  OpenJDK 25 downloaded"
    else
        echo "  Java 25 not available, trying Java 21..."
        local jdk21_url="https://github.com/adoptium/temurin21-binaries/releases/latest/download/OpenJDK21U-jdk_aarch64_mac_hotspot_*.tar.gz"
        # Note: This is macOS, not iOS - need iOS-specific build
        echo "  WARNING: Need iOS-specific OpenJDK build"
    fi
}

# SPIRV-Cross (for Minecraft 26.2+ shaders)
download_spirv_cross() {
    echo "Downloading SPIRV-Cross..."
    local spvc_url="https://github.com/FlameLaunchers/FlameLauncher-SDL3/releases/download/spirv-cross-v2024.1/libspirv-cross-ios-arm64.dylib"
    curl -L -o "$NATIVES_DIR/libspirv-cross.dylib" "$spvc_url" 2>/dev/null || echo "  SPIRV-Cross not found (optional)"
}

# Shaderc (for Minecraft 26.3+ runtime shader compilation)
download_shaderc() {
    echo "Downloading shaderc..."
    local shaderc_url="https://github.com/FlameLaunchers/FlameLauncher-SDL3/releases/download/shaderc-v2024.1/libshaderc-ios-arm64.dylib"
    curl -L -o "$NATIVES_DIR/libshaderc.dylib" "$shaderc_url" 2>/dev/null || echo "  shaderc not found (optional, for 26.3+)"
}

# Main
download_sdl3
download_lwjgl
download_mobileglues
download_openjdk
download_spirv_cross
download_shaderc

echo ""
echo "=== Download complete ==="
echo "Natives directory: $NATIVES_DIR"
ls -la "$NATIVES_DIR"

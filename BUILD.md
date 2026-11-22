# Build Instructions

## Prerequisites

### macOS (Required for Building)

| Tool | Install Command |
|---|---|
| Xcode 16+ | App Store |
| Homebrew | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` |
| CMake, Ninja | `brew install cmake ninja` |

### Linux (For Testing/Sideload Only)

Building the iOS app **requires macOS**. Linux can only be used for:
- Sideload installation (after building on Mac)
- JIT enabling (SideJITServer)
- Development/testing of non-iOS code

```bash
# Arch Linux
sudo pacman -S libimobiledevice usbmuxd avahi python-pip
pip3 install pymobiledevice3 --break-system-packages
yay -S sidejitserver-git
```

---

## Step-by-Step Build (macOS)

### 1. Clone and Setup

```bash
git clone https://github.com/dijakonal/mc-ios-launcher.git
cd mc-ios-launcher

# Create build directory
mkdir -p build
```

### 2. Download Prebuilt Natives

```bash
./Scripts/download-natives.sh
```

This downloads:
- **SDL3** (libSDL3.dylib) — Windowing, input, events
- **LWJGL 3.4.3** — Java game library bindings
- **OpenJDK 25** — Java runtime for iOS arm64
- **MobileGlues** — OpenGL to GLES translator
- **SPIRV-Cross** — Shader compiler (26.2+)
- **shaderc** — Runtime shader compilation (26.3+)

Expected output:
```
=== MC iOS Launcher - Native Downloader ===
Downloading SDL3...
  SDL3 downloaded (2.4M)
Downloading LWJGL 3.4.3...
  LWJGL downloaded (15M)
...
=== Download complete ===
```

### 3. Configure Codesigning

Edit `Resources/MCiOSLauncher.entitlements`:

```xml
<!-- Replace with your Apple Developer Team ID -->
<key>com.apple.developer.team-identifier</key>
<string>YOUR_TEAM_ID</string>
```

To find your Team ID:
1. Visit https://developer.apple.com/account
2. Look under "Membership" — Team ID is shown there

Or in Xcode:
1. Open project in Xcode
2. Select project → Signing & Capabilities
3. Team dropdown shows your Team ID

### 4. Build the Java Launcher

```bash
cd JavaApp

# Compile Java sources
mkdir -p build/classes
find src -name "*.java" > sources.txt
javac -d build/classes @sources.txt
rm sources.txt

# Create launcher JAR
cd build/classes
jar cf ../../Natives/launcher.jar com/
cd ../..
```

### 5. Build the Native Bridge

```bash
# Compile JNI bridge
clang -framework Foundation -framework JavaNativeFoundation \
    -dynamiclib Natives/JNIBridge.m \
    -o Natives/libjnibridge.dylib \
    -arch arm64 \
    -isysroot $(xcrun --show-sdk-path -sdk iphoneos) \
    -miphoneos-version-min=17.0
```

### 6. Build the iOS App (Xcode)

```bash
# Open in Xcode
open MCiOSLauncher.xcodeproj

# In Xcode:
# 1. Select your development team (Xcode → Preferences → Accounts)
# 2. Select your target device
# 3. Product → Archive
# 4. Distribute App → Development → Export
```

**Or via command line:**

```bash
xcodebuild \
    -project MCiOSLauncher.xcodeproj \
    -scheme MCiOSLauncher \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    archive \
    -archivePath build/MCiOSLauncher.xcarchive

# Export IPA
xcodebuild \
    -exportArchive \
    -archivePath build/MCiOSLauncher.xcarchive \
    -exportPath build/ipa \
    -exportOptionsPlist Scripts/export-options.plist
```

### 7. Verify Build

```bash
ls -lh build/ipa/MCiOSLauncher.ipa
# Should be ~200-250MB

# Check contents
unzip -l build/ipa/MCiOSLauncher.ipa | head -30
```

---

## Build Output

| File | Size | Purpose |
|---|---|---|
| `build/ipa/MCiOSLauncher.ipa` | ~220MB | Installable iOS app |
| `Natives/launcher.jar` | ~50KB | Java bootstrap |
| `Natives/libjnibridge.dylib` | ~20KB | Swift-JNI bridge |

---

## CI/CD (GitHub Actions)

Automated builds via GitHub Actions (requires macOS runner):

```yaml
# .github/workflows/build.yml
name: Build iOS App

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      
      - name: Download Natives
        run: ./Scripts/download-natives.sh
      
      - name: Build App
        run: ./Scripts/build-app.sh
      
      - name: Upload IPA
        uses: actions/upload-artifact@v4
        with:
          name: MCiOSLauncher
          path: build/ipa/MCiOSLauncher.ipa
```

---

## Build Troubleshooting

### "Xcode not found"

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

### "Codesign failed"

- Check your Team ID is correct in entitlements
- Make sure you're logged into Xcode with your Apple ID
- Try: `security unlock-keychain`

### "Native library not found"

- Verify `download-natives.sh` completed successfully
- Check `Natives/` directory has all required `.dylib` files
- Run `lipo -info Natives/SDL3/libSDL3.dylib` — should report `arm64`

### "Java compilation failed"

```bash
# Check Java version
java -version
javac -version

# Should be Java 17+ for MC 26.3
```

---

## After Building

1. **Install on device** — See [INSTALL.md](INSTALL.md)
2. **Enable JIT** — Required for Java to run
3. **Test launch** — Start with Minecraft 1.21.1 (more stable)
4. **Debug if needed** — Check Xcode console for errors

For prebuilt IPAs (no building required), see [ALTERNATIVES.md](ALTERNATIVES.md).

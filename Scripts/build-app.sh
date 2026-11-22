#!/bin/bash
#
# build-app.sh
# Builds the MC iOS Launcher app
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== MC iOS Launcher - Build ==="

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "ERROR: Xcode not found. This script must run on macOS with Xcode installed."
    exit 1
fi

# Configuration
SCHEME="MCiOSLauncher"
CONFIGURATION="Release"
DESTINATION="generic/platform=iOS"

# Build Java launcher
echo "Building Java launcher..."
JAVA_APP_DIR="$PROJECT_DIR/JavaApp"
JAVA_OUT="$PROJECT_DIR/Natives/launcher.jar"

cd "$JAVA_APP_DIR"
mkdir -p build/classes

# Compile Java sources
find src -name "*.java" > sources.txt
javac -d build/classes @sources.txt
rm sources.txt

# Create launcher JAR
cd build/classes
jar cf "$JAVA_OUT" com/
cd "$PROJECT_DIR"

echo "  launcher.jar built"

# Build native bridge
echo "Building native bridge..."
NATIVES_DIR="$PROJECT_DIR/Natives"

clang -framework Foundation -framework JavaNativeFoundation \
    -dynamiclib "$NATIVES_DIR/JNIBridge.m" \
    -o "$NATIVES_DIR/libjnibridge.dylib" \
    -arch arm64 \
    -isysroot "$(xcrun --show-sdk-path -sdk iphoneos)" \
    -miphoneos-version-min=17.0

echo "  libjnibridge.dylib built"

# Build Xcode project
echo "Building iOS app..."

# Create Xcode project if it doesn't exist
if [ ! -f "$PROJECT_DIR/MCiOSLauncher.xcodeproj/project.pbxproj" ]; then
    echo "Creating Xcode project..."
    create_xcode_project
fi

cd "$PROJECT_DIR"

xcodebuild \
    -project MCiOSLauncher.xcodeproj \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "$DESTINATION" \
    -derivedDataPath build/DerivedData \
    archive \
    -archivePath build/archives/MCiOSLauncher.xcarchive

# Export IPA
echo "Exporting IPA..."

# Create export options plist
cat > build/export-options.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <false/>
    <key>signingStyle</key>
    <string>manual</string>
</dict>
</plist>
EOF

xcodebuild \
    -exportArchive \
    -archivePath build/archives/MCiOSLauncher.xcarchive \
    -exportPath build/ipa \
    -exportOptionsPlist build/export-options.plist

echo ""
echo "=== Build complete ==="
echo "IPA location: $PROJECT_DIR/build/ipa/MCiOSLauncher.ipa"

# Helper function to create Xcode project
create_xcode_project() {
    mkdir -p "$PROJECT_DIR/MCiOSLauncher.xcodeproj"
    
    # Minimal project.pbxproj - in production, use Xcode to create properly
    cat > "$PROJECT_DIR/MCiOSLauncher.xcodeproj/project.pbxproj" << 'PBXPROJ'
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {
		/* Begin PBXBuildFile section */
		/* End PBXBuildFile section */
		/* Begin PBXFileReference section */
		/* End PBXFileReference section */
		/* Begin PBXGroup section */
		/* End PBXGroup section */
		/* Begin PBXNativeTarget section */
		/* End PBXNativeTarget section */
		/* Begin PBXProject section */
		/* End PBXProject section */
	};
	rootObject = "";
}
PBXPROJ
    
    echo "  Xcode project created (edit in Xcode for full configuration)"
}

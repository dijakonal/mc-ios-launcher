# Installation Guide

## From Linux (After Building)

If you have a `.ipa` file (built on Mac or obtained elsewhere), here's how to install and run it from Linux.

### Prerequisites on Arch Linux

```bash
# Core iOS tools
sudo pacman -S libimobiledevice usbmuxd avahi

# Start required services
sudo systemctl enable --now usbmuxd avahi-daemon

# JIT enabling (network-based)
yay -S sidejitserver-git

# Python tools (alternative method)
sudo pacman -S python-pip
pip3 install pymobiledevice3 --break-system-packages
```

### Step 1: Pair Your iPhone

```bash
# Unlock your iPhone and keep it on the home screen
# You should see "Trust This Computer?" — tap "Trust" and enter passcode

# Pair the device
idevicepair pair

# Verify connection
ideviceinfo | grep ProductVersion
```

### Step 2: Install the IPA

**Method A: ideviceinstaller**

```bash
# Install IPA
ideviceinstaller -i MCiOSLauncher.ipa

# Verify installation
ideviceinstaller -l | grep -i mc

# Uninstall if needed
ideviceinstaller -u com.mcioslauncher.app
```

**Method B: pymobiledevice3**

```bash
export PATH="$PATH:$HOME/.local/bin"

# Install
pymobiledevice3 installation install MCiOSLauncher.ipa

# List installed apps
pymobiledevice3 installation list
```

**Method C: AltServer-Linux** (if above fail)

```bash
git clone https://github.com/NyaMisty/AltServer-Linux.git
cd AltServer-Linux
pip3 install -r requirements.txt

# Run server
python3 altserver.py --apple-id your@email.com --password your-app-specific-password

# Then visit http://localhost:53841 in browser and upload the IPA
```

### Step 3: Enable JIT

**Option A: SideJITServer (Recommended for Linux)**

```bash
# Run SideJITServer on your Linux machine
sidejitserver

# On your iPhone:
# 1. Settings → Wi-Fi
# 2. Tap the (i) next to your network
# 3. Set your Linux machine's IP as the "SideJITServer"
# 4. JIT will enable automatically when the app launches
```

**Option B: StikDebug**

```bash
# Install StikDebug IPA on your iPhone (via SideStore)
# Create a pairing file (requires computer once)
# In StikDebug: Load pairing file, enable JIT for MC iOS Launcher
```

**Option C: TrollStore** (iOS 17.0 and below only)

```bash
# If you have TrollStore installed:
# 1. Open TrollStore
# 2. Tap "+" and select MCiOSLauncher.ipa
# 3. JIT is permanently enabled (no computer needed)
```

### Step 4: Launch and Play

1. Open **MC iOS Launcher** on your iPhone
2. If using SideJITServer, JIT enables automatically
3. Sign in with Microsoft account
4. Download Minecraft version (26.3 for latest)
5. Create/select a profile
6. Tap **Launch**

---

## From macOS (Build + Install)

### Build the IPA

```bash
cd ~/Projects/mc-ios-launcher

# Download prebuilt natives
./Scripts/download-natives.sh

# Build the app
./Scripts/build-app.sh

# Output: build/ipa/MCiOSLauncher.ipa
```

### Install to Device

**Via Xcode:**

1. Open `MCiOSLauncher.xcodeproj` in Xcode
2. Select your device from the device list
3. Product → Run (or press ⌘R)

**Via command line:**

```bash
# Get device UDID
xcrun devicectl list devices

# Install
xcrun devicectl device install app \
  --device <DEVICE-UDID> \
  build/ipa/MCiOSLauncher.ipa
```

---

## Troubleshooting

### "No device found"

- Unlock your iPhone
- Make sure you tapped "Trust" on the popup
- Try: `idevicepair unpair && idevicepair pair`
- Restart usbmuxd: `sudo systemctl restart usbmuxd`

### "JIT is required"

- Verify SideJITServer is running on your Linux machine
- Check iPhone Wi-Fi settings — SideJITServer IP is configured
- Try launching the app again (JIT enables on launch)

### App crashes immediately

- Check JIT is actually enabled (open StikDebug/SideJITServer to verify)
- Try an older Minecraft version (1.21.1 is more stable than 26.3)
- Lower render distance and Java memory in settings

### Installation fails

- Make sure the IPA is signed with your Apple ID
- Try reinstalling: `ideviceinstaller -u com.mcioslauncher.app && ideviceinstaller -i MCiOSLauncher.ipa`
- Check free space on device (need at least 3GB)

---

## Next Steps

After installation:

1. **Configure JIT** — See [JIT.md](JIT.md) for detailed JIT setup
2. **Sign in** — Microsoft account required for Minecraft authentication
3. **Download version** — First download takes 5-15 minutes
4. **Play!** — See [GAMEPLAY.md](GAMEPLAY.md) for tips

For prebuilt alternatives (if you don't want to build), see [ALTERNATIVES.md](ALTERNATIVES.md).

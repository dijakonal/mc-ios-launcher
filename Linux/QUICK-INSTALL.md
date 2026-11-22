# Quick Install Guide - FlameLauncher from Linux

## The Problem

Prebuilt IPAs (like FlameLauncher) are signed with the developer's certificate. iOS **rejects** these unless they're resigned with **your** Apple ID.

## Solution: SideStore (Wireless, No Computer After Setup)

This is the **most reliable method** from Linux.

### Step 1: On Your iPhone (Safari)

1. Open **Safari** (not Chrome/Firefox)
2. Visit: **https://sidestore.io**
3. Tap **"Get Started"**
4. Follow the on-screen instructions

### Step 2: Wireless Pairing (One Time)

SideStore will guide you through:

1. **Download pairing file** from a computer (you're on Linux, this works)
2. **Load pairing file** into SideStore on iPhone
3. **Enable LocalDevVPN** (iOS Settings → VPN)

### Step 3: Install FlameLauncher

Once SideStore is set up:

1. Download FlameLauncher.ipa to your computer
2. Transfer to iPhone (AirDrop, iCloud Drive, or download directly on iPhone)
3. Open SideStore → Browse → "+" → Select FlameLauncher.ipa
4. Tap **Install**

### Step 4: Enable JIT

**Option A: StikDebug** (Recommended)

1. Install StikDebug IPA via SideStore
2. Create pairing file (computer needed once)
3. Enable JIT for FlameLauncher

**Option B: SideJITServer** (From your Linux machine)

```bash
# On your Arch Linux machine:
yay -S sidejitserver-git

# Run it:
sidejitserver

# On iPhone:
# Settings → Wi-Fi → Tap (i) next to your network
# Set SideJITServer to your Linux machine's IP
```

---

## Alternative: AltServer-Linux (If You Have Apple ID Credentials)

```bash
# Install dependencies
sudo pacman -S boost cpprestsdk libzip

# Build AltServer-Linux
cd /tmp
git clone --recursive https://github.com/NyaMisty/AltServer-Linux.git
cd AltServer-Linux
make -f Makefile -j$(nproc)

# Install IPA
./AltServer-Linux \
  -u YOUR-DEVICE-UDID \
  -a your@email.com \
  -p your-app-specific-password \
  FlameLauncher.ipa
```

**Note:** You need an **app-specific password**, not your regular Apple ID password.
Get it at: https://appleid.apple.com/account/manage

---

## Get Your Device UDID

```bash
ideviceinfo | grep UniqueDeviceID
# Output: UniqueDeviceID: 00008101-0001381C1E00801E
```

---

## Troubleshooting

### "ApplicationVerificationFailed"

The IPA wasn't signed with your certificate. Use SideStore or AltServer-Linux to resign it.

### "JIT is required"

Install StikDebug or run SideJITServer on your Linux machine.

### "No device found"

- Unlock iPhone
- Trust this computer (if prompted)
- Run: `idevicepair pair`

---

## Quick Commands Reference

```bash
# Check device connection
ideviceinfo | grep ProductVersion

# Pair device
idevicepair pair

# List installed apps
ideviceinstaller -l

# Install IPA (if properly signed)
ideviceinstaller -i FlameLauncher.ipa

# Uninstall app
ideviceinstaller -u kr.co.donghyun.flamelauncher

# Run SideJITServer
sidejitserver
```

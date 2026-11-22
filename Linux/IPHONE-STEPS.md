# iPhone Setup Steps - Do This On Your Phone

Follow these steps **on your iPhone** to install FlameLauncher.

---

## Part 1: Install SideStore (5 minutes)

### Step 1: Open Safari

**Important:** Use **Safari**, not Chrome or Firefox.

1. Open **Safari** on your iPhone
2. Go to: **https://sidestore.io**

### Step 2: Start Installation

1. Tap **"Get Started"** or **"Install"**
2. You'll see a popup asking to download a profile
3. Tap **"Allow"**

### Step 3: Install Profile

1. Open **Settings** app
2. At the top, you'll see **"Profile Downloaded"**
3. Tap it
4. Tap **"Install"** (top right)
5. Enter your iPhone passcode
6. Tap **"Install"** again
7. Tap **"Done"**

### Step 4: Open SideStore

1. Find **SideStore** on your home screen
2. Open it
3. Tap **"Begin"**

### Step 5: Wireless Pairing

SideStore needs a pairing file. You have two options:

**Option A: Use Your Linux Computer**

```bash
# On your Arch Linux machine:
mkdir -p ~/sidepair
cd ~/sidepair

# Download the pairing script
curl -LO https://github.com/SideStore/Pairing-Data/releases/latest/download/pairing-data.json

# Actually, SideStore will guide you through this
# Visit on iPhone Safari: https://sidestore.io/pair
```

**Option B: Do It All On iPhone (Easier)**

1. In SideStore, tap **"Pairing File"**
2. Tap **"Create Pairing File"**
3. Follow the on-screen instructions
4. This may require connecting to a computer once

### Step 6: Enable LocalDevVPN

1. In SideStore, tap **"Setup LocalDevVPN"**
2. Go to **Settings → General → VPN & Device Management**
3. Enable the VPN profile
4. Return to SideStore

---

## Part 2: Install FlameLauncher (3 minutes)

### Step 1: Download FlameLauncher IPA

**On your iPhone:**

1. Open **Safari**
2. Go to: https://github.com/FlameLaunchers/FlameLauncher-iOS/releases/download/v1.6.7/FlameLauncher.ipa
3. Tap **"Download"**
4. Wait for download to complete (~206 MB)

### Step 2: Import to SideStore

1. Open **Files** app
2. Go to **Downloads**
3. Find **FlameLauncher.ipa**
4. Long-press on it
5. Tap **"Share"**
6. Scroll and tap **"SideStore"**

**OR:**

1. Open **SideStore**
2. Tap the **"+"** button (top right)
3. Navigate to **Downloads → FlameLauncher.ipa**
4. Tap it

### Step 3: Install

1. SideStore will show FlameLauncher
2. Tap **"Install"**
3. Wait for installation to complete
4. You'll see FlameLauncher on your home screen

---

## Part 3: Enable JIT (2 minutes)

### Option A: StikDebug (Recommended)

1. **Download StikDebug:**
   - In SideStore, tap **"Browse"**
   - Search for **"StikDebug"**
   - Tap **"Install"**

2. **Create Pairing File (one time):**
   - Connect iPhone to computer via USB
   - Follow StikDebug's instructions to create pairing file
   - OR use https://sidestore.io/pair on iPhone

3. **Enable JIT:**
   - Open **StikDebug**
   - Tap **"Enable JIT"**
   - Select **FlameLauncher**
   - JIT is now enabled!

### Option B: SideJITServer (From Linux)

1. **On your Linux machine:**
   ```bash
   yay -S sidejitserver-git
   sidejitserver
   ```

2. **On your iPhone:**
   - Go to **Settings → Wi-Fi**
   - Tap the **(i)** next to your network
   - Scroll down to **"SideJITServer"**
   - Enter your Linux machine's IP address
   - Save

3. **JIT enables automatically** when you open FlameLauncher

---

## Part 4: Play Minecraft

1. **Open FlameLauncher** on your iPhone
2. **Sign in** with Microsoft account (the one that owns Minecraft)
3. **Download** Minecraft 26.3 (first time: 5-15 minutes)
4. **Create a profile** or use default
5. Tap **"Play"**

---

## Troubleshooting

### "JIT is required" message

- Open StikDebug and enable JIT for FlameLauncher
- OR make sure SideJITServer is running on your Linux machine

### App crashes immediately

- JIT is not enabled - see above
- Try closing and reopening the app

### Can't download IPA on iPhone

- Download on computer, transfer via AirDrop or iCloud Drive
- Or use a different browser on iPhone

### SideStore won't install

- Make sure you're using Safari
- Check iOS version (needs iOS 15+)
- Try the alternative: https://altstore.io

---

## Quick Reference

| What | Where |
|---|---|
| SideStore | https://sidestore.io |
| FlameLauncher IPA | GitHub Releases (206 MB) |
| StikDebug | In SideStore Browse |
| SideJITServer | `yay -S sidejitserver-git` |

---

## After Setup

- **Refresh every 7 days** (free Apple ID limitation)
  - Open SideStore → tap **"Refresh All"**
- **JIT persists** until you reboot or the app closes
- **Updates:** Download new IPA, import to SideStore again

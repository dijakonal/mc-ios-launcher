# Prebuilt Alternatives

If you don't want to build from source (or don't have a Mac), these prebuilt launchers work on iOS:

---

## FlameLauncher iOS ⭐ (Recommended)

**Best for:** Latest Minecraft (26.3), shaders, mods, active development

| Feature | Status |
|---|---|
| Minecraft 26.3 | ✅ Fully supported |
| Fabric/Forge/NeoForge | ✅ |
| Iris Shaders | ✅ |
| Online LAN | ✅ |
| JIT Support | StikDebug, SideJITServer, TrollStore |
| Last Updated | October 2026 |

**Download:** https://github.com/FlameLaunchers/FlameLauncher-iOS/releases

**Latest:** v1.6.7 (206 MB) — Includes FlameJIT helper app

**Why choose this:**
- Most up-to-date (runs 26.3 with shaders)
- Active development
- Prebuilt IPA (no Mac needed)
- Works with Linux sideloading

**Install from Linux:**
```bash
wget https://github.com/FlameLaunchers/FlameLauncher-iOS/releases/download/v1.6.7/FlameLauncher.ipa
ideviceinstaller -i FlameLauncher.ipa
sidejitserver  # For JIT
```

---

## Amethyst iOS

**Best for:** Stability, older versions, PojavLauncher fork

| Feature | Status |
|---|---|
| Minecraft 26.3 | ⚠️ Partial (see notes) |
| Fabric/Forge | ✅ |
| Iris Shaders | ⚠️ Limited |
| Last Updated | November 2026 |

**Download:** https://github.com/AngelAuraMC/Amethyst-iOS/releases

**Notes:**
- Successor to PojavLauncher iOS
- 26.1-26.2 work, 26.3 has issues (LWJGL version mismatch)
- More stable for older versions (1.21.x and below)

---

## PojavLauncher iOS (Archived)

**Best for:** Historical interest only — **discontinued**

| Feature | Status |
|---|---|
| Minecraft 26.x | ❌ Not supported |
| Max Version | 1.20.x |
| Status | Archived (Sept 2025) |

**Repository:** https://github.com/PojavLauncherTeam/PojavLauncher_iOS (archived)

**Don't use this** — it's discontinued and doesn't support modern Minecraft versions.

---

## Comparison Table

| Launcher | 26.3 | Shaders | Mods | JIT Methods | IPA Size |
|---|---|---|---|---|---|
| **FlameLauncher** | ✅ | ✅ | ✅ | All | 206 MB |
| **Amethyst** | ⚠️ | ⚠️ | ✅ | All | 210 MB |
| **PojavLauncher** | ❌ | ❌ | ✅ | Limited | 180 MB |
| **MC iOS Launcher** (this repo) | ✅* | 🚧 | ✅ | All | ~220 MB |

*After building from source

---

## Which Should You Use?

| Your Situation | Recommendation |
|---|---|
| Want latest MC (26.3) + shaders | **FlameLauncher** |
| Playing on older version (1.21.x) | **Amethyst** or **FlameLauncher** |
| Want to modify/extend launcher | **This repo** (build from source) |
| Don't have Mac | **FlameLauncher** (prebuilt) |
| iOS 17.0 or below | Any + **TrollStore** |
| iOS 17.4+ | Any + **StikDebug/SideJITServer** |

---

## Install Any IPA from Linux

All of these can be installed from Arch Linux:

```bash
# 1. Download IPA
wget <IPA_URL> -O launcher.ipa

# 2. Pair iPhone (unlock and trust first)
idevicepair pair

# 3. Install
ideviceinstaller -i launcher.ipa

# 4. Enable JIT
sidejitserver

# 5. Launch on iPhone
```

---

## JIT Methods Compared

| Method | iOS Version | Computer Needed | Auto-Enable |
|---|---|---|---|
| **TrollStore** | ≤17.0 | Once (install) | ✅ Yes |
| **StikDebug** | 17.4+ | Once (pairing file) | ✅ Yes |
| **SideJITServer** | 17.0-17.3 | Always (same network) | ✅ Yes |
| **AltStore** | Any | Every 7 days (refresh) | ⚠️ With AltServer running |

**For Linux users:** SideJITServer is the most convenient — runs as a daemon, enables JIT automatically.

```bash
# Install SideJITServer on Arch
yay -S sidejitserver-git

# Run it
sidejitserver

# Configure iPhone Wi-Fi to point to your Linux IP
# JIT enables automatically when app launches
```

---

## Links

- FlameLauncher: https://github.com/FlameLaunchers/FlameLauncher-iOS
- FlameLauncher-SDL3 (natives): https://github.com/FlameLaunchers/FlameLauncher-SDL3
- Amethyst: https://github.com/AngelAuraMC/Amethyst-iOS
- StikDebug: https://github.com/StephenDev0/StikDebug
- SideJITServer: https://github.com/nythepegasus/SideJITServer

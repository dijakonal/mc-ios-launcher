# MC iOS Launcher

**Run Minecraft: Java Edition on iPhone/iPad — written from scratch.**

This is a complete iOS launcher for Minecraft: Java Edition (including 26.3). The launcher code is original — we use prebuilt binaries only for the heavy native dependencies (SDL3, LWJGL, OpenJDK).

[![iOS](https://img.shields.io/badge/iOS-17.0+-black?logo=apple)](#)
[![Minecraft](https://img.shields.io/badge/minecraft-26.3-green)](#)
[![License](https://img.shields.io/badge/license-AGPL--3.0-blue)](LICENSE)

## What This Is

| Component | Status |
|---|---|
| Swift iOS app (UI, JIT, auth) | ✅ Written from scratch |
| Java launcher bootstrap | ✅ Written from scratch |
| JNI native bridge | ✅ Written from scratch |
| Microsoft OAuth2 flow | ✅ Written from scratch |
| SDL3, LWJGL, OpenJDK | ⚠️ Prebuilt binaries |

## Quick Start

### If You Have a Mac

```bash
# 1. Download prebuilt natives
./Scripts/download-natives.sh

# 2. Build the iOS app
./Scripts/build-app.sh

# 3. Sideload to your device (see INSTALL.md)
```

### If You Don't Have a Mac

You have two options:

1. **Use a prebuilt IPA** (like FlameLauncher) — see [ALTERNATIVES.md](ALTERNATIVES.md)
2. **Find someone with a Mac** to build this repo, then sideload from Linux

## Features

- ✅ **Full version support** — Minecraft 1.7 through 26.3 (latest)
- ✅ **Mod loaders** — Fabric, Forge, NeoForge, Quilt
- ✅ **Microsoft auth** — Official OAuth2 login flow
- ✅ **JIT enabling** — StikDebug, SideJITServer, AltStore, TrollStore
- ✅ **Profile system** — Multiple configs with renderer/memory settings
- ✅ **Mod support** — Modrinth and CurseForge integration
- ✅ **Online LAN** — Play with friends over the internet

## Requirements

### For Building

| Requirement | Why |
|---|---|
| macOS 14+ with Xcode 16+ | Required to compile Swift and export IPA |
| Apple ID (free works) | For codesigning (7-day cert) |
| 5GB free disk space | For natives, Java, and build artifacts |

### For Running

| Requirement | Why |
|---|---|
| iPhone XS or later (iOS 17+) | A12+ chip recommended for Java performance |
| 3GB free storage | Game files, assets, Java runtime |
| JIT enabled | Required for Java JIT compilation |
| Minecraft: Java Edition account | Microsoft account with active license |

## Project Structure

```
mc-ios-launcher/
├── App/                      # Swift iOS application
│   ├── MCiOSLauncherApp.swift
│   ├── ContentView.swift     # Main launcher UI
│   ├── JITManager.swift      # JIT enabling (StikDebug, etc.)
│   ├── LauncherViewModel.swift
│   ├── MicrosoftAuth.swift   # OAuth2 → Xbox → Minecraft
│   ├── VersionManifest.swift # Mojang API client
│   ├── SignInView.swift
│   ├── ProfilesView.swift
│   └── SettingsView.swift
│
├── JavaApp/                  # Java launcher (runs inside JVM)
│   └── src/main/java/.../JavaLauncher.java
│
├── Natives/
│   ├── JNIBridge.m          # Swift ↔ Java JNI bridge
│   ├── SDL3/                # Prebuilt SDL3 iOS arm64
│   ├── LWJGL/               # Prebuilt LWJGL 3.4.3 iOS arm64
│   └── OpenJDK/             # Prebuilt OpenJDK 25 iOS arm64
│
├── Resources/
│   ├── Info.plist           # App configuration
│   └── MCiOSLauncher.entitlements
│
├── Scripts/
│   ├── download-natives.sh  # Fetch prebuilt binaries
│   └── build-app.sh         # Build iOS app (needs macOS)
│
├── Linux/                   # Linux sideloading tools
│   ├── install.sh           # Install IPA from Linux
│   └── sidejitserver.service
│
├── README.md                # This file
├── BUILD.md                 # Detailed build instructions
├── INSTALL.md               # Installation & JIT guide
├── ALTERNATIVES.md          # Prebuilt alternatives
└── LICENSE                  # AGPL-3.0
```

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                     MC iOS Launcher                          │
├─────────────────────────────────────────────────────────────┤
│  Swift App (iOS)                                            │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐   │
│  │   UI        │  │  JIT Mgr     │  │  Microsoft Auth │   │
│  │  (SwiftUI)  │  │  (StikDebug) │  │  (OAuth2)       │   │
│  └──────┬──────┘  └──────┬───────┘  └────────┬────────┘   │
│         │                │                    │             │
│         └────────────────┼────────────────────┘             │
│                          │                                  │
│                    ┌─────▼─────┐                           │
│                    │  JNI      │                           │
│                    │  Bridge   │                           │
│                    └─────┬─────┘                           │
├──────────────────────────┼─────────────────────────────────┤
│                    Java VM (OpenJDK 25)                     │
│                          │                                  │
│              ┌───────────▼───────────┐                     │
│              │   JavaLauncher.java   │                     │
│              │  - Classpath builder  │                     │
│              │  - Native loader      │                     │
│              │  - Minecraft bootstrap│                     │
│              └───────────┬───────────┘                     │
├──────────────────────────┼─────────────────────────────────┤
│                    Native Libraries                         │
│    ┌────────┐  ┌────────┐  ┌────────┐  ┌────────────┐     │
│    │  SDL3  │  │ LWJGL  │  │  GL    │  │  OpenJDK   │     │
│    │  3.4.16│  │ 3.4.3  │  │  GLES  │  │    25      │     │
│    └────────┘  └────────┘  └────────┘  └────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

## License

**AGPL-3.0** — The launcher code is original, but links to AGPL components.

| Component | License |
|---|---|
| This launcher | AGPL-3.0 |
| SDL3 | Zlib |
| LWJGL | BSD-3 |
| OpenJDK | GPL-2 + Classpath Exception |
| MobileGlues | LGPL-2.1 |

## Acknowledgments

This project stands on the shoulders of giants:

- [PojavLauncher](https://github.com/PojavLauncherTeam/PojavLauncher) — Original iOS Java launcher
- [Amethyst](https://github.com/AngelAuraMC/Amethyst-iOS) — PojavLauncher successor
- [FlameLauncher](https://github.com/FlameLaunchers/FlameLauncher-iOS) — LWJGL 3.4.3 + SDL3 iOS builds
- [libsdl-org/SDL](https://github.com/libsdl-org/SDL) — SDL3 windowing/input
- [LWJGL](https://github.com/LWJGL/lwjgl3) — Java game library bindings

Minecraft is a trademark of Mojang AB. This project is not affiliated with Mojang or Microsoft.

## Contributing

Contributions welcome! Areas needing work:

- [ ] Shader support (Iris integration)
- [ ] Controller mapping UI
- [ ] Modpack browser
- [ ] Performance optimizations for A12-A14 chips

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

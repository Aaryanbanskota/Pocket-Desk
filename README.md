<div align="center">

<img src="./assets/repobanner.png" alt="PocketDesk Banner" width="100%" />

# PocketDesk

**Your offline-first, privacy-respecting productivity ecosystem.**

*Plan • Track • Focus*

<br>

[![Flutter](https://img.shields.io/badge/Flutter-3.22.2-blue?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-API%2024%2B-green?logo=android&logoColor=white)](https://developer.android.com)
[![Linux](https://img.shields.io/badge/Linux-Desktop-orange?logo=linux&logoColor=white)](https://flutter.dev/desktop)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/Aaryanbanskota/Pocket-Desk)](https://github.com/Aaryanbanskota/Pocket-Desk/releases)
[![Stars](https://img.shields.io/github/stars/Aaryanbanskota/Pocket-Desk?style=social)](https://github.com/Aaryanbanskota/Pocket-Desk/stargazers)

<br>

[📥 Android](#-android-downloads) ·
[🐧 Linux](#-linux-desktop-downloads) ·
[✨ Features](#-features) ·
[🏗 Architecture](#-architecture) ·
[🚀 Quick Start](#-quick-start-development) ·
[🤝 Contributing](#-contributing)

</div>

---

## 📖 About

**PocketDesk** is a production-quality, offline-first productivity hub built with Flutter.  
It combines a full-featured **Calendar**, **Task Manager**, **Notes** app, and **Schedule Planner** into a single, beautifully designed application — without requiring a cloud account or internet connection.

> **You own your data. Everything works offline. Internet is only used for device-to-device synchronization.**

### Platform Support

| Platform | Status |
|:---------|:-------|
| <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/android/android-original.svg" width="18" height="18" alt="Android"/> **Android** (API 24+) | ✅ Supported |
| <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/linux/linux-original.svg" width="18" height="18" alt="Linux"/> **Linux / Ubuntu** | ✅ Supported |
| <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/windows8/windows8-original.svg" width="18" height="18" alt="Windows"/> **Windows** | 🔜 Planned |
| <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/apple/apple-original.svg" width="18" height="18" alt="macOS"/> **macOS** | 🔜 Planned |

---

## 📥 Downloads & Releases

### 🤖 Android Downloads

<div align="center">
  <img src="./assets/apk-banner.png" alt="Android APK Banner" width="100%" />
</div>

| Build Type | Download | Size |
|:-----------|:---------|:-----|
| **Release APK** | [📥 Download APK](https://github.com/Aaryanbanskota/Pocket-Desk/raw/main/all-apk/app-release.apk) | ~78 MB |
| **App Bundle (AAB)** | [📦 Download AAB](https://github.com/Aaryanbanskota/Pocket-Desk/raw/main/all-apk/app-release.apk)) | ~36 MB |

> **Tip:** Prefer the AAB for Google Play / modern installers. Use the APK for sideloading.

### 🐧 Linux Desktop Downloads

<div align="center">
  <img src="./assets/1linux-banner.png" alt="Linux Desktop Banner" width="100%" />
</div>

| Platform | Download | Size |
|:---------|:---------|:-----|
| **Linux x64** | [🐧 Download tar.gz](https://github.com/Aaryanbanskota/Pocket-Desk/blob/main/pocketdesk-linux-x64.tar.gz) | ~15 MB |

#### Linux Installation

```bash
# 1. Download & extract
tar -xzf pocketdesk-linux-x64.tar.gz
cd bundle

# 2. Install system dependencies
# Ubuntu / Debian
sudo apt-get update && sudo apt-get install -y \
  clang cmake ninja-build pkg-config libgtk-3-dev libsecret-1-dev

# Fedora
sudo dnf install clang cmake ninja-build pkgconfig gtk3-devel libsecret-devel

# 3. Run
./pocketdesk
```

---

## ✨ Features

<table>
<tr>
<td width="50%" valign="top">

### 📅 Calendar
- Day / Week / Month / Year / Agenda views
- Recurring events (full RFC 5545 support)
- Multiple color-coded calendars
- Multiple reminders per event
- ICS Import & Export
- Time-zone aware & fully offline

</td>
<td width="50%" valign="top">

### ✅ Task Manager
- Lists, Folders & Categories
- Priority levels (Urgent → Low)
- Nested subtasks with progress tracking
- Recurring tasks + due dates + reminders
- Swipe-to-complete / swipe-to-delete
- Archive history

</td>
</tr>
<tr>
<td width="50%" valign="top">

### 📝 Notes
- Rich text & Markdown editor
- Checklists & image attachments
- Pin, favorite, folders & tags
- Full-text search
- Sticky-note grid layout

</td>
<td width="50%" valign="top">

### 🔄 Device-to-Device Sync
- Encrypted WebSocket (AES-GCM-128)
- QR Code pairing — **no accounts**
- HMAC-SHA256 signed tokens
- Delta synchronization
- Offline queue with auto-resume

</td>
</tr>
</table>

### 🔐 Privacy & Security

- Local authentication with **Argon2id** (OWASP parameters)
- All data stored on-device in **Isar** database
- **Zero** telemetry, tracking, or cloud lock-in
- You fully own your data

---

## 🏗 Architecture

PocketDesk follows **Clean Architecture** with a feature-first layout:

```text
lib/
├── app/                      # App root & routing entry
├── core/
│   ├── database/             # Isar provider (singleton)
│   ├── error/                # AppFailure, GlobalErrorBoundary
│   ├── logging/              # AppLogger
│   ├── router/               # GoRouter configuration
│   ├── sync/                 # WebSocket, encryption, delta engine
│   ├── theme/                # Design tokens (colors, type, spacing)
│   └── utils/                # Date, string, file, validators
└── features/
    ├── auth/                 # Login, Register, Profile
    ├── calendar/             # Events, recurrence, views
    ├── dashboard/            # Home widgets
    ├── notes/                # Rich editor, folders
    └── tasks/                # Task lists, subtasks
```

### Tech Stack

| Layer              | Technology                                 |
|--------------------|--------------------------------------------|
| State Management   | Riverpod (code-generated providers)        |
| Navigation         | GoRouter                                   |
| Database           | Isar (embedded, fully offline NoSQL)       |
| Code Generation    | build_runner + freezed + json_serializable |
| Cryptography       | cryptography / crypto (AES-GCM-128)        |
| Sync Transport     | web_socket_channel                         |

---

## 🚀 Quick Start (Development)

### Prerequisites

- [Flutter SDK](https://flutter.dev) **3.22+**
- Dart 3.x (included with Flutter)
- Android Studio or VS Code + Flutter extension

### Setup

```bash
# Clone
git clone https://github.com/Aaryanbanskota/Pocket-Desk.git
cd Pocket-Desk

# Install dependencies
flutter pub get

# Generate code
dart run build_runner build --delete-conflicting-outputs

# Run (development)
flutter run -t lib/main_dev.dart
```

### Build Releases

```bash
# Android APK
flutter build apk --release

# Linux Desktop
flutter build linux --release
```

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

---

## 📄 License

This project is licensed under the **MIT License**.  
See the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Made with ❤️ using Flutter**

*Plan • Track • Focus*

<br>

⭐ [Star this repo](https://github.com/Aaryanbanskota/Pocket-Desk) ·
🐛 [Report Bug](https://github.com/Aaryanbanskota/Pocket-Desk/issues) ·
💡 [Request Feature](https://github.com/Aaryanbanskota/Pocket-Desk/issues)

</div>

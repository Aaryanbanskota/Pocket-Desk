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

## ⚡ Recent Updates & Fixes (v1.2.0 Final Release)

- ⏰ **Clock & Timers Hub**:
  - Full working Alarm system with custom labels, repeat schedules, enable/disable switches, and local push notifications.
  - Interactive minute/second countdown timer with quick duration chips (1m, 5m, 10m, 15m), custom duration picker dialog, and alarm notification triggers upon completion.
  - High-precision Stopwatch for productivity tracking.
- 🚀 **Post-Registration Setup Onboarding**:
  - Interactive onboarding flow launching automatically upon new user registration.
  - Walkthrough of all major app features (Clock, Money Tracker, P2P File Share, AI Companion).
  - Step-by-step OpenRouter API key guide (`https://openrouter.ai/` → Get API → Create Key → Save in Settings → AI).
  - Convenient **Skip Setup** button to navigate straight to the dashboard anytime.
- 🎨 **AI Cardano Radial Dots Emblem & Companion Chat**:
  - Custom radial dot matrix emblem rendered with Flutter `CustomPainter`.
  - Smooth pulse & rotation animations when Pocketdesk AI is processing or typing.
  - System prompt enhanced with full app knowledge so users can ask AI for help using features or finding settings 24/7.
- 📊 **Stylized AI Money Health Report**:
  - Monthly breakdown card showing spent vs. remaining starting balance.
  - Spending Score (out of 100), color-coded status badge, personalized spending advice quotes, category percentage progress bars, and next-month savings targets.
- 📅 **Responsive Calendar Layout**:
  - Horizontal scrolling view segment bar preventing label truncation across screen sizes.
- 🔐 **Security Questions & Password Recovery**:
  - 2-step registration with 2 security recovery questions (preset & custom options).
  - Password recovery verification using Argon2id hashing.
- 🗑️ **2-Step Delete Account**:
  - Complete account deletion with double confirmation ("DELETE").
- 🔄 **In-App Updater & P2P File Transfer**:
  - Checks the public GitHub update manifest and opens Android's installer for downloaded APKs.
  - Local network P2P web server file sharing.

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

To publish an in-app Android update, increment the app version and build number in `pubspec.yaml`, build a release APK signed with the same key as the installed app, replace `all-apk/app-release.apk`, and update `update.json` with that version, build number, download URL, and release notes. The repository must be public so installed apps can retrieve the manifest and APK.

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

### 📅 Calendar & Events
- Day / Week / Month / Year / Agenda views
- Recurring events (full RFC 5545 support)
- Event Previews & Quick Edit / Delete
- Multiple color-coded calendars & reminders
- ICS Import & Export, fully offline

</td>
<td width="50%" valign="top">

### ✅ Task Manager
- Task Preview modal & compact edit sheet
- Subtask checklists & progress tracking
- Priority levels (Urgent → Low)
- Quick edit/delete icons on dashboard
- Swipe actions & Archive history

</td>
</tr>
<tr>
<td width="50%" valign="top">

### 📝 Note Ecosystem
- Note Preview on click with Edit & Delete actions
- Auto-save on edit with complete state preservation
- Checklist formatting, code blocks, headings
- Attachments: Images, files/PDFs, audio notes, drawings
- Organization: Folders, colors, tag/title search, duplicate note

</td>
<td width="50%" valign="top">

### 💰 Money Health & Wallet
- Starting & current wallet balance tracker
- Expense recording with categories & dates
- Complete spending history & category filters
- **AI Spending Score (0–100)** with personalized financial advice

</td>
</tr>
<tr>
<td width="50%" valign="top">

### 🤖 Smart AI Integration
- Companion Chatbot (`"yo {username}"`)
- Password-secured OpenRouter API Key storage (Argon2id)
- Universal AI across Money Health, Note Formatting, Feed Comments
- Direct Isar DB lookup for persistent state

</td>
<td width="50%" valign="top">

### 🔄 P2P Sync & Network Share
- In-App Self-Hosted Update System via raw GitHub hosting
- Local Wi-Fi network file server with PIN access
- Encrypted WebSocket sync (AES-GCM-128) & zero cloud servers
- Personal social feed with post media, likes, and AI responses
- Clean, responsive hamburger navigation drawer

</td>
</tr>
</table>

### 🔐 Privacy & Security

- Local authentication with **Argon2id** (OWASP parameters)
- All data stored on-device in **Isar** database
- **Argon2id Password Protection** for sensitive Settings (AI API Key edit/delete)
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
    ├── ai/                   # AI Settings, direct Isar repository, security lock
    ├── auth/                 # Argon2id auth, profile, password validation
    ├── calendar/             # Events, recurrence, event preview
    ├── chat/                 # P2P chat & AI companion buddy ("yo {username}")
    ├── dashboard/            # Home widgets, quick action icons
    ├── feed/                 # Personal social feed & AI post comments
    ├── money/                # Wallet balance, expenses, Money Health AI
    ├── notes/                # Rich editor, checklists, attachments, AI format
    └── tasks/                # Task lists, subtasks, task preview modal
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

### Prerequisites & Flutter SDK Pinning

PocketDesk uses **[FVM (Flutter Version Management)](https://fvm.app/)** to pin Flutter **3.24.0** (Dart 3.5.0) for reproducible builds across developer environments and CI/CD pipelines.

- **Pinned Flutter SDK**: `3.24.0` (managed via `.fvmrc`)
- **Dart SDK**: `^3.5.0`
- [FVM CLI](https://fvm.app/docs/getting_started/installation) (`dart pub global activate fvm`)

### Setup

```bash
# 1. Clone repository
git clone https://github.com/Aaryanbanskota/Pocket-Desk.git
cd Pocket-Desk

# 2. Install pinned Flutter SDK version via FVM
fvm install
fvm use 3.24.0

# 3. Install dependencies using pinned Flutter
fvm flutter pub get

# 4. Generate code
fvm dart run build_runner build --delete-conflicting-outputs

# 5. Run (development)
fvm flutter run -t lib/main_dev.dart
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

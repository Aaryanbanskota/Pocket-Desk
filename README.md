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

## ⚡ Recent Updates & Fixes (v1.2.0)

- 🔐 **Security Questions & Forgot Password Reset**:
  - Registration flow now prompts users to set custom security questions and answers.
  - Forgot Password flow allows offline account recovery by verifying security answers locally with Argon2id hashing.
- 🗑️ **2-Step Complete Delete Account & Data Purge**:
  - Complete account deletion workflow with 2-step verification ("Are you sure?" -> Type "DELETE").
  - Fully wipes all Isar database tables, secure storage keys, user preferences, and app state so the user starts 100% fresh.
- 🔄 **Self-Hosted In-App Update System**:
  - Offline-first background update checks against raw `update.json` hosted on GitHub.
  - Automatic download progress modal and seamless launch of Android's native package installer (`FileProvider` / `REQUEST_INSTALL_PACKAGES`).
  - Preserves user data and silently degrades when offline or without internet access.
- 🤖 **Universal AI Integration & Security**:
  - Direct Isar database querying (`AISettingsRepository`) powering AI across all screens (Money Health, Note Formatting, Chat Buddy, Personal Social Feed).
  - **Argon2id Password Lock** in Settings to protect saved AI API keys; authenticates user before viewing, editing, or deleting keys.
- 📁 **Enhanced File Sharing & Local Web Server**:
  - Redesigned File Share page with local network web server support.
  - Generates network link and PIN code so external devices without the app installed can download shared files directly over Wi-Fi.
- 💬 **AI Companion & Offline Social Feed**:
  - Offline/P2P chat falls back to PocketDesk AI ("yo {username}") when no peer is connected.
  - Personal social feed supporting image/video post attachments, post liking, and automatic AI interactions.
- 📝 **Rich Note Ecosystem & Preview Navigation**:
  - Note preview modal on tap, with explicit edit and delete actions.
  - Functional auto-save on edit, checklists, audio/drawings/attachments, archive, duplicate, and tag organization.
- 🔐 **Privacy Settings & Security**:
  - Integrated password change feature in Privacy Settings with Argon2id hash verification.
- 🎯 **Navigation & UX Improvements**:
  - Uncramped, clean hamburger menu drawer across all dashboard views.
  - Pinned Flutter `3.24.0` via FVM for consistent builds.

---

## 📥 Downloads & Releases

### 🤖 Android Downloads

<div align="center">
  <img src="./assets/apk-banner.png" alt="Android APK Banner" width="100%" />
</div>

| Build Type | Download | Size |
|:-----------|:---------|:-----|
| **Release APK** | [📥 Download APK](https://github.com/Aaryanbanskota/Pocket-Desk/raw/main/all-apk/app-release.apk) | ~78 MB |
| **App Bundle (AAB)** | [📦 Download AAB](https://github.com/Aaryanbanskota/Pocket-Desk/releases/download/v1.0.0/app-release.aab) | ~36 MB |

> **Tip:** Prefer the AAB for Google Play / modern installers. Use the APK for sideloading.

### 🐧 Linux Desktop Downloads

<div align="center">
  <img src="./assets/1linux-banner.png" alt="Linux Desktop Banner" width="100%" />
</div>

| Platform | Download | Size |
|:---------|:---------|:-----|
| **Linux x64** | [🐧 Download tar.gz](https://github.com/Aaryanbanskota/Pocket-Desk/releases/download/v1.0.0/pocketdesk-linux-x64.tar.gz) | ~15 MB |

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
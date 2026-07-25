<div align="center">

<img src="assets/logo.png" alt="PocketDesk Logo" width="120" height="120" />

# PocketDesk

**Your productivity hub — offline-first, privacy-respecting, and always in your pocket.**

[![Flutter](https://img.shields.io/badge/Flutter-3.22.2-blue?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-API%2024%2B-green?logo=android&logoColor=white)](https://developer.android.com)
[![Linux](https://img.shields.io/badge/Linux-Desktop-orange?logo=linux&logoColor=white)](https://flutter.dev/desktop)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen)](https://github.com/Aaryanbanskota/Pocket-Desk/releases/tag/v1.0.0)
[![Release](https://img.shields.io/github/v/release/Aaryanbanskota/Pocket-Desk)](https://github.com/Aaryanbanskota/Pocket-Desk/releases)

[📥 Download](#-download) · [✨ Features](#-features) · [🏗 Architecture](#-architecture) · [🚀 Quick Start](#-quick-start) · [🌐 Website](website/index.html) · [📋 Roadmap](#-roadmap)

</div>

---

## 📖 About

PocketDesk is a **production-quality, offline-first productivity ecosystem** built with Flutter. It combines a full-featured Calendar, Task Manager, Notes app, and Schedule Planner into a single, beautifully designed application — all without requiring a cloud account or internet connection.

> **"You own your data. Everything works offline. Internet is only used for device synchronization."**

| Platform | Status |
|----------|--------|
| 🤖 Android (API 24+) | ✅ Supported |
| 🐧 Ubuntu / Linux | ✅ Supported |
| 🪟 Windows | 🔜 Planned |
| 🍎 macOS | 🔜 Planned |

---

## 📸 Screenshots

<div align="center">

| Dashboard | Calendar | Tasks |
|-----------|----------|-------|
| <img src="assets/screenshots/dashboard.png" width="250" alt="Dashboard" /> | <img src="assets/screenshots/calendar.png" width="250" alt="Calendar" /> | <img src="assets/screenshots/tasks.png" width="250" alt="Tasks" /> |

| Notes | Login | Profile |
|-------|-------|---------|
| <img src="assets/screenshots/notes.png" width="250" alt="Notes" /> | <img src="assets/screenshots/login.png" width="250" alt="Login" /> | <img src="assets/screenshots/profile.png" width="250" alt="Profile" /> |

</div>

---

## ✨ Features

### 📅 Calendar
- Day, Week, Month, Year, and Agenda views
- Recurring events with full RFC 5545 rule support
- Multiple calendars with color-coding
- Multiple reminders per event
- ICS Import & Export
- All-day and multi-day events
- Time zone support
- Drag & Drop (Desktop, coming in v1.1)
- Fully offline — no Google Calendar dependency

### ✅ Task Manager
- Lists, Folders, and Categories
- Priority levels (Urgent → Low)
- Subtasks with nested completion tracking
- Recurring tasks
- Due dates & reminders
- Swipe-to-complete / swipe-to-delete
- Archive & History
- Search & Filters

### 📝 Notes
- Rich text & Markdown editor
- Checklists
- Image attachments
- Pin & Favorite
- Folders & Tags
- Full-text search
- Sticky-note grid layout

### 🔄 Sync (Device-to-Device)
- Encrypted WebSocket synchronization (AES-GCM-128)
- QR Code pairing — no accounts, no servers
- HMAC-SHA256 signed pairing tokens
- Delta synchronization (only changed data)
- Last-Write-Wins conflict resolution
- Offline queue — syncs when connection restores
- Auto-reconnect with exponential backoff

### 🔐 Privacy & Security
- Local authentication (username + password)
- Argon2id password hashing (OWASP parameters)
- All data stored on-device in Isar database
- No telemetry, no tracking, no cloud

### 🎨 Design
- Material 3 design system
- Dark & Light mode
- Centralized design tokens (colors, typography, spacing)
- Responsive layout (Mobile → Tablet → Desktop)
- Smooth micro-animations

---

## 🏗 Architecture

PocketDesk uses **Clean Architecture** with a feature-first directory structure:

```
lib/
├── app/                    # App root, routing entry
├── core/
│   ├── database/           # Isar provider (singleton)
│   ├── error/              # AppFailure, GlobalErrorBoundary
│   ├── logging/            # AppLogger
│   ├── router/             # GoRouter configuration
│   ├── sync/               # WebSocket, encryption, delta engine
│   ├── theme/              # Design tokens (colors, type, spacing)
│   └── utils/              # Date, string, file, validators
└── features/
    ├── auth/               # Login, Register, Profile
    ├── calendar/           # Events, recurrence, views
    ├── dashboard/          # Home widgets
    ├── notes/              # Rich editor, folders
    └── tasks/              # Task lists, subtasks
```

### State Management

| Layer | Technology |
|-------|-----------|
| State | Riverpod (code-generated providers) |
| Navigation | GoRouter |
| Database | Isar (embedded, fully offline) |
| Code Generation | build_runner + freezed + json_serializable |
| Sync | WebSocket + AES-GCM-128 |
| Auth Storage | flutter_secure_storage |

### 🛠 Developer & Styling Guide

For any new or existing developers looking to maintain or update the project, here are the key entry points:

1. **Flutter App Entry Points**:
   - Primary Entry: [lib/main.dart](file:///home/aaryan/Documents/Pocketdesk/lib/main.dart) (bootstraps the production target).
   - Production Config: [lib/main_prod.dart](file:///home/aaryan/Documents/Pocketdesk/lib/main_prod.dart) (runs app with production logging).
   - Development Config: [lib/main_dev.dart](file:///home/aaryan/Documents/Pocketdesk/lib/main_dev.dart) (runs app with verbose/debug logging).

2. **Styling & Theme (Centralized)**:
   - **Static Website CSS**: The web site is built using vanilla HTML/CSS. The main stylesheet is located at [website/style.css](file:///home/aaryan/Documents/Pocketdesk/website/style.css).
   - **Flutter Theme system**: Centralized in [lib/core/theme/](file:///home/aaryan/Documents/Pocketdesk/lib/core/theme/):
     - [app_colors.dart](file:///home/aaryan/Documents/Pocketdesk/lib/core/theme/app_colors.dart) for color palettes.
     - [app_typography.dart](file:///home/aaryan/Documents/Pocketdesk/lib/core/theme/app_typography.dart) for typography settings.
     - [app_spacing.dart](file:///home/aaryan/Documents/Pocketdesk/lib/core/theme/app_spacing.dart) for layouts/margins.
     - [app_theme.dart](file:///home/aaryan/Documents/Pocketdesk/lib/core/theme/app_theme.dart) for combining the above into Material 3 ThemeData.

3. **Documentation**:
   - All architecture, protocol, planning, and specifications are organized inside the [docs/](file:///home/aaryan/Documents/Pocketdesk/docs/) directory.

---


## 🛠 Tech Stack

| Category | Technology |
|----------|-----------|
| Framework | Flutter 3.22.2 (stable) |
| Language | Dart 3.x |
| UI | Material 3 + Google Fonts |
| State | Riverpod + Riverpod Annotation |
| Routing | GoRouter |
| Database | Isar |
| Auth | flutter_secure_storage |
| Crypto | cryptography, crypto |
| Sync | web_socket_channel |
| Notifications | flutter_local_notifications |
| QR Codes | qr_flutter, mobile_scanner |
| Serialization | Freezed + Json Serializable |
| Responsive | responsive_framework |

---

## 🚀 Quick Start

### Prerequisites

- [Flutter SDK 3.22+](https://docs.flutter.dev/get-started/install)
- Dart 3.x (bundled with Flutter)
- Android Studio / VS Code (recommended)

### Clone & Run

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

### Build Android

```bash
# Release APK
flutter build apk --release

# Release App Bundle (for Play Store)
flutter build appbundle --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Build Ubuntu / Linux

```bash
# Install system dependencies (one-time)
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev libsecret-1-dev

# Build
flutter build linux --release
```

Output: `build/linux/x64/release/bundle/`

### Run Tests

```bash
flutter test
```

### Lint & Analyze

```bash
flutter analyze
```

---

## 🔄 Offline-First Architecture

PocketDesk is designed **offline-first** at every layer:

1. **All data lives locally** in Isar (embedded NoSQL database)
2. **Every feature works without internet** — create events, tasks, notes, all offline
3. **Sync is additive** — internet adds sync, not a requirement
4. **Offline queue** — operations performed while offline are queued and applied when connectivity is restored

```
User Action
    │
    ▼
Riverpod Notifier
    │
    ├──► Isar Database (immediate, local)
    │
    └──► Sync Queue (if connected → WebSocket)
              │
              ▼
         Peer Device (LWW conflict resolution)
```

---

## 🔄 Synchronization Overview

Device-to-device sync uses **no central server**:

```
Device A                              Device B
   │                                     │
   │── QR Code Generated ───────────────►│
   │                                     │── Scan QR
   │◄── HMAC-Signed Pairing Token ───────│
   │                                     │
   │═══ Encrypted WebSocket (AES-GCM) ═══│
   │                                     │
   │── Delta Payload (changed rows) ────►│
   │◄── Delta Payload (changed rows) ────│
   │                                     │
   │    Last-Write-Wins Resolution       │
```

See [SYNC_PROTOCOL.md](docs/SYNC_PROTOCOL.md) and [WEBSOCKET_PROTOCOL.md](docs/WEBSOCKET_PROTOCOL.md) for full protocol documentation.

---

## 📥 Download

<div align="center">

### PocketDesk v1.0.0

| Platform | Download | Size |
|----------|----------|------|
| 🤖 Android APK | [**Download APK**](https://github.com/Aaryanbanskota/Pocket-Desk/releases/download/v1.0.0/app-release.apk) | ~78 MB |
| 🤖 Android AAB | [**Download AAB**](https://github.com/Aaryanbanskota/Pocket-Desk/releases/download/v1.0.0/app-release.aab) | ~36 MB |
| 🐧 Linux Bundle | [**Download tar.gz**](https://github.com/Aaryanbanskota/Pocket-Desk/releases/download/v1.0.0/pocketdesk-linux-x64.tar.gz) | ~15 MB |
| 📦 Source Code | [**GitHub Release**](https://github.com/Aaryanbanskota/Pocket-Desk/releases/tag/v1.0.0) | — |

</div>

### Linux Installation

```bash
tar -xzf pocketdesk-linux-x64.tar.gz
cd bundle
./pocketdesk
```

---

## 🌐 Website

The PocketDesk website is included in the [`website/`](website/) directory. It is a static site (HTML/CSS/JS) with:

- Dark mode toggle
- OS auto-detection for download recommendations
- Features overview, FAQ, Documentation, Privacy Policy

---

## 📋 Roadmap

| Version | Features |
|---------|---------|
| v1.0.0 | ✅ Calendar, Tasks, Notes, Dashboard, Auth, Sync, Website |
| v1.1.0 | 🔜 Drag & Drop (Desktop), Schedule Planner view |
| v1.2.0 | 🔜 Windows support |
| v1.3.0 | 🔜 macOS support |
| v2.0.0 | 🔜 Optional encrypted cloud backup, widget integrations |

See [ROADMAP.md](docs/ROADMAP.md) for the full milestone breakdown.

---

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a pull request.

```bash
# Fork → Clone → Branch → Code → Test → PR
git checkout -b feat/your-feature
flutter test
flutter analyze
git commit -m "feat: your feature"
git push origin feat/your-feature
# Open PR on GitHub
```

---

## 🔒 Security

For reporting security vulnerabilities, please read [SECURITY.md](docs/SECURITY.md).

---

## 📄 License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE) for details.

---

## 🙏 Credits

| Role | Contributor |
|------|------------|
| Project Lead & Design | [@Aaryanbanskota](https://github.com/Aaryanbanskota) |
| Flutter Framework | [Google / Flutter Team](https://flutter.dev) |
| Database | [Isar](https://isar.dev) |

---

<div align="center">

Made with ❤️ using Flutter

[⭐ Star this repo](https://github.com/Aaryanbanskota/Pocket-Desk) · [🐛 Report Bug](https://github.com/Aaryanbanskota/Pocket-Desk/issues) · [💡 Request Feature](https://github.com/Aaryanbanskota/Pocket-Desk/issues)

</div>

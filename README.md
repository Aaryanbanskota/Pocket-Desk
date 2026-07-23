# <img src="assets/images/logo.png" alt="PocketDesk Logo" width="48" height="48" align="center"/> PocketDesk

PocketDesk is a comprehensive, offline-first productivity ecosystem designed to keep your life organized. It seamlessly integrates a Calendar, Task Manager, Notes, and Schedule Planner, all while keeping your data local and secure. With built-in multi-device sync, you can manage your productivity across your Android and Ubuntu Linux devices without relying on the cloud.

## ✨ Features

- **📅 Calendar**: Full-featured calendar with Day, Week, Month, Year, and Agenda views. Supports recurring events, reminders, and ICS import/export.
- **✅ Task Manager**: Organize your life with lists, folders, priorities, recurring tasks, subtasks, and rich filtering.
- **📝 Notes**: Capture ideas with rich text and Markdown support, complete with checklists, images, and attachments.
- **⏱️ Schedule Planner**: Plan your day efficiently with a unified dashboard showing today's schedule, tasks, and upcoming events.
- **🔄 Multi-device Sync**: Securely sync data across your devices using local WebSockets and QR code pairing—no cloud required!
- **🔒 Offline-First**: Your data lives on your device. Everything works seamlessly without an internet connection.

## 🛠️ Tech Stack

PocketDesk is built with modern, performant technologies:

- **Frontend Framework**: Flutter (Latest Stable)
- **Design System**: Material 3 & Responsive Framework
- **State Management**: Riverpod
- **Routing**: GoRouter
- **Code Generation**: Freezed, Json Serializable
- **Database**: Isar Database (High-performance NoSQL)
- **Secure Storage**: flutter_secure_storage
- **Networking**: WebSockets for real-time local sync
- **Backend (Sync Server)**: Dart backend with Shelf

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Latest Stable)
- [Dart SDK](https://dart.dev/get-dart)
- Supported IDE (VS Code, Android Studio, etc.)

### Setup Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/pocketdesk.git
   cd pocketdesk
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate code (Freezed, JSON Serializable, Isar):**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

### Running the App

To run the app on a connected device or emulator:

```bash
flutter run
```

### Running Tests

To execute the test suite:

```bash
flutter test
```

## 📁 Project Structure Overview

```
pocketdesk/
├── android/           # Android native code
├── linux/             # Ubuntu Linux native code
├── assets/            # Images, fonts, icons
├── lib/
│   ├── app/           # App configuration, routing, theme
│   ├── core/          # Shared utilities, constants, network, database setup
│   ├── features/      # Feature modules (Calendar, Tasks, Notes, Sync, Dashboard)
│   └── main.dart      # Application entry point
├── packages/          # Local Dart packages (e.g., backend sync server)
├── test/              # Unit and widget tests
└── docs/              # Detailed documentation
```

## 📚 Documentation

For detailed technical specifications, architecture diagrams, and feature documentation, please refer to the `docs/` directory.

- [Project Specification](PROJECT_SPEC.md)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on how to submit pull requests, report issues, and suggest features.

## 💻 Platform Support

PocketDesk is currently optimized and officially supported on:
- **Android**
- **Ubuntu Linux Desktop**

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

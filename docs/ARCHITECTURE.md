# PocketDesk Architecture

This document describes the high-level architecture and technical decisions for PocketDesk, an offline-first productivity suite built with Flutter and Dart.

## 1. High-Level Architecture Overview

PocketDesk follows an offline-first architecture, meaning all features are fully functional without an internet connection. Data is stored locally and synchronized with other paired devices directly over a local network when available, without any central cloud servers.

### Architecture Diagram

```
+-------------------------------------------------------------+
|                        PocketDesk App                       |
|                                                             |
|  +----------------+  +-----------------+  +--------------+  |
|  | Presentation   |  | Domain          |  | Data         |  |
|  | (Flutter UI)   |  | (Business Logic)|  | (Local DB/   |  |
|  |                |  |                 |  |  Sync)       |  |
|  | - Screens      |<-> - Use Cases     |<-> - Repositories| |
|  | - Riverpod     |  | - Entities      |  | - Isar DB    |  |
|  | - GoRouter     |  |                 |  | - Sync Queue |  |
|  +----------------+  +-----------------+  +--------------+  |
+-------------------------------------------------------------+
                            ^  ^
                            |  | (WebSocket Sync)
                            v  v
+-------------------------------------------------------------+
|                    Local Network Device                     |
|  (Paired desktop/mobile running PocketDesk with Shelf API)  |
+-------------------------------------------------------------+
```

## 2. Flutter App Architecture

The app uses **Clean Architecture** combined with a **Feature-first** folder structure.

*   **State Management:** Riverpod is used for robust, testable state management utilizing providers and notifiers.
*   **Routing:** GoRouter handles navigation, including nested routing for complex navigation flows (e.g., bottom navigation bars).
*   **Database:** Isar Database serves as the embedded, high-performance local database.
*   **Models:** Freezed and Json Serializable are used to generate immutable data classes and handle serialization/deserialization safely.
*   **Secure Storage:** `flutter_secure_storage` protects sensitive information, such as passwords and encryption keys.

### Directory Structure

```
lib/
  core/                  # App-wide infrastructure
    theme/               # Centralized AppTheme
    router/              # GoRouter configuration
    error/               # Global error handling & logging
    utils/               # Helper functions
  features/              # Feature-based modules
    auth/
      data/              # Repositories, datasources, models
      domain/            # Entities, use cases, repository interfaces
      presentation/      # Screens, widgets, Riverpod providers
    dashboard/
    calendar/
    tasks/
    notes/
    sync/
    profile/
  shared/                # Components shared across features
    widgets/             # Reusable UI components
    extensions/          # Dart extension methods
```

## 3. Backend Architecture

While PocketDesk has no central cloud backend, it includes an embedded Dart backend to facilitate direct device-to-device communication.

*   **Framework:** Dart with the Shelf framework.
*   **Communication:** A WebSocket server enables real-time synchronization between paired devices.
*   **Pairing API:** A REST API handles the initial device pairing protocol.
*   **Data Privacy:** True peer-to-peer (via local network) approach. There are no cloud user accounts, databases, or third-party storage services.

## 4. Synchronization Architecture

Syncing is localized, peer-to-peer, and encrypted.

*   **QR Pairing Flow:** Devices are paired securely by scanning a QR code containing an initial connection token and IP address info.
*   **Encrypted WebSockets:** All sync data transmitted over the local network is encrypted end-to-end.
*   **Delta Sync:** Instead of syncing entire databases, devices exchange change vectors and timestamps to only send modified data.
*   **Offline Queue:** Changes made while disconnected from paired devices are stored in a persistent local queue and processed upon reconnection.
*   **Conflict Resolution:** Conflicts are resolved using a Last-Write-Wins (LWW) strategy based on timestamps, with an option for manual user override in complex scenarios.
*   **Resilience:** Built-in heartbeat mechanisms and automatic reconnect logic ensure the sync connection remains stable when devices are active on the same network.

## 5. Security Architecture

*   **Local Password Hashing:** User passwords (for app locking) are hashed locally using the robust Argon2 algorithm.
*   **Encrypted Local Storage:** Sensitive data and sync keys are stored in secure enclaves using `flutter_secure_storage`.
*   **Signed Pairing Tokens:** QR pairing tokens contain a device ID, user ID, nonce, expiration time, public key, and cryptographic signature to prevent tampering.
*   **Replay Attack Prevention:** Pairing endpoints validate the nonce and expiration time.
*   **Input Validation:** Strict validation rules are applied at the presentation and domain layers to prevent injection or corruption.

## 6. Design System Architecture

*   **Centralized AppTheme:** All styling rules live in `lib/core/theme`.
*   **Design Tokens:** We utilize design tokens for colors, typography, spacing, border radiuses, and animation durations to ensure absolute consistency.
*   **Material 3:** Theming is built on top of Flutter's Material 3 design language.
*   **Rule:** Never hardcode UI values (e.g., `SizedBox(height: 16)`); always use design tokens (e.g., `SizedBox(height: AppSpacing.md)`).

## 7. Database Architecture

*   **Isar Collections:** Each domain entity (Note, Task, Event) corresponds to an Isar collection.
*   **Relationships:** Isar links are used for relationships (e.g., linking subtasks to a parent task).
*   **Indexing:** Frequent query fields (like dates and tags) are indexed for performance.
*   **Migrations:** Schema changes are handled via Isar's built-in migration strategies and automated code generation.

## 8. Key Architectural Decisions (ADRs)

*   **ADR-001: Riverpod over Provider/BLoC.** Chosen for its compile-time safety and ease of combining providers.
*   **ADR-002: Isar over SQLite.** Chosen for its superior performance in Flutter, native Dart API, and easy full-text search capabilities.
*   **ADR-003: Peer-to-Peer local sync.** Chosen to maximize privacy and adhere strictly to the "offline-first" ethos without relying on external cloud providers.

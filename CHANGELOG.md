# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2026-07-24] — M4 Start: Calendar Models, Repository, & Views

### Added
- **M4-T9 Recurring Events Engine**: Designed and implemented an offline recurrence expansion system (`RecurrenceEngine`) supporting:
  - Daily, Weekly, Monthly, Yearly, and Custom recurrence patterns.
  - RFC 5545 recurrence rule processing (e.g. `FREQ`, `INTERVAL`, `BYDAY`).
  - Virtual instance cloning to display recurring instances in day, week, month, and agenda views.
- **M4-T9 Recurrence Engine Unit Tests**: Created comprehensive unit tests validating correct instance generation, custom rule logic, and date boundaries.
- **M4-T10 Reminders & Notifications**: Integrated local reminders and notifications for events:
  - Created `NotificationService` wrapper initialized during dev and prod startup.
  - Integrated notification scheduling inside `CalendarEventsNotifier` for event creations and updates.
  - Automatically cancels pre-existing reminders on event deletion or modifications.
  - Created `NotificationService` unit tests validating initialization, cancellation, and scheduling robustness.
- **M4-T11 Multiple Calendars**: Added `CalendarModel` Isar schema + `CalendarManagerRepository` (save/delete/ensureDefault). Registered schema in Isar provider.
- **M4-T12/13 ICS Import/Export**: Built pure-Dart `IcsService` (RFC 5545) — zero external deps, full round-trip serialize/deserialize for all event fields including recurrence, all-day, reminders.
- **M4-T13 Search & Filters**: Built `CalendarSearchPage` with full-text search + category + recurrence type filters. Accessible from Calendar AppBar search icon.
- **M4-T14 Time Zone Support**: `NotificationService` now resolves each event's stored `timeZone` field into a `TZDateTime` location, with graceful fallback to local time.
- **M4-T3 to M4-T7 Calendar Views**: Developed responsive, modular UI view widgets for calendar interactions:
  - **Day View**: Horizontal time block rendering mapping hourly ranges.
  - **Week View**: Responsive 7-column layout displaying parallel columns.
  - **Month View**: Complete month-grid cell mapping with event card previews.
  - **Year View**: Annual 12 mini months grid.
  - **Agenda View**: Chronological scrolling view grouping all scheduled events by date.
- Integrated a premium SegmentedButton calendar view controller within `CalendarDashboardView`.

### Added
- **M4-T1 Calendar Data Model**: Created `CalendarEventModel` schema for Isar, with indexes, recurrence types, and sync attributes. Registered the schema globally in `isarProvider`.
- **M4-T2 Calendar Repository**: Implemented database operations (`saveEvent`, `deleteEvent`, `getEventsForUser`, `getEventsForRange`, `searchEvents`) using Isar transactions.
- Corrected imports and type annotations across the newly integrated calendar presentation pages and state providers.

### Verified
- `flutter analyze` -> Clean
- `flutter test` -> All unit and widget tests pass ✅

## [2026-07-23] — M3 Complete: Interactive Dashboard

### Added
- **M3-T1 Dashboard Layout**: Created responsive page layout displaying schedules, tasks, stats, and widgets matching viewport width.
- **M3-T2 Today Schedule Widget**: Built a structured list visualizer for mock schedule events.
- **M3-T3 Calendar Mini Widget**: Implemented a weekly strip calendar control indicating the current date.
- **M3-T4/M3-T5 Tasks & Notes Widgets**: Developed quick overview panels for user tasks and markdown notes.
- **M3-T6 Statistics Widget**: Introduced statistics summary displaying completed task count metrics.
- **M3-T7 Quick Actions**: Created an icon-based button panel for fast navigation to event creation and task creation dialogs.
- **M3-T8 Pinned Widgets**: Added a flexible, persistent alert cards panel.
- **M3-T9 Responsive Layout**: Managed cross-platform layouts displaying column configurations customized for Desktop, Tablet, and Mobile views.

### Verified
- `flutter analyze` -> Clean
- `flutter test` -> All unit and widget tests pass ✅

## [2026-07-23] — M2 Complete: Local Authentication & User Profiles

### Added
- **M2-T1 Isar UserModel Schema**: Defined `UserModel` with secure schema annotations (unique index on username, hash + salt properties, theme preferences, timestamps).
- **M2-T2 Password Hashing**: Implemented Argon2id password hashing parameters using OWASP recommendations (19 MiB memory, 2 iterations, 1 parallelism, 128-bit random salt, constant-time verification).
- **M2-T3/M2-T4 UI Screens**: Designed stateful, beautiful Material 3 `LoginPage` and `RegisterPage` with curved scale-up animations, real-time password strength indicators, form validations, and custom styled form text fields (`PDTextField`).
- **M2-T5 Auth State Notifier**: Wrote Riverpod `AuthNotifier` controlling application state (`AuthLoading`, `AuthUnauthenticated`, `AuthAuthenticated`, `AuthError`).
- **M2-T6 Secure Auth Storage**: Handled secure local keychain persistence of session parameters using `flutter_secure_storage` (Android Keystore / GNOME Keyring).
- **M2-T7 Profile Management Screen**: Created `ProfilePage` allowing display name updates, password alterations, sign-outs, and account detail logs.

### Changed
- Configured dynamic redirection inside `app_router.dart` depending on auth state changes.

### Verified
- `flutter analyze` -> Clean
- `flutter test` -> All unit and widget tests pass ✅

## [2026-07-23] — M1 Complete: Routing, Error Handling, Core Utilities

### Added
- **M1-T4 Routing**: `AppRoutes` constants, `GoRouter` provider with auth-guard redirect, placeholder screens, barrel export (`lib/core/router/`)
- **M1-T5 Error Handling**: `GlobalErrorBoundary` widget catching `FlutterError` + `runZonedGuarded`, `AppFailure` sealed class hierarchy (`DatabaseFailure`, `NetworkFailure`, `AuthFailure`, `SyncFailure`, `SerializationFailure`, `FileFailure`, `UnexpectedFailure`), `AppLogger` structured logger with levels (barrel: `lib/core/error/`, `lib/core/logging/`)
- **M1-T6 Core Utilities**: `DateTimeUtils` (formatting, relative labels, boundaries), `StringX`/`NullableStringX` extensions, `FileSystemUtils` (persistent/cache dirs, read/write, size), `Validators` (username, password, required, composable) — barrel: `lib/core/utils/`

### Changed
- `lib/app/app.dart` updated to `MaterialApp.router` wired to `appRouterProvider`
- `lib/main_dev.dart` and `lib/main_prod.dart` wrapped in `runZonedGuarded` + `GlobalErrorBoundary`

### Verified
- `flutter analyze --no-pub` → **No issues found**
- Milestone 1 — Foundation: **100% complete** ✅

## [2026-07-23] — M1-T2: Flutter Configuration Complete


Completed the dependency injection setup and flavored environment environments.

### Added
- Added core framework packages (`flutter_riverpod`, `go_router`, `isar`, `isar_flutter_libs`, `responsive_framework`, `cryptography`, `flutter_secure_storage`, etc.) to `pubspec.yaml`
- Created environment-specific JSON configuration files (`.env.development.json`, `.env.production.json`)
- Created custom entry points (`lib/main_dev.dart`, `lib/main_prod.dart`) and updated `lib/main.dart` to run production by default
- Configured Android build specifications (`minSdk = 24`, `targetSdk = 34` in Gradle config)

### Changed
- Refactored `test/widget_test.dart` to verify `PocketDeskApp` rendering within `ProviderScope`

### Next
- M1-T3: Design System & Theme (creating a centralized Material 3 theme)

## [2026-07-23] — M1-T1: Project Setup Complete

Completed the initial setup of the Flutter project targeting Android and Linux platforms.

### Added
- Boilerplate Flutter structure (`lib/main.dart`, `android/`, `linux/`, `test/`)
- Custom static analysis configuration (`analysis_options.yaml`) enforcing strict casts, inferences, raw-types, and key lints
- Updated project `.gitignore` for local database caching, secrets/env, and system files

### Changed
- Restored original, highly detailed `README.md` from Phase 1 documentation

### Next
- M1-T2: Flutter Configuration (configuring build targets and base packages/dependencies)

## [2026-07-23] — Initial Project Documentation

This marks the official kickoff of PocketDesk. No production code has been written yet.

### Added
- RULES.md: Internalized all agent rules and coding standards
- README.md: Full project overview, setup instructions, tech stack
- PROJECT_SPEC.md: Detailed feature specifications for all modules
- ARCHITECTURE.md: Clean Architecture design, folder structure, ADRs
- ROADMAP.md: 10-milestone roadmap with tasks and subtasks
- TASKS.md: Full task tracker with all milestones, tasks, and subtasks
- DATABASE_SCHEMA.md: Complete Isar schema for all features
- API.md: Full REST + WebSocket API reference for sync backend
- SYNC_PROTOCOL.md: Peer-to-peer delta sync protocol spec
- WEBSOCKET_PROTOCOL.md: WebSocket message types and state machine
- SECURITY.md: Threat model, Argon2id, ECDH, AES-256-GCM specs
- TEST_PLAN.md: Full test strategy with coverage targets
- PROJECT_CONTEXT.md: Persistent agent memory initialized
- CHANGELOG.md: This file

### Architecture Decisions
- Flutter (latest stable) + Material 3 for Android + Ubuntu Desktop
- Riverpod state management, GoRouter navigation
- Isar embedded database for offline-first storage
- Freezed + Json Serializable for immutable models
- Argon2id for secure password hashing
- Dart/Shelf backend for synchronization server
- Encrypted WebSocket (AES-256-GCM) for device sync
- QR-based device pairing with ECDH + Ed25519 signatures
- Clean Architecture + Feature-first folder structure
- Centralized AppTheme design system (no hardcoded values)

### Next
- Phase 2: Architecture review
- Phase 3: Begin implementation at Milestone 1 — Foundation

# PocketDesk – Junior Developer Reference

> Stack: **Flutter 3 · Dart ≥3.4 · Riverpod · Isar · GoRouter**
> Version: `1.1.0+2` — see `pubspec.yaml` at project root.

---

## 1. Project File Map

```
Pocketdesk/
├── lib/
│   ├── main.dart                      # entry point
│   ├── main_dev.dart                  # dev flavour entry
│   ├── main_prod.dart                 # prod flavour entry
│   ├── app/
│   │   ├── app.dart                   # MaterialApp root, theme wiring
│   │   └── config/app_config.dart
│   ├── core/
│   │   ├── database/isar_provider.dart        # Isar DB singleton (Riverpod)
│   │   ├── error/
│   │   │   ├── app_failure.dart
│   │   │   ├── error.dart
│   │   │   └── global_error_boundary.dart
│   │   ├── logging/app_logger.dart
│   │   ├── router/
│   │   │   ├── app_router.dart        # GoRouter definition
│   │   │   ├── app_router.g.dart      # ← GENERATED, do not edit
│   │   │   ├── app_routes.dart        # route path string constants
│   │   │   └── router.dart
│   │   ├── services/
│   │   │   ├── notification_service.dart
│   │   │   ├── p2p_sync_service.dart
│   │   │   └── qr_data_share_service.dart
│   │   ├── sync/
│   │   │   ├── delta_sync_engine.dart
│   │   │   ├── device_pairing_service.dart
│   │   │   ├── pairing_token_service.dart
│   │   │   ├── sync_coordinator.dart
│   │   │   ├── sync_encryptor.dart
│   │   │   ├── sync_protocol.dart
│   │   │   └── websocket_sync_client.dart
│   │   ├── theme/                     # ← ALL STYLING LIVES HERE
│   │   │   ├── app_colors.dart        # colour palette (single source of truth)
│   │   │   ├── app_spacing.dart       # spacing constants
│   │   │   ├── app_typography.dart    # TextStyles / fonts
│   │   │   ├── app_animations.dart    # durations & curves
│   │   │   ├── app_theme.dart         # ThemeData assembly (light + dark)
│   │   │   ├── theme.dart             # barrel export
│   │   │   └── theme_mode_notifier.dart
│   │   └── utils/
│   │       ├── date_time_utils.dart
│   │       ├── file_system_utils.dart
│   │       ├── string_extensions.dart
│   │       ├── utils.dart
│   │       └── validators.dart
│   └── features/
│       ├── auth/
│       │   ├── data/models/user_model.dart          (+ .g.dart generated)
│       │   ├── data/repositories/auth_repository.dart
│       │   ├── data/services/password_hasher.dart
│       │   ├── data/services/secure_auth_storage.dart
│       │   ├── presentation/pages/login_page.dart
│       │   ├── presentation/pages/register_page.dart
│       │   ├── presentation/pages/profile_page.dart
│       │   ├── presentation/providers/auth_notifier.dart
│       │   ├── presentation/widgets/auth_logo_header.dart
│       │   └── presentation/widgets/pd_text_field.dart
│       ├── calendar/
│       │   ├── data/models/calendar_event_model.dart (+ .g.dart)
│       │   ├── data/models/calendar_model.dart       (+ .g.dart)
│       │   ├── data/models/recurrence_engine.dart
│       │   ├── data/repositories/calendar_manager_repository.dart
│       │   ├── data/repositories/calendar_repository.dart
│       │   ├── data/services/ics_service.dart
│       │   ├── presentation/pages/calendar_dashboard_view.dart
│       │   ├── presentation/pages/calendar_search_page.dart
│       │   ├── presentation/providers/calendar_events_notifier.dart
│       │   └── presentation/widgets/  (agenda/day/week/month/year/event_form)
│       ├── dashboard/
│       │   ├── presentation/pages/dashboard_page.dart
│       │   └── presentation/widgets/  (calendar_mini, notes, tasks, schedule, stats, quick_actions, pinned)
│       ├── notes/
│       │   ├── data/models/note_model.dart           (+ .g.dart)
│       │   ├── data/repositories/note_repository.dart
│       │   ├── presentation/pages/note_editor_page.dart
│       │   ├── presentation/pages/notes_dashboard_view.dart
│       │   └── presentation/providers/notes_notifier.dart
│       ├── settings/
│       │   ├── presentation/pages/settings_page.dart
│       │   └── presentation/widgets/
│       │       ├── appearance_settings_widget.dart
│       │       ├── device_settings_widget.dart
│       │       ├── privacy_settings_widget.dart
│       │       └── qr_data_share_widget.dart
│       └── tasks/
│           ├── data/models/task_model.dart           (+ .g.dart)
│           ├── data/repositories/task_repository.dart
│           ├── presentation/pages/tasks_dashboard_view.dart
│           ├── presentation/providers/tasks_notifier.dart
│           └── presentation/widgets/ (task_card, task_form_sheet)
```

---

## 2. Theming / Styling (there is no CSS — it's Flutter/Dart)

| What to change | File |
|----------------|------|
| Colours | `lib/core/theme/app_colors.dart` |
| Fonts / TextStyles | `lib/core/theme/app_typography.dart` |
| Spacing | `lib/core/theme/app_spacing.dart` |
| Animations | `lib/core/theme/app_animations.dart` |
| ThemeData (light + dark) | `lib/core/theme/app_theme.dart` |
| Dark/Light mode toggle | `lib/core/theme/theme_mode_notifier.dart` |

**Rule:** change `app_colors.dart` only; every widget references it via `Theme.of(context)` or the colour constants.

---

## 3. Generated Files — never edit `*.g.dart` by hand

Regenerate after any model/provider change:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Watch mode (dev):

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

---

## 4. Build Commands

### Android APK

```bash
# Debug
flutter build apk --debug

# Release (requires keystore configured in android/key.properties)
flutter build apk --release

# Smaller — split per CPU architecture
flutter build apk --release --split-per-abi
```

Output: `build/app/outputs/flutter-apk/`

### Linux Desktop

```bash
# One-time system dependency install
sudo apt install libglib2.0-dev libgtk-3-dev ninja-build cmake

# Build
flutter build linux --release
```

Output: `build/linux/x64/release/bundle/`  
Run: `./build/linux/x64/release/bundle/pocketdesk`

---

## 5. Day-to-day Commands

```bash
flutter pub get                          # install packages
flutter run -t lib/main_dev.dart        # run on phone / emulator
flutter run -d linux -t lib/main_dev.dart  # run on Linux desktop
flutter analyze                          # lint check
flutter test                             # unit tests
```

---

## 6. Architecture Pattern

```
Isar DB  →  Repository  →  Riverpod Notifier  →  Widget (ref.watch)
```

Each feature folder follows the same structure:
- `data/` — models (Isar), repositories
- `presentation/` — pages, widgets, providers (Riverpod notifiers)

---

## 7. Navigation (GoRouter)

Routes are defined in `lib/core/router/app_router.dart`.  
Path strings are in `lib/core/router/app_routes.dart`.

```dart
context.go(AppRoutes.dashboard);   // replace stack
context.push(AppRoutes.noteEditor); // push on stack
```

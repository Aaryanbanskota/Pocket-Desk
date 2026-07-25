# PocketDesk — Freelancer Onboarding Guide

> This document tells you everything you need to know to read, edit, and hand back a page of the PocketDesk Flutter app.
> It also acts as a prompt you can paste into any AI assistant to get accurate, context-aware help.

---

## App Overview

**PocketDesk** is a privacy-first, offline-first personal productivity desktop + mobile app built with Flutter.

| Feature | Pages / Views |
|---------|---------------|
| Dashboard | `dashboard_page.dart` |
| Tasks | `tasks_dashboard_view.dart` |
| Notes (rich text) | `notes_dashboard_view.dart`, `note_editor_page.dart` |
| Calendar | `calendar_dashboard_view.dart`, `calendar_search_page.dart` |
| Settings | `settings_page.dart` |
| Auth (login / register) | `login_page.dart`, `register_page.dart`, `profile_page.dart` |

---

## Tech Stack (quick reference)

| Layer | Technology |
|-------|-----------|
| UI | Flutter (Dart) |
| State management | Riverpod 2 (`flutter_riverpod`, `riverpod_annotation`) |
| Local database | Isar 3 |
| Navigation | GoRouter 14 |
| Styling | Dart `ThemeData` — **no CSS exists** |
| Fonts | Google Fonts (`google_fonts` package) |
| Code generation | `build_runner` + `isar_generator` + `riverpod_generator` |
| Crypto / Security | `cryptography`, `flutter_secure_storage` |
| Notifications | `flutter_local_notifications` |
| QR Sync | `qr_flutter` + `mobile_scanner` |

---

## Where Every Page Lives

### Routing entry point
`lib/core/router/app_router.dart` — defines all routes.  
`lib/core/router/app_routes.dart` — path string constants.

### Pages

| Page | Path |
|------|------|
| Dashboard | `lib/features/dashboard/presentation/pages/dashboard_page.dart` |
| Tasks list | `lib/features/tasks/presentation/pages/tasks_dashboard_view.dart` |
| Notes list | `lib/features/notes/presentation/pages/notes_dashboard_view.dart` |
| Note editor | `lib/features/notes/presentation/pages/note_editor_page.dart` |
| Calendar | `lib/features/calendar/presentation/pages/calendar_dashboard_view.dart` |
| Calendar search | `lib/features/calendar/presentation/pages/calendar_search_page.dart` |
| Settings | `lib/features/settings/presentation/pages/settings_page.dart` |
| Login | `lib/features/auth/presentation/pages/login_page.dart` |
| Register | `lib/features/auth/presentation/pages/register_page.dart` |
| Profile | `lib/features/auth/presentation/pages/profile_page.dart` |

### Widgets used on each page

**Dashboard widgets** (`lib/features/dashboard/presentation/widgets/`):
- `calendar_mini_widget.dart` — mini month preview
- `notes_widget.dart` — recent notes strip
- `tasks_widget.dart` — task summary cards
- `today_schedule_widget.dart` — today's calendar events
- `statistics_widget.dart` — stats/counters
- `quick_actions.dart` — FAB-style quick actions
- `pinned_widgets.dart` — pinned items section

**Calendar widgets** (`lib/features/calendar/presentation/widgets/`):
- `agenda_view_widget.dart`, `day_view_widget.dart`, `week_view_widget.dart`, `month_view_widget.dart`, `year_view_widget.dart`
- `event_form_sheet.dart` — bottom sheet for creating/editing events

**Task widgets** (`lib/features/tasks/presentation/widgets/`):
- `task_card.dart`, `task_form_sheet.dart`

**Settings widgets** (`lib/features/settings/presentation/widgets/`):
- `appearance_settings_widget.dart`, `device_settings_widget.dart`
- `privacy_settings_widget.dart`, `qr_data_share_widget.dart`

---

## Styling — Where to Change Visual Appearance

There is **no CSS**. All visual tokens are in `lib/core/theme/`:

| File | Controls |
|------|----------|
| `app_colors.dart` | All colour constants |
| `app_typography.dart` | Font sizes, weights, letter-spacing |
| `app_spacing.dart` | Padding / margin constants |
| `app_animations.dart` | Durations and easing curves |
| `app_theme.dart` | Full `ThemeData` (light + dark) |
| `theme_mode_notifier.dart` | Riverpod provider that toggles dark/light |

**To change a colour:** open `app_colors.dart`, find the constant, change its value. It will propagate everywhere automatically.

**To change a font:** open `app_typography.dart`, change the `GoogleFonts.*` call.

---

## Data Flow Pattern

```
User action
  └─► Widget calls Riverpod notifier method
        └─► Notifier calls Repository method
              └─► Repository reads/writes Isar DB
                    └─► Notifier rebuilds state
                          └─► Widget re-renders
```

Example: adding a task
1. `task_form_sheet.dart` → calls `ref.read(tasksNotifierProvider.notifier).addTask(task)`
2. `tasks_notifier.dart` → calls `taskRepository.saveTask(task)`
3. `task_repository.dart` → writes to Isar
4. Notifier updates state → `tasks_dashboard_view.dart` re-renders

---

## How Providers Work

Providers live in `presentation/providers/` inside each feature:

```dart
// Example: watch the tasks list
final tasks = ref.watch(tasksNotifierProvider);

// Example: call a method
ref.read(tasksNotifierProvider.notifier).addTask(task);
```

Never instantiate repositories or services directly in widgets — always go through a Riverpod provider.

---

## Generated Files — Important

Files ending in `.g.dart` are **auto-generated**. Do NOT edit them.  
After changing any model or provider annotation, run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## How to Run the App

```bash
# 1. Install Flutter packages
flutter pub get

# 2. Run on Android device/emulator
flutter run -t lib/main_dev.dart

# 3. Run on Linux desktop
flutter run -d linux -t lib/main_dev.dart
```

---

## How to Build for Delivery

### Android APK

```bash
flutter build apk --release --split-per-abi
```
Files go to `build/app/outputs/flutter-apk/`

### Linux Desktop Bundle

```bash
# Install build dependencies first (Ubuntu/Debian)
sudo apt install libglib2.0-dev libgtk-3-dev ninja-build cmake

flutter build linux --release
```
Bundle goes to `build/linux/x64/release/bundle/`

---

## When You Replace/Edit a Page — Checklist

1. **Keep the same file path and class name** — routing depends on them.
2. **Use `ref.watch` / `ref.read`** for data — do not create your own state manually if a notifier already exists.
3. **Use theme tokens** — `Theme.of(context).colorScheme.*`, or the constants from `app_colors.dart`. Avoid hardcoded hex values.
4. **After changing a model or adding a `@riverpod` annotation**, run `build_runner build`.
5. **Check for `use_build_context_synchronously` lint** — after any `await`, use a local `ctx` variable captured before the await, and guard with `ctx.mounted`.
6. **Run `flutter analyze`** before submitting — zero warnings expected.

---

## AI Prompt (paste this into any AI assistant for context)

```
Project: PocketDesk — a Flutter offline-first productivity app.
Tech: Flutter 3, Dart ≥3.4, Riverpod 2, Isar 3, GoRouter 14, Google Fonts.
Architecture: Feature-first. Each feature has data/ (models + repositories) and
presentation/ (pages + widgets + providers). State is managed with Riverpod
notifiers. Database is Isar (local, offline). Navigation uses GoRouter.
Styling: Dart ThemeData — NO CSS. Colours in lib/core/theme/app_colors.dart,
typography in app_typography.dart, spacing in app_spacing.dart.
Pages live in lib/features/<feature>/presentation/pages/.
Providers live in lib/features/<feature>/presentation/providers/.
Generated files (*.g.dart) must never be edited; run build_runner to regenerate.
Lint rule to respect: use_build_context_synchronously — capture context in a
local variable before any await and guard with ctx.mounted, not State.mounted.
```

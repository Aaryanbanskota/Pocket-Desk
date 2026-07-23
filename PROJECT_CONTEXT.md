# PocketDesk — Project Context
## Last Updated: 2026-07-24
## Current Milestone: Milestone 4 — Calendar
## Current Task: M4-T11 — Multiple Calendars

## Project Summary
Offline-first productivity ecosystem combining Calendar, Task Manager, Notes, Schedule Planner, Device Synchronization, and a Web Landing Page.

## Architecture Decisions Made
1. Flutter + Material 3 for cross-platform (Android + Ubuntu Desktop)
2. Riverpod for state management
3. GoRouter for navigation
4. Isar for local database (offline-first)
5. Freezed + Json Serializable for models
6. flutter_secure_storage for sensitive data
7. Argon2id for password hashing
8. Dart/Shelf for backend
9. Encrypted WebSockets for sync
10. Clean Architecture + Feature-first folder structure
11. Design System with centralized AppTheme (never hardcode values)
12. QR pairing with ECDH key exchange + Ed25519 signatures

## Completed Work
- [x] RULES.md read and internalized
- [x] All design reference files reviewed (DESIGN-awsmd-com.md, SKILL-awsmd-com.md, design-tokens-awsmd-com.json)
- [x] Design assets reviewed (dashboard reference, loading screen, logo)
- [x] All documentation files created (README, ARCHITECTURE, ROADMAP, SYNC_PROTOCOL, etc.)
- [x] M1: Foundation (Project Setup, Configs, Design System/Theming, Routing, Logging, Utilities)
- [x] M2: Authentication (UserModel Schema, Argon2id Password Hashing, Secure Storage, Auth Notifier, Login/Register/Profile Screens)
- [x] M3: Dashboard (Grid Layout, Widgets: Today Schedule, Calendar Mini, Tasks, Notes, Stats, Quick Actions, Pinned alerts)
- [x] M4-T1: Calendar Data Model (Isar)
- [x] M4-T2: Calendar Repository (CRUD operations with Isar)
- [x] M4-T3 to M4-T7: Day, Week, Month, Year, and Agenda views implementation
- [x] M4-T8: Full EventFormSheet — color picker, date/time pickers, recurrence type, reminder chips, category chips, location, all-day toggle, delete
- [x] M4-T9: Recurring Events Engine (Offline recurrence expander supporting Daily, Weekly, Monthly, Yearly, and Custom patterns with full unit test coverage)
- [x] M4-T10: Reminders & Notifications (Implemented NotificationService wrapper for flutter_local_notifications, scheduled exact reminders for events, handled past exclusions, and verified with unit tests)

## Pending Work
- [ ] M4-T11 to M4-T15: Multiple Calendars, ICS Import/Export, Search/Filters, Time Zone Support
- [ ] Milestone 5: Task Manager
- [ ] Milestone 6: Notes
- [ ] Milestone 7: Backend & Sync Infrastructure
- [ ] Milestone 8: Synchronization
- [ ] Milestone 9: Website
- [ ] Milestone 10: Polish & Release

## Known Bugs
None.

## Technical Debt
None.

## Design Notes
- PocketDesk UI inspired by dashboard reference (resource-and-instruction/deskatod-refral.png)
- Loading screen inspired by resource-and-instruction/loding-page-degine.png
- Official logo at resource-and-instruction/poket-desk (1).png
- Website design inspired by awsmd.com design system but ORIGINAL — not a copy
- App uses dark-mode friendly Material 3 theming
- PocketDesk color palette: deep indigo primary, rich accent, soft backgrounds — premium feel

1. Begin M1-T3: Create custom app theme and design system tokens in lib/app/theme/
2. Implement light/dark mode configuration
3. Set up GoRouter configuration (M1-T4)
4. Setup Clean Architecture folder structures
5. Implement error boundary and logging system (M1-T5)
6. Write core utilities and formatting helpers (M1-T6)

## Notes for Agent
- Always read this file before any task
- Always update this file after any task
- One task at a time — never rush
- Run flutter analyze before marking any task done
- Update TASKS.md and CHANGELOG.md after every task

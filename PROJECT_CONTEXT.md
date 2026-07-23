# PocketDesk — Project Context
## Last Updated: 2026-07-23
## Current Milestone: Milestone 1 — Foundation
## Current Task: M1-T1 — Project Setup (NEXT)

## Project Summary
[Brief description of PocketDesk]

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
- [x] README.md created
- [x] PROJECT_SPEC.md created
- [x] ARCHITECTURE.md created
- [x] ROADMAP.md created
- [x] TASKS.md created
- [x] DATABASE_SCHEMA.md created
- [x] API.md created
- [x] SYNC_PROTOCOL.md created
- [x] WEBSOCKET_PROTOCOL.md created
- [x] SECURITY.md created
- [x] TEST_PLAN.md created
- [x] PROJECT_CONTEXT.md created
- [x] CHANGELOG.md created

## Pending Work
- Phase 2: Architecture review and approval
- Phase 3: Implementation starting with Milestone 1 (Foundation)
  - Flutter project creation
  - Clean Architecture folder structure
  - Design System & AppTheme setup
  - GoRouter configuration
  - Error handling infrastructure
  - Core utilities

## Known Bugs
None yet — project not started.

## Technical Debt
None yet.

## Design Notes
- PocketDesk UI inspired by dashboard reference (resource-and-instruction/deskatod-refral.png)
- Loading screen inspired by resource-and-instruction/loding-page-degine.png
- Official logo at resource-and-instruction/poket-desk (1).png
- Website design inspired by awsmd.com design system but ORIGINAL — not a copy
- App uses dark-mode friendly Material 3 theming
- PocketDesk color palette: deep indigo primary, rich accent, soft backgrounds — premium feel

## Next Steps (in order)
1. Await architecture review/approval from user
2. Begin M1-T1: Create Flutter project
3. Set up Clean Architecture folder structure
4. Configure pubspec.yaml with all dependencies
5. Create AppTheme design system
6. Set up GoRouter
7. Create core utilities

## Notes for Agent
- Always read this file before any task
- Always update this file after any task
- One task at a time — never rush
- Run flutter analyze before marking any task done
- Update TASKS.md and CHANGELOG.md after every task

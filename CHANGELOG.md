# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

# PocketDesk Development Roadmap

This document outlines the milestones and specific tasks required to complete PocketDesk.

## Milestone 1 - Foundation
**Focus:** Project Setup, Flutter config, Clean Architecture skeleton, Design System/Theme, Routing, Error handling.

*   [ ] **Task 1.1: Initial Setup** (Complexity: Low)
    *   Initialize Flutter project.
    *   Configure flavors (Dev, Prod).
    *   Set up CI/CD skeleton (GitHub Actions).
*   [ ] **Task 1.2: Architecture Skeleton** (Complexity: Medium)
    *   Create Clean Architecture folder structure.
    *   Set up Riverpod and GoRouter.
    *   Configure global error handling and logging (Logger).
*   [ ] **Task 1.3: Design System** (Complexity: High)
    *   Define design tokens (colors, typography, spacing).
    *   Implement Material 3 `AppTheme`.
    *   Create base shared widgets (Buttons, TextFields, Cards).

## Milestone 2 - Authentication
**Focus:** Local auth (login, register, secure storage, Argon2 hashing, profile setup).

*   [ ] **Task 2.1: Local Storage & Security** (Complexity: Medium)
    *   Implement `flutter_secure_storage` repository.
    *   Integrate Argon2 hashing for passwords.
*   [ ] **Task 2.2: Auth Flow UI** (Complexity: Medium)
    *   Build Onboarding, Register, and Login screens.
    *   Implement form validation.
*   [ ] **Task 2.3: Profile Setup** (Complexity: Low)
    *   Create local user profile creation.
    *   *Dependencies:* Task 2.1, 2.2.

## Milestone 3 - Dashboard
**Focus:** Dashboard layout, widgets, statistics, quick actions, responsive layout.

*   [ ] **Task 3.1: Dashboard Layout** (Complexity: Medium)
    *   Implement responsive grid layout (mobile vs. desktop).
*   [ ] **Task 3.2: Quick Actions & Stats** (Complexity: Low)
    *   Create quick action floating buttons.
    *   Design mock statistic cards (upcoming tasks, events).

## Milestone 4 - Calendar
**Focus:** All views (day/week/month/year/agenda), event CRUD, recurring events, reminders, ICS import/export.

*   [ ] **Task 4.1: Isar Database Setup (Calendar)** (Complexity: High)
    *   Define Event models and Isar collections.
*   [ ] **Task 4.2: Calendar Views** (Complexity: High)
    *   Implement Day, Week, Month, and Agenda views.
    *   Add drag-and-drop support for events.
*   [ ] **Task 4.3: Event Management** (Complexity: Medium)
    *   CRUD operations for events.
    *   Implement recurring event logic.
*   [ ] **Task 4.4: ICS & Reminders** (Complexity: Medium)
    *   Implement ICS import/export logic.
    *   Integrate local notifications for reminders.

## Milestone 5 - Task Manager
**Focus:** Lists, folders, priorities, subtasks, recurring tasks, reminders.

*   [ ] **Task 5.1: Task Database** (Complexity: Medium)
    *   Define Task, Folder, and Subtask models in Isar.
*   [ ] **Task 5.2: Task UI** (Complexity: High)
    *   Build list views, folder navigation.
    *   Implement drag-and-drop reordering.
*   [ ] **Task 5.3: Task Logic** (Complexity: Medium)
    *   Implement priorities, recurring logic, and status toggles.

## Milestone 6 - Notes
**Focus:** Rich text editor, Markdown, checklists, images, search, pinning, folders.

*   [ ] **Task 6.1: Editor Core** (Complexity: High)
    *   Integrate rich text / Markdown editor.
    *   Implement inline checklists and image embedding.
*   [ ] **Task 6.2: Organization & Search** (Complexity: Medium)
    *   Folder management and pinning logic.
    *   Implement full-text search via Isar.

## Milestone 7 - Backend & Sync Infrastructure
**Focus:** Dart/Shelf backend, WebSocket server, QR pairing, delta sync, conflict resolution.

*   [ ] **Task 7.1: Embedded Shelf Server** (Complexity: High)
    *   Initialize Shelf server within the Flutter app.
    *   Create REST endpoints for device discovery/pairing.
*   [ ] **Task 7.2: WebSocket & Pairing** (Complexity: High)
    *   Implement WebSocket connection logic.
    *   Build QR code generation and scanning flow.
    *   Implement secure token verification (nonce, signature).

## Milestone 8 - Synchronization
**Focus:** End-to-end sync, offline queue, heartbeat, reconnect, test across devices.

*   [ ] **Task 8.1: Delta Sync Protocol** (Complexity: High)
    *   Implement change vector generation and timestamp logic.
*   [ ] **Task 8.2: Sync Engine** (Complexity: High)
    *   Build persistent offline queue.
    *   Implement Last-Write-Wins conflict resolution.
    *   Add heartbeat and automatic reconnect logic.

## Milestone 9 - Website
**Focus:** Full marketing website with all pages, OS detection, SEO, dark mode.

*   [ ] **Task 9.1: Website Structure** (Complexity: Medium)
    *   Build landing page, features, and download sections.
*   [ ] **Task 9.2: Optimization** (Complexity: Low)
    *   Implement OS detection for dynamic download buttons.
    *   Configure SEO tags and Dark mode support.

## Milestone 10 - Polish & Release
**Focus:** Performance optimization, golden tests, integration tests, accessibility, final review.

*   [ ] **Task 10.1: Testing** (Complexity: High)
    *   Write golden tests for core UI components.
    *   Implement integration tests for critical flows (auth, sync).
*   [ ] **Task 10.2: Optimization & Accessibility** (Complexity: Medium)
    *   Profile and optimize render performance.
    *   Audit and fix accessibility (semantics, contrast).
*   [ ] **Task 10.3: App Store Prep** (Complexity: Low)
    *   Prepare screenshots, metadata, and final builds.

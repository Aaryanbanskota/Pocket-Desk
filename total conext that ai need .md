# PocketDex: Complete System Architecture, Inter-Feature Blueprint & AI Constraints Reference

This is the **authoritative reference document** for the **PocketDex** project (`pocketdesk` package, version `1.2.0+3`). Any AI agent or developer reading this document will gain complete context on how the application is maintained, how features connect to each other, what dependencies power each subsystem, what is already completed, and **strictly what parts of the codebase MUST NOT be modified**.

---

## 1. Executive Summary & Maintenance Rules

### Application Purpose
PocketDex is an **offline-first, privacy-respecting, cross-platform personal productivity ecosystem** (Android, Linux, Windows, macOS, iOS, Web). It combines tasks, notes, calendar, financial tracking, world clock/timers, local P2P file sharing, personal media feed (Posts/Instants), and an AI Universal Action Agent.

### Primary Maintainability Principles
1. **Offline-First Storage**: Isar DB is the sole local source of truth. All feature data persists locally first before syncing via P2P.
2. **State Management via Riverpod**: Presentation UI elements consume Riverpod `Notifier` / `AsyncNotifier` providers. UI components NEVER invoke raw Isar queries directly.
3. **Strict Validation & Data Sanitization**: All user/AI inputs undergo HTML/script sanitization (`<script>` tags stripped, trim, non-empty validation) before reaching database entities.
4. **Clean Code Generation**: Built with `build_runner`, `riverpod_generator`, `isar_generator`, and `json_serializable`. Code generators produce `.g.dart` files.

---

## 2. STRICT RULES: WHAT NOT TO TOUCH & RESTRICTION MATRIX

To prevent regressions, broken builds, or compromised security, the following components are strictly restricted:

```
+-----------------------------------------------------------------------------------------+
|                               DO NOT TOUCH RESTRICTIONS                                 |
+-------------------------------------------------+---------------------------------------+
| Component / File Path                           | Restriction & Rationale               |
+-------------------------------------------------+---------------------------------------+
| lib/core/database/isar_provider.dart            | CRITICAL. Database schemas registry.  |
| lib/core/router/app_router.g.dart               | Generated file. Do not edit manually. |
| lib/features/posts/ (Personal Feed)             | STRICTLY READ-ONLY FOR AI AGENTS.     |
| lib/features/trash/ (Trash System)              | STRICTLY READ-ONLY FOR AI AGENTS.     |
| FocusNode Instantiations in chat_page.dart      | MUST remain persistent on State class.|
| Isar Model Schema Signatures (@Collection)      | Do not modify without Isar generator. |
| P2P Encryption Core (lib/core/sync/cryptography)| Crypto protocol for pairing & sync.   |
+-------------------------------------------------+---------------------------------------+
```

### Detailed AI Agent Restrictions
1. **Personal Feed (`lib/features/posts/`)**:
   - **READ-ONLY FOR AI**. The AI Agent is **FORBIDDEN** from creating, updating, or deleting posts or instants.
2. **Trash System (`lib/features/trash/`)**:
   - **READ-ONLY FOR AI**. The AI Agent can inspect deleted items but is **FORBIDDEN** from permanently purging or restoring trash items.
3. **Deletion Safety**:
   - Deletion across all features (Notes, Tasks, Calendar, Expenses) is **DISABLED BY DEFAULT** for the AI Agent. If the user invokes `/delete`, the AI must request explicit interactive confirmation.
4. **Chat Input Focus Nodes**:
   - `_msgFocusNode` and `_keyboardFocusNode` in `chat_page.dart` MUST be declared on `_ChatPageState` and disposed cleanly. **NEVER** write `focusNode: FocusNode()` inline inside `build()` as it breaks keyboard listeners and unmounts the text field on `/` keypresses.

---

## 3. Core Dependencies & Feature Mapping

```
+-------------------+---------------------------+-----------------------------------------------------------+
| Feature Module    | Dependencies Used         | Underlying System Process & Responsibilities              |
+-------------------+---------------------------+-----------------------------------------------------------+
| Database Core     | isar, isar_flutter_libs,  | Manages local NoSQL storage, 11 schemas, schemas timeout,|
|                   | path_provider             | and reactive queries across app startup.                  |
+-------------------+---------------------------+-----------------------------------------------------------+
| State & Routing   | flutter_riverpod,         | Dependency injection, auth state listening, declarative   |
|                   | go_router                 | route redirection (splash, login, onboarding, dashboard).|
+-------------------+---------------------------+-----------------------------------------------------------+
| AI Action Agent   | http, flutter_riverpod,   | Communicates with OpenRouter API, parses natural language |
|                   | isar                      | slash commands (/create, /edit, etc.), executes JSON      |
|                   |                           | payloads through Notifiers.                               |
+-------------------+---------------------------+-----------------------------------------------------------+
| P2P & File Share  | web_socket_channel,       | Discovers local peers, executes AES-GCM encrypted delta  |
|                   | cryptography, qr_flutter  | sync, scans pairing QR codes, streams files over socket.  |
+-------------------+---------------------------+-----------------------------------------------------------+
| Camera & Scanning | camera, mobile_scanner    | Viewport camera stream, instant capture, flash control,   |
|                   |                           | platform detection (Linux webcam / Android camera switcher)|
+-------------------+---------------------------+-----------------------------------------------------------+
| Notifications     | flutter_local_notifications| Schedules task reminders, calendar event alerts, alarms  |
|                   | timezone                  | across local device background services.                  |
+-------------------+---------------------------+-----------------------------------------------------------+
```

---

## 4. Feature Interconnections & Data Flow Architecture

The following diagram illustrates how feature modules interact with the database, Riverpod state layer, P2P sync, and the AI Universal Action Agent:

```
                                  +-----------------------+
                                  |    User Input / UI    |
                                  +-----------+-----------+
                                              |
                                              v
                                  +-----------------------+
                                  |  AI Chat (/create,    |
                                  |   /edit, /search)     |
                                  +-----------+-----------+
                                              |
                                (Emits JSON Action Payload)
                                              |
                                              v
+-----------------------------------------------------------------------------------+
|                            Riverpod State Notifiers Layer                         |
|  (tasksProvider, notesProvider, calendarEventsProvider, moneyProvider, etc.)      |
+--------+--------------------+---------------------+--------------------+----------+
         |                    |                     |                    |
         v                    v                     v                    v
  +--------------+     +--------------+      +--------------+     +--------------+
  |  Task Model  |     |  Note Model  |      | Calendar     |     | Expense/     |
  |  & Service   |     |  & Service   |      | Event Model  |     | Wallet Model |
  +------+-------+     +------+-------+      +------+-------+     +------+-------+
         |                    |                     |                    |
         +--------------------+----------+----------+--------------------+
                                         |
                                         v
                         +-------------------------------+
                         |   Isar Local NoSQL Database   |
                         |   (11 Collections & Schemas)  |
                         +---------------+---------------+
                                         |
                                         v
                         +-------------------------------+
                         |     P2P WebSocket Sync        |
                         |  (Delta Engine & Pairing)     |
                         +-------------------------------+
```

### Feature Integration Matrix
1. **Chat & Action Execution**:
   - `ChatPage` -> `AiSettingsProvider` (Fetches API Key) -> `OpenRouter HTTP` -> `_executeAIAction()` -> Invokes `tasksNotifier`, `notesNotifier`, `calendarEventsNotifier`, `moneyNotifier`.
2. **Trash & Recovery**:
   - When entities are deleted from Tasks, Notes, or Calendar, they are transformed into `TrashItemModel` and moved to `trashProvider`.
3. **P2P Sync Engine**:
   - `P2PSyncService` queues sync events whenever any Isar model changes. Transmits encrypted JSON deltas over `WebSocketSyncClient`.
4. **Calendar & Tasks Interlock**:
   - `CalendarEventsNotifier` checks `tasksProvider` for tasks with due dates and renders them on the unified calendar dashboard view.
5. **Money Tracker & Dashboard**:
   - Financial summaries (`ExpenseModel`, `WalletModel`) stream into `dashboardProvider` to render home screen metrics.

---

## 5. What Is Completed & Verified

- [x] **Core Database Engine**: Isar 3.1 open/timeout logic and 11 collections fully mapped (`UserModel`, `CalendarEventModel`, `CalendarModel`, `TaskModel`, `NoteModel`, `WalletModel`, `ExpenseModel`, `PostModel`, `InstantModel`, `AISettingsModel`, `TrashItemModel`).
- [x] **AI Slash Action Autocomplete**: Dynamic `/` menu powered by live `capabilityRegistry` (`/create`, `/edit`, `/delete`, `/view`, `/search`, `/help`, `/summarize`, `/mark`, `/manage`).
- [x] **Chat Focus Stability**: Fixed unmounting issue on keypress by moving `KeyboardListener` focus node to state class (`_keyboardFocusNode`).
- [x] **Camera & Instant Support**: Linux webcam detection and Android camera stream preview with graceful fallback.
- [x] **P2P Pairing & Sync Protocol**: QR pairing token generation, AES encryption, and delta sync Engine.
- [x] **Navigation Structure**: Auth-aware GoRouter setup with splash, onboarding, login, register, and main dashboard routes.

---

## 6. Maintenance & Verification Commands

Whenever performing updates or adding features, execute the following workflow:

```bash
# 1. Run Flutter static analysis (MUST have 0 errors)
flutter analyze

# 2. Re-generate Riverpod and Isar code bindings (if models or annotations changed)
dart run build_runner build --delete-conflicting-outputs

# 3. Run unit and integration tests
flutter test
```

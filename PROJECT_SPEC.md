# PocketDesk Project Specification

## 1. Project Overview

**PocketDesk** is an offline-first productivity ecosystem designed to provide users with a comprehensive suite of tools to manage their daily lives. By combining a Calendar, Task Manager, Notes, and Schedule Planner into a single, cohesive application, PocketDesk eliminates the need to switch between multiple apps. The core philosophy is "offline-first" and "local-first," ensuring that user data remains private, secure, and accessible without an internet connection. Multi-device synchronization is achieved through secure, peer-to-peer local network connections.

## 2. Goals and Non-Goals

### Goals
- Provide a unified, seamless productivity experience across Android and Ubuntu Linux.
- Ensure all core functionality is available offline.
- Offer secure, reliable multi-device synchronization over local networks (LAN) without relying on third-party cloud servers.
- Deliver a highly responsive and fluid UI using Flutter and Material 3.
- Maintain high data privacy and security standards.

### Non-Goals
- Cloud-based synchronization or web-hosted user accounts.
- Collaboration features (e.g., shared calendars or task lists with other users over the internet).
- Integration with third-party productivity tools (e.g., Google Calendar, Notion) for real-time two-way sync, though one-time import/export is supported.
- Support for iOS, macOS, or Windows in the initial release phase.

## 3. Users and Personas

- **The Privacy Advocate**: Users who are skeptical of cloud services and want complete ownership of their personal data.
- **The Productivity Enthusiast**: Users who juggle multiple projects and need a unified dashboard to see their schedule, tasks, and notes in one place.
- **The Commuter/Traveler**: Users who frequently find themselves in areas with poor or no internet connectivity but still need access to their planner.
- **The Linux Power User**: Users who utilize Ubuntu as their primary desktop environment and want a native-feeling productivity app that syncs with their Android phone.

## 4. Features Specification

### 4.1 Authentication
- **Local Only**: No cloud accounts. Authentication is device-specific.
- **Credentials**: Username and password.
- **Profile**: Optional user avatar.
- **Security**: Passwords securely hashed using Argon2 and stored via `flutter_secure_storage`.

### 4.2 Dashboard
The central hub of the application.
- **Today's Schedule**: A chronological timeline of today's events and tasks.
- **Calendar Widget**: A mini month-view calendar for quick navigation.
- **Tasks & Notes**: Quick access to high-priority tasks and recently edited notes.
- **Upcoming Events**: A list of events happening in the next 7 days.
- **Statistics**: Visual summaries of task completion and productivity metrics.
- **Quick Actions**: FAB (Floating Action Button) or shortcut buttons to quickly add a new event, task, or note.
- **Pinned Widgets**: Customizable dashboard layout allowing users to pin their most used modules.

### 4.3 Calendar
- **Views**: Day, Week, Month, Year, and Agenda views.
- **Event CRUD**: Create, Read, Update, and Delete events.
- **Recurrence**: Support for recurring events with custom rules (e.g., "Every 2 weeks on Tuesday and Thursday").
- **Time Management**: Support for time zones, all-day events, and multi-day events.
- **Reminders**: Customizable local notifications.
- **Desktop Interaction**: Drag-and-drop support for moving events (Ubuntu Linux).
- **Search**: Fast, indexed search for event titles, descriptions, and locations.
- **Organization**: Multiple calendars with color-coding and categories.
- **Interoperability**: ICS (iCalendar) import and export functionality.
- **Attachments**: Ability to attach local files to events.
- **Offline Editing**: Full support for creating and modifying events offline.

### 4.4 Task Manager
- **Organization**: Lists, folders, and categories.
- **Attributes**: Priority levels (Low, Medium, High, Urgent), due dates, and reminders.
- **Advanced Tasks**: Recurring tasks and nested subtasks.
- **Content**: Support for adding notes and attaching files to tasks.
- **Tracking**: Task history and archiving of completed tasks.
- **Discovery**: Robust search and filtering capabilities (e.g., "Show high priority tasks due today").

### 4.5 Notes
- **Editor**: Rich text and Markdown support.
- **Elements**: Checklists, embedded images, and file attachments.
- **Organization**: Folders, tags, and pinning of important notes.
- **Discovery**: Full-text search across all notes.

### 4.6 Multi-device Sync
Peer-to-peer synchronization over local networks.
- **Pairing**: QR code-based pairing process.
- **Security Tokens**: Uses cryptographic tokens containing device ID, user ID, nonce, expiration time, public key, and digital signature.
- **Transport**: Encrypted WebSockets (WSS/TLS over local IP).
- **Data Transfer**: Delta sync (only syncing changed data since the last sync).
- **Conflict Resolution**: Automated conflict resolution using timestamp-based Last-Writer-Wins (LWW) or manual prompt for complex conflicts.
- **Offline Queue**: Actions performed while un-synced are queued and processed automatically upon connection.

### 4.7 User Profile
- **Information**: Username, password management, and avatar.
- **Preferences**: App theme (Light/Dark/System), notification settings.
- **Device Management**: View and manage linked devices, with the ability to revoke access.

### 4.8 Website (Marketing & Support)
A static or lightweight website to promote PocketDesk.
- **Pages**: Home, Features, Downloads, Screenshots, Documentation, Release Notes, FAQ, Privacy Policy, About, Contact.
- **UX Features**: Automatic OS detection to suggest the correct download (Android APK or Linux AppImage/Snap), SEO optimization, and Dark Mode toggle.

## 5. Non-Functional Requirements

- **Offline-First**: The app must function at 100% capacity without an internet connection. Network calls are strictly for local syncing.
- **Performance**:
  - App launch time under 2 seconds.
  - Smooth 60fps/120fps scrolling in calendar and lists.
  - Sub-50ms database query times using Isar.
- **Security**:
  - Data stored locally must be encrypted where applicable (e.g., credentials).
  - Local sync traffic must be encrypted to prevent snooping on public Wi-Fi.
- **Accessibility**:
  - High contrast themes.
  - Screen reader support (TalkBack on Android, Orca on Linux).
  - Scalable text sizes.

## 6. Platform Support

- **Android**: Minimum SDK 24 (Android 7.0), target SDK 34.
- **Ubuntu Linux Desktop**: Supports Ubuntu 20.04 LTS and newer. Distributed via AppImage and/or Snap.

## 7. Constraints and Assumptions

- **Constraints**:
  - Syncing requires devices to be on the same local network or connected via a VPN (e.g., Tailscale).
  - No push notifications from a server; all notifications are scheduled locally.
- **Assumptions**:
  - Users are responsible for their device security (e.g., device lock screens) to protect their local data, though sensitive app settings are secured.
  - Users will periodically back up their data using the provided export tools.

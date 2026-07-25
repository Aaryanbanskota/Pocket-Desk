# PocketDesk Database Schema

## 1. Overview
PocketDesk uses **Isar Database**, an embedded, high-performance, NoSQL local database tailored for Flutter. 
The application adopts an **offline-first** architecture, ensuring that all data is primarily read from and written to the local database before being synchronized.

## 2. User & Auth Collections

### `UserProfile`
- `id` (Id, Auto-increment)
- `username` (String, Indexed)
- `passwordHash` (String)
- `passwordSalt` (String)
- `avatarPath` (String?)
- `createdAt` (DateTime)
- `updatedAt` (DateTime)

### `LinkedDevice`
- `id` (Id, Auto-increment)
- `deviceId` (String, Indexed)
- `deviceName` (String)
- `publicKey` (String)
- `pairedAt` (DateTime)
- `lastSeenAt` (DateTime)
- `isActive` (bool)

## 3. Calendar Collections

### `CalendarEvent`
- `id` (Id, Auto-increment)
- `title` (String)
- `description` (String?)
- `startDateTime` (DateTime, Indexed)
- `endDateTime` (DateTime, Indexed)
- `isAllDay` (bool)
- `location` (String?)
- `calendarId` (int)
- `colorHex` (String?)
- `recurrenceRule` (String?)
- `recurrenceExceptions` (List<String>)
- `reminders` (List<int>)
- `attachments` (List<String>)
- `timeZone` (String)
- `createdAt` (DateTime)
- `updatedAt` (DateTime)
- `syncedAt` (DateTime?)
- `isDeleted` (bool)

### `Calendar`
- `id` (Id, Auto-increment)
- `name` (String)
- `colorHex` (String)
- `isDefault` (bool)
- `isVisible` (bool)
- `createdAt` (DateTime)

### `RecurrenceRule`
- `id` (Id, Auto-increment)
- `freq` (Enum)
- `interval` (int)
- `until` (DateTime?)
- `count` (int?)
- `byDay` (List<int>?)
- `byMonth` (List<int>?)
- `byMonthDay` (List<int>?)

## 4. Task Collections

### `TaskList`
- `id` (Id, Auto-increment)
- `name` (String)
- `colorHex` (String)
- `icon` (String?)
- `folderId` (int?)
- `sortOrder` (int)

### `TaskFolder`
- `id` (Id, Auto-increment)
- `name` (String)
- `colorHex` (String?)

### `Task`
- `id` (Id, Auto-increment)
- `title` (String)
- `description` (String?)
- `listId` (int)
- `priority` (Enum)
- `dueDate` (DateTime?)
- `completedAt` (DateTime?)
- `isCompleted` (bool)
- `parentTaskId` (int?)
- `recurrenceRule` (String?)
- `reminders` (List<int>)
- `attachments` (List<String>)
- `notes` (String?)
- `tags` (List<String>)
- `createdAt` (DateTime)
- `updatedAt` (DateTime)
- `isDeleted` (bool)

## 5. Notes Collections

### `NoteFolder`
- `id` (Id, Auto-increment)
- `name` (String)
- `colorHex` (String?)

### `Note`
- `id` (Id, Auto-increment)
- `title` (String)
- `content` (String)
- `type` (Enum: markdown / richtext / checklist)
- `folderId` (int?)
- `isPinned` (bool)
- `tags` (List<String>)
- `attachments` (List<String>)
- `createdAt` (DateTime)
- `updatedAt` (DateTime)
- `isDeleted` (bool)

### `Attachment`
- `id` (Id, Auto-increment)
- `fileName` (String)
- `filePath` (String)
- `fileSize` (int)
- `mimeType` (String)
- `createdAt` (DateTime)

## 6. Sync Collections

### `SyncQueue`
- `id` (Id, Auto-increment)
- `entityType` (String)
- `entityId` (int)
- `operation` (Enum: create / update / delete)
- `payload` (String/JSON)
- `createdAt` (DateTime)
- `retryCount` (int)
- `status` (Enum)

### `SyncState`
- `id` (Id, Auto-increment)
- `deviceId` (String)
- `lastSyncAt` (DateTime)
- `vectorClock` (String/JSON)

## 7. Settings Collection

### `AppSettings`
- `id` (Id, Single Record)
- `theme` (Enum)
- `language` (String)
- `notificationsEnabled` (bool)
- `syncEnabled` (bool)
- `defaultCalendarId` (int?)
- `defaultTaskListId` (int?)

## 8. Indexes and Relationships
- **Indexes:** Primary keys are implicitly indexed. Additional indexes include `username` in `UserProfile`, `deviceId` in `LinkedDevice`, `startDateTime` and `endDateTime` in `CalendarEvent`.
- **Relationships:** Uses Isar Links where appropriate, though IDs are often mapped manually to support multi-device syncing easily (e.g., `calendarId`, `folderId`).

## 9. Migration Strategy
- **Additive Changes:** New fields are appended as optional or with default values without breaking the local schema.
- **Breaking Changes:** Require explicit migration routines mapped to app version changes, utilizing Isar's upgrade helpers.
- **Sync Migrations:** Ensuring data from older schema versions sync seamlessly by keeping server-side schemas backward compatible or routing through adapter layers.

## 10. Data Integrity Rules
- Soft deletes are utilized (via `isDeleted` flags) across core entities (CalendarEvent, Task, Note) to resolve synchronization conflicts properly.
- All timestamp fields (`createdAt`, `updatedAt`, `syncedAt`) are maintained strictly in UTC.
- Data dependencies are enforced in UI/Business logic before database insertion (e.g. valid `calendarId` for `CalendarEvent`).

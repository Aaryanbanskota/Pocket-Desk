# PocketDesk Test Plan

## 1. Testing Philosophy
Testing is done alongside code development. We utilize Test-Driven Development (TDD) for complex logic and strive for high coverage on critical paths to ensure application stability and reliability.

## 2. Test Types
- **Unit Tests:** Focus on domain logic, use cases, repositories, providers, and utilities.
- **Widget Tests:** Cover all screens and key UI widgets.
- **Golden Tests:** Visual regression testing for key UI components.
- **Integration Tests:** Full feature flows tested end-to-end.
- **Performance Tests:** Measure startup time, DB queries, and widget rebuilds.
- **Sync Tests:** Verify offline queue, conflict resolution, and reconnect logic.
- **Security Tests:** Ensure password hashing, token validation, and replay prevention mechanisms work.

## 3. Test Structure
```
test/
  unit/
    auth/
    calendar/
    tasks/
    notes/
    sync/
  widget/
    auth/
    dashboard/
    calendar/
    tasks/
    notes/
  golden/
  integration/
  performance/
```

## 4. Critical Test Cases
- **Auth:**
  - Login with valid credentials
  - Login with wrong password
  - Register new user
  - Password hash verification
- **Calendar:**
  - Create, edit, and delete event
  - Recurring event generation
  - ICS import/export parsing
- **Tasks:**
  - Create and complete task
  - Subtask nesting behavior
  - Recurring task logic
- **Notes:**
  - Create note
  - Markdown rendering correctness
  - Search functionality
- **Sync:**
  - Offline queue persistence
  - Conflict resolution mechanisms
  - Reconnect drain logic

## 5. Test Tools
- `flutter_test`
- `mockito` / `mocktail`
- `integration_test`
- `golden_toolkit`

## 6. Coverage Targets
- **Unit Tests:** >80% coverage
- **Widget Tests:** >70% coverage
- **Critical Paths:** 100% coverage

## 7. CI Integration
Our GitHub Actions workflow automatically runs:
- Linting and static analysis
- All unit and widget tests
- Golden tests validation
- Code coverage reporting

## 8. Performance Benchmarks
- **App startup:** <2s cold start
- **DB queries:** <50ms for lists
- **Calendar render:** <16ms/frame
- **Sync:** <5s for 1000 entity full sync

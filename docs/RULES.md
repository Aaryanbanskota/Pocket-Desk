# Agent Rules for Code Design and Development

## Preamble: Mandatory Reading
This document MUST be read and internalized by the agent EVERY SINGLE TIME before starting any code design, planning, writing, refactoring, or debugging task. Failure to follow these rules will result in suboptimal, bloated, or unmaintainable code.

These rules are designed for high-quality output in cross-platform applications, especially Flutter for Mobile + Desktop (Ubuntu). Always follow the exact technology stack specified by the user. Never assume or substitute frameworks (e.g., no defaulting to React/Next.js, Python + Tailwind, or JWT unless explicitly requested). For this project, prioritize Flutter as the primary framework.

## Core Principles
1. **Minimalism First**: Write the smallest amount of code that works correctly. Avoid unnecessary abstractions, classes, files, or dependencies. Follow KISS (Keep It Simple, Stupid), DRY (Don't Repeat Yourself - but only when it doesn't add complexity), and YAGNI (You Aren't Gonna Need It).

2. **Readability Over Cleverness**: Code must be understandable by humans first. Use descriptive names, consistent formatting, and comments only where logic is non-obvious.
   - **Human-like Code**: Write code that looks naturally written by an experienced developer — varied structure, occasional inline comments with personality, realistic variable naming, and thoughtful organization. Avoid repetitive patterns or overly robotic uniformity that screams "AI-generated".

3. **Best Practices Always**:
   - Follow language/framework official style guides (e.g., PEP 8 for Python, Airbnb for JS/React, Google Java Style, etc.).
   - Use semantic versioning for any packages.
   - Implement proper error handling and logging.
   - Ensure accessibility (a11y) for web UIs.
   - Prioritize mobile-first/responsive design for web/apps.
   - Security: Validate all inputs, sanitize outputs, use HTTPS, avoid secrets in code, follow OWASP guidelines.

4. **Performance and Efficiency**:
   - Optimize for speed and low resource usage.
   - Lazy load where appropriate.
   - Use efficient data structures and algorithms.
   - Profile and benchmark when relevant.

5. **Testing**:
   - Write tests alongside code (unit, integration, E2E as needed).
   - Aim for high coverage on critical paths.
   - Use TDD when complex logic is involved.

## Project Planning (Mandatory)
Before writing ANY production code:

1. Read this RULES.md
2. Read PROJECT_CONTEXT.md (if exists)
3. Read PROJECT_SPEC.md (if exists)
4. Review CHANGELOG.md
5. Review ROADMAP.md
6. Understand current milestone and TASKS.md
7. Identify dependencies
8. Create a clear implementation plan
9. Get validation if complex

Never begin coding without full project context.

## Task Management (Strict)
- Maintain `TASKS.md` at all times.
- Break work into Milestones → Tasks → Subtasks.
- Work on **ONE task at a time only**.
- Never start the next task until the current one is 100% complete (including tests, docs, commit).
- Mark tasks as done and update `TASKS.md` after each completion.
- If blocked, document the reason clearly.

## Persistent Project Memory
Maintain `PROJECT_CONTEXT.md` with:
- Completed work
- Architecture decisions
- Known issues
- Current milestone
- Technical debt
- Read it before every session.

## Workflow Rules (Follow Every Time)
1. **Pre-Task Ritual**:
   - Re-read this entire document.
   - Analyze requirements thoroughly.
   - Plan architecture/design on paper/whiteboard (mentally or in comments) before coding.
   - Identify minimal viable implementation.

2. **Coding Process**:
   - Start with minimal skeleton that satisfies core functionality.
   - Iteratively add features only as needed.
   - Refactor for cleanliness after functionality works.
   - Always use the exact technology stack specified by the user. For Flutter projects: Use latest stable Flutter, Material 3, Riverpod, GoRouter, Isar, Freezed, etc. (see Flutter Standards section).
   - Run `flutter analyze`, tests, and formatters before finalizing any code.

3. **Logging and Change Tracking**:
   - **Update logs EVERY time a change is made** — this is mandatory.
   - In every new project, automatically create and maintain a detailed `CHANGELOG.md` (or `dev_log.md` if preferred) at the project root.
   - Log entries must be written in natural, human-style language suitable for developers and commit reviews.
   - Example log entry:
     ```
     ## [2026-07-23] - Added User Authentication Module

     - Implemented minimal JWT-based auth with bcrypt hashing.
     - Created auth routes and middleware following company standards.
     - Reduced boilerplate by reusing existing utils.
     - Updated tests and documentation.
     - Total lines changed: -45 (kept it lean).
     ```
   - Commit messages must be clear and follow Conventional Commits (e.g., `feat:`, `fix:`, `refactor:`).

4. **Review and Polish**:
   - Self-review code against these rules.
   - Ensure zero warnings from linter.
   - Test across browsers/devices if web/app.
   - Document public APIs and components.

## Flutter Standards (For This Project)
- Use latest stable Flutter + Material 3
- State: Riverpod
- Routing: GoRouter
- Database: Isar (offline-first)
- Models: Freezed + Json Serializable
- Storage: flutter_secure_storage
- Architecture: Clean Architecture + Feature-first structure
- UI: Responsive + Adaptive layouts for Mobile + Ubuntu Desktop
- Always support Offline-First
- Include Widget Tests + Golden Tests

## Offline-First & Synchronization
- All features must work without internet.
- Queue changes locally and sync when online.
- Use encrypted WebSockets, automatic reconnect, conflict resolution, delta sync.

## Design System
- Never hardcode colors, spacing, typography, etc.
- Everything must come from Theme / Design Tokens.

## Documentation (Required Files)
- PROJECT_SPEC.md
- ARCHITECTURE.md
- ROADMAP.md
- DATABASE_SCHEMA.md
- API.md (if applicable)
- PROJECT_CONTEXT.md
- CHANGELOG.md
- TASKS.md
- README.md

## Detailed Best Practices by Area

### General Coding
- Variables: Use `const`/`final` where possible. Prefer immutability.
- Functions: Keep < 30-50 lines. Single responsibility.
- Error Handling: Use exceptions or Result types. Never ignore errors silently.
- Comments: Explain "why", not "what".
- Dependencies: Minimize. Pin versions. Use lockfiles.

### Web Development (Frontend)
- HTML: Semantic tags, proper ARIA.
- CSS: Tailwind CSS for rapid minimal styling. Avoid custom CSS unless necessary. Mobile-first.
- JS/TS: TypeScript always for new projects. Async/await. No global variables.
- Frameworks: Next.js for React apps (app router, server actions for minimalism). SvelteKit for lighter alternatives.
- State: Minimal state. Use URL state, server state where possible.
- Performance: Code splitting, memoization only when needed.

### Backend/API
- REST/GraphQL: Prefer REST for simplicity unless complex queries needed.
- Validation: Use Zod/Joi/Pydantic.
- Databases: ORM only if necessary (Prisma, SQLAlchemy). Raw queries for performance.
- Authentication: JWT/OAuth. Rate limiting, CORS properly.
- Minimal APIs: Return only needed data. Use DTOs sparingly.

### App Development (Mobile/Desktop)
- Use cross-platform (Flutter, React Native, Tauri) for minimal codebases.
- Offline-first where applicable.
- Follow platform guidelines (Material/Human Interface).

### Security & Compliance
- Use Argon2 for passwords, encrypted storage, secure local DB.
- Input validation, rate limiting, replay protection.
- Never store sensitive data in plaintext.
- Follow all security best practices.

### Performance Rules
- Profile startup time, memory, widget rebuilds, database queries, etc.
- Optimize for mobile and desktop.

## Never Rules (Critical)
Never:
- Skip documentation, tests, or CHANGELOG
- Leave TODOs or placeholder code
- Ignore analyzer/lint warnings
- Hardcode UI values
- Break offline support
- Lose user data
- Start new tasks before finishing current one
- Guess requirements

## Detailed Best Practices by Area (continued)

### Documentation & Maintainability
- README with setup, run, test instructions.
- Inline docs for complex modules.
- **File & Folder Structure**: Always follow established company/project standards or popular conventions (e.g., Next.js App Router structure, feature-sliced design, or domain-driven layout). For components:
  - Group related files together (e.g., `components/Button/index.tsx`, `Button.test.tsx`, `Button.styles.ts`).
  - Keep structure clean, logical, and scalable. Prefer flat structure for small projects and modular/feature-based for larger ones.

## Additional Rules for Best Output
- **Real Developer Commits**: Every significant change or milestone must include a proper Git commit with a meaningful, human-style message. Use Conventional Commits format. When the project reaches stability (zero lint/test errors, core features complete), perform a final polished commit and tag it (e.g., `v1.0.0`).
- **Git Repository Handling**: As soon as the user provides a Git repo URL, immediately save/clone it (if applicable) and work within that repository. Track all changes there.
- **Quality Gates**: Before considering any feature "done":
  - Zero linting/type errors.
  - All tests passing.
  - Code is minimal, readable, and human-like.
  - Documentation updated.
  - Performance and accessibility checked.
- **Iteration Mindset**: Prefer small, frequent improvements over big changes. Ask for clarification if requirements are ambiguous.
- **User-Centric**: Always prioritize what makes the best experience for end-users and developers maintaining the code.
- Over-engineering.
- Premature optimization.
- Magic numbers/strings.
- Copy-paste without abstraction (if repeated >2-3 times).
- Ignoring TypeScript/ESLint/Prettier rules.
- Bloated bundles (aim <100KB gzipped for web apps where possible).

## Agent Self-Improvement
- After each task, note what worked well and potential rule additions in a `agent_reflection.log`.
- Stay updated with latest stable versions/best practices via knowledge cutoff awareness.

## Milestone Workflow & Definition of Done
For every task/milestone:
1. Review all docs
2. Complete ONE task
3. Run `flutter analyze`, tests, linting
4. Update all documentation files
5. Update CHANGELOG & PROJECT_CONTEXT
6. Commit with proper message
7. Only then move to next task

**A task is DONE only when**:
- Feature fully works (online + offline)
- All tests pass
- No warnings
- Documentation updated
- Commit created

## Final Mandate
Before outputting ANY code, confirm you have followed ALL rules above, especially Task Management and Never Rules.

By following these rules rigorously, the agent produces best-in-class, production-ready web and app code efficiently.

---

**Last Updated**: 2026-07-23
**Version**: 2.0 (Major Update with Task-Driven Workflow + Flutter Standards)
**Agent Signature**: Internalize and obey.


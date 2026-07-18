# Tomo AI — Project Instructions

Local-first Android task agent (Kotlin/Compose). Full plan: `ROADMAP.md` (technology rationale, milestones, best practices) and `local-task-agent-plan.md` (original product plan). Read `ROADMAP.md` before making any architecture or dependency decision not already covered here — this file is the fast-reference summary, that one is the source of truth.

## Identity

- Package / namespace: `com.nidev.tomoai`
- minSdk 24, targetSdk 37, compileSdk 37 (Android 17 "Cinnamon Bun" — highest available SDK; re-verify still current before Week 1 build work starts)
- Single Gradle module (`:app`) — don't split into multi-module until build times demand it

## Tech stack quick reference

| Layer | Choice |
|---|---|
| UI | Jetpack Compose + Material 3 |
| Language | Kotlin 2.3.x, Compose Compiler Gradle plugin |
| DI | Hilt (2.59+, AGP 9-compatible) |
| DB | Room 2.7.x stable, via KSP (not kapt) |
| Async | Coroutines + Flow |
| Exact reminders | AlarmManager (`setExactAndAllowWhileIdle`), gated on `canScheduleExactAlarms()` |
| Reboot rescheduling / non-critical work | WorkManager |
| LLM calls | Anthropic Claude Messages API, forced tool use (`create_task` tool) |
| HTTP | Retrofit + OkHttp |
| JSON | kotlinx.serialization |
| Navigation | Compose Navigation |
| Date/time | kotlinx-datetime in `domain/`, `java.time` (desugared) at the Android boundary |
| Recurrence | `org.dmfs:lib-recur`, RRULE strings on disk |
| Logging | Timber (no-op tree in release) |
| Lint | ktlint + detekt, run in CI on every push |

## Architecture rules (enforce these, don't just aspire to them)

```
com.nidev.tomoai/
├── presentation/   Compose screens, ViewModels, StateFlow UI state
├── domain/         Pure Kotlin — Task, Recurrence, Priority, use cases, repository interfaces
├── data/           Room, TaskRepositoryImpl, AlarmScheduler/BootCompletedReceiver, AgentClient
└── di/             Hilt modules
```

- **`domain/` never imports `android.*`.** If a use case needs `Context` or any Android import, the abstraction has leaked — push it behind a `repository` interface implemented in `data/`. This is what keeps use cases unit-testable on the plain JVM.
- Manual entry and agent-parsed entry both terminate in the same `AddTask` use case. Don't build two code paths that write tasks differently.
- Every screen defines empty, loading, and error states explicitly — no bare happy-path-only composables.

## Non-negotiables

1. **Never trust LLM output blindly.** Validate every field from the `create_task` tool response (date parses and is in a sane range, recurrence/priority are valid enum values, title is non-empty and bounded) before it touches Room. Validation failure is a normal path with a test, not a crash.
2. **Offline-first is a hard boundary.** The only network call anywhere in the app is the agent parse at task-creation time. Viewing, editing, completing, and notifying never touch the network. If a change would violate this, stop and flag it rather than implementing it.
3. **Exact alarms are permissioned and can be denied or revoked.** Always check `canScheduleExactAlarms()` before scheduling; degrade to a WorkManager-based inexact reminder with a visible in-app notice rather than silently dropping it.
4. **Never block main thread.** Room, AlarmManager scheduling, and the API call are all off `Main` via coroutines — no exceptions for "small" work.
5. **Secrets never ship unprotected.** API key comes from `local.properties` → `BuildConfig`, is never logged (not even at `DEBUG`/`BASIC` interceptor level in release builds), and is never committed.
6. **On agent parse failure (network, timeout, malformed response, validation failure), fall back to the manual entry form pre-filled with the raw text.** Never fail silently, never crash.

## Working conventions

- Conventional commits: `feat:`, `fix:`, `test:`, `chore:`, `refactor:`. One logical change per commit.
- Every use case in `domain/usecase/` gets a unit test before it's considered done.
- Run before considering any change complete: `./gradlew ktlintCheck detekt testDebugUnitTest`.
- CI (GitHub Actions) must be green before merging to `main`.
- Don't start v2 features (NL queries, voice input, widget) until the Week 5 gate in `ROADMAP.md` §5 is met: full test suite green, every screen has defined empty/loading/error states.

## Collaboration workflow (author-reviewed, branch-per-task)

These rules govern how every task gets worked on, not just how the code is written. They apply starting now, to every issue in the tracker.

- **Branch per task.** Every issue gets its own branch off `main`: `task/<issue-number>-<short-slug>` (e.g. `task/1-bump-sdk-37`). Never commit directly to `main`.
- **Decompose before starting.** If an issue is big enough that reviewing the diff in one pass would be a slog, split it into smaller sub-issues first — each sub-issue gets its own branch and its own PR. A PR should be small enough to actually review, not a dump of a whole milestone.
- **Every issue needs a problem statement and an intended solution, written before code is written.** Not after the fact as documentation — the approach gets written down first, so the author can weigh in on the plan before implementation time is spent on it. Use the issue template (`.github/ISSUE_TEMPLATE/task.md`).
- **Every PR targets `main`**, describes what changed and why, links its issue (`Closes #N`), and uses the PR template (`.github/PULL_REQUEST_TEMPLATE.md`).
- **Nothing merges without the author's explicit sign-off.** Claude opens PRs but never merges them. Merging is Nasif's call, always — the checklist in the PR template exists so that check is concrete, not a vibe.
- **Learn-before-implement gate.** Before starting any task that touches a topic Nasif hasn't worked with yet, stop and point to the relevant section of `LEARNING_RESOURCES.md` (or other reading) instead of writing code. Wait for explicit confirmation that it's been read and understood before proceeding — the goal is that every implementation is something the author can actually review line by line, not a black box handed over finished.
- **End-of-day logging happens on the issue, not in a separate log file.** At the end of a work session, comment on every issue touched that day with what was done, decisions made, and what's left. The issue thread is the devlog.

## Current status

Foundation stage — Week 1 of the roadmap. Gradle skeleton exists (`com.nidev.tomoai`, AGP 9.0.1) but Compose/Hilt/Room are not yet wired in. See `ROADMAP.md` §3 for the exact Week 1 setup checklist. Update this section as milestones complete.

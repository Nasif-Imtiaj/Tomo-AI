# Tomo AI — Build Roadmap

Local-first Android task agent. You describe a task in plain language, an LLM parses it into a structured, scheduled task, and everything after that — viewing, editing, notifying — runs fully offline. This document is the engineering plan: what we build, in what order, with which technology, and why. It expands on the original product plan (`local-task-agent-plan.md`) into an actionable roadmap tied to the actual project skeleton already in this repo (`com.nidev.tomoai`, AGP 9.0.1, minSdk 24).

Last updated: 2026-07-15.

**Decision:** target the highest available SDK rather than pin to the current compileSdk 36 skeleton. Android 17 ("Cinnamon Bun", API 37, Build-Tools 37) is the latest available SDK as of this update. Google Play only requires new app submissions to target API 36 as of August 31, 2026, but since this is a from-scratch project with no legacy constraint, build against **compileSdk 37 / targetSdk 37** from the start — that's also what Compose ≥1.12.0 requires, so it resolves the mismatch flagged below in one move instead of revisiting it later. minSdk stays 24 (no reason to raise the floor; AlarmManager/Compose/Room all support it fine with desugaring).

---

## 1. Product scope (recap)

**v1 (must-have):** free-text task capture parsed by an LLM into a structured task; manual add/edit/delete/complete as the primary fallback path; today/upcoming/overdue/done list; local notifications that survive app kill and device reboot; zero network dependency once a task exists.

**v2 (only after v1 ships cleanly):** natural-language queries over existing tasks, smarter recurrence inference, on-device speech-to-text, home-screen widget.

Scope discipline matters more than feature count here — this is a portfolio piece, and a tight, reliable v1 reads as stronger engineering judgment than a half-finished v2.

---

## 2. Technology decisions

Each row is a real decision with an alternative that was considered and rejected, not just a default pick.

| Concern | Choice | Why this, not the alternative |
|---|---|---|
| UI toolkit | Jetpack Compose + Material 3 | XML/View system is legacy-maintenance territory now; Compose is what a 2026 reviewer expects, and it maps cleanly onto unidirectional state from ViewModels. The project currently has no Compose dependency wired up — that's the first thing Week 1 adds. |
| Language / compiler | Kotlin 2.3.x with the Compose Compiler Gradle plugin | Since Kotlin 2.0, the Compose compiler ships inside the Kotlin repo and versions in lockstep with the Kotlin version, which removes the old Compose-to-Kotlin compatibility-matrix problem entirely. AGP 9.0 (already in this project) enables built-in Kotlin support, so the standalone `org.jetbrains.kotlin.android` plugin is no longer required. |
| DI | Hilt | Compile-time-safe, the de facto standard for Android, and it removes a whole class of manual-wiring bugs that a reviewer will notice in a portfolio piece. Koin was considered — it's simpler to bootstrap but is runtime service-location, which is a weaker signal for "I understand DI" than Hilt's generated graph. Pin to Hilt 2.59+ specifically, since 2.59 is the first line whose Gradle plugin supports AGP 9 (this project is already on AGP 9.0.1). |
| Local DB | Room 2.7.x (stable channel) | Room 3.0 shipped in March 2026 with Kotlin Multiplatform support and all-suspend APIs, but it's a young major version with a smaller support surface, and this app has no multiplatform target — the KMP rewrite buys nothing here. Room 2.x is now in maintenance mode (bug fixes only, no new features) but that's exactly what you want under a single-entity, single-module app: stability over churn. Use KSP, not kapt, for the annotation processor — kapt is deprecated and materially slower. |
| Async | Kotlin Coroutines + Flow | Room and WorkManager both expose first-class coroutine/Flow APIs, so this isn't really a choice — it's what the rest of the stack assumes. |
| Reminders (exact) | `AlarmManager` with `setExactAndAllowWhileIdle`, gated behind a runtime `canScheduleExactAlarms()` check | As of Android 14 (and unchanged through 2026), `SCHEDULE_EXACT_ALARM` is **denied by default** for apps targeting API 33+; it must be granted by the user via Settings (`ACTION_REQUEST_SCHEDULE_EXACT_ALARM`), and Play policy restricts the always-granted `USE_EXACT_ALARM` permission to apps whose *core function* is alarms/calendaring. A task app arguably qualifies, but treat that as a judgment call to revisit at Week 3, not an assumption baked into the manifest. Either way, the app must degrade gracefully when exact-alarm permission is absent. |
| Reminders (fallback / non-critical) | `WorkManager` for reboot-time rescheduling batch work and any non-time-critical background work | WorkManager doesn't guarantee exact timing, so it's wrong for the reminder firing itself, but it's the right tool for "reschedule all pending alarms after boot" and future sync/cleanup jobs — it's durable across process death and battery-optimization-aware in a way a raw `BroadcastReceiver` scheduling loop isn't. |
| Reboot survival | `BOOT_COMPLETED` `BroadcastReceiver` → re-reads all non-done, future-dated tasks from Room → re-arms `AlarmManager` for each | This is the piece most to-do-app tutorials skip entirely; doing it correctly (and writing a test for it) is the single highest-signal item in this codebase for a reviewer. |
| LLM call (NL parsing) | Anthropic Claude API (Messages API with forced tool use / strict JSON schema via a single `create_task` tool) | Forcing a tool call rather than free-form generation means the model's output is structurally constrained before it ever reaches your validation code — this removes an entire category of "did the JSON parse" bugs and is a legitimate architecture point to defend in the README. |
| HTTP client | Ktor Client (CIO or OkHttp engine) or Retrofit + OkHttp — either is defensible; **default to Retrofit + OkHttp** | Retrofit's interface-based API mapping and mature Kotlin ecosystem support make it the lower-friction pick for a single external endpoint; Ktor is the better choice only if multiplatform is ever a goal, which it isn't here. Add `HttpLoggingInterceptor` at `BASIC` level in debug builds only — never log full request/response bodies in release, since they may contain the user's task text. |
| JSON | kotlinx.serialization (1.11.x) | First-party Kotlin, no reflection, works cleanly with `@Serializable` data classes for both the Room-adjacent DTOs and the LLM tool-call payload. Skip Moshi/Gson — no reason to pull a second serialization library in. |
| Navigation | Compose Navigation (`androidx.navigation.compose`) | Standard, type-safe-enough with sealed-class routes, and it's what every Compose reviewer expects to see. |
| Date/time | `kotlinx-datetime` for domain-layer date math, `java.time` (desugared via `coreLibraryDesugaring`) at the Android-framework boundary (AlarmManager epoch millis, formatting) | Keeps the domain layer platform-agnostic and testable on the JVM without an Android runtime, while still using the framework-native type where AlarmManager actually requires it. minSdk stays 24 (no reason to raise the floor — Compose, Room, and AlarmManager all support it fine), so core library desugaring stays required for `java.time` below API 26 regardless of how high compileSdk/targetSdk go. |
| Recurrence | `org.dmfs:lib-recur` for anything beyond `none/daily/weekly/monthly`, RFC 5545 (`RRULE`) as the on-disk format for `custom-rrule` | Rolling a custom recurrence engine is a classic place to introduce off-by-one and DST bugs; lib-recur is a mature, purpose-built RFC 5545 implementation and storing RRULE strings means the schema doesn't need to change if recurrence gets richer later. |
| Logging | Timber | Thin wrapper, standard choice, keep it out of release logcat via a no-op tree in release builds. |
| Static analysis | ktlint (formatting) + detekt (structural/complexity lint) | Both run in CI on every push; ktlint alone catches style, detekt catches things like long methods and god classes, which matters for keeping Clean Architecture boundaries honest. |
| Secrets | API key in `local.properties` (git-ignored) injected into `BuildConfig` at build time; **never committed, never bundled unobfuscated in a shipped release APK** | For a portfolio project, README should say explicitly that a production version of this app would proxy the LLM call through a backend so the API key never ships in the client at all — call this out as a known, deliberate scope cut, not an oversight. |
| Testing | JUnit4/5 + Turbine (Flow testing) + MockK + Compose UI test + Robolectric (for the boot-receiver/alarm-scheduling logic, which needs framework classes without a real emulator) | Turbine specifically because the domain layer will expose `Flow<List<Task>>` from Room and testing Flow emissions by hand is painful. |
| CI | GitHub Actions: ktlint + detekt + unit tests on every push; instrumented tests on PR to `main` | Cheap to set up, and a green CI badge is table stakes for a portfolio repo. |

**Version pins to set in `gradle/libs.versions.toml` in Week 1** (verified current as of July 2026 — re-check each against the AndroidX/Kotlin release pages before pinning, since these move fast):

- Kotlin: 2.3.21
- Compose BOM: 2026.06.00 (compatible with compileSdk 37, which Compose ≥1.12.0 requires)
- Hilt: 2.59.x (AGP 9-compatible line)
- Room: latest 2.7.x
- kotlinx.serialization: 1.11.0
- AGP: 9.0.1 (already pinned)
- compileSdk / targetSdk: 37 (Android 17, "Cinnamon Bun" — the highest available SDK as of this update; re-verify it's still current before Week 1 actually starts, since a newer preview/stable release may have shipped by then)

---

## 3. Current repo state vs. Week 1 target

What exists today: a bare Android Studio "Empty Views" skeleton — `com.nidev.tomoai`, minSdk 24 / targetSdk 36 / compileSdk 36, only `core-ktx`, `appcompat`, and `material` as dependencies, Java 11 source compatibility, no Compose plugin, no `MainActivity`, no Hilt/Room wiring.

Week 1 setup work, concretely:

1. Bump `compileSdk`/`targetSdk` from 36 to 37 (per the SDK decision above).
2. Add the Compose Compiler Gradle plugin and Compose BOM; remove the now-redundant standalone Kotlin Android plugin reference if present (AGP 9 provides it).
3. Add Hilt Gradle plugin + KSP plugin; annotate an `Application` class with `@HiltAndroidApp`.
4. Add Room + KSP; stub the `Task` entity and `AppDatabase`.
5. Enable `coreLibraryDesugaring` for `java.time` on minSdk 24.
6. Wire ktlint + detekt Gradle plugins and a GitHub Actions workflow that runs them plus `testDebugUnitTest` on push.
7. Set up the three source-set packages described below, even before they have real content, so every subsequent PR lands in the right place.

---

## 4. Architecture

Clean Architecture, three layers, one Gradle module (`:app`) to start — split into Gradle modules later only if build times actually demand it, not preemptively:

```
com.nidev.tomoai/
├── presentation/        Compose screens, ViewModels, UI state (StateFlow)
│   ├── tasklist/
│   ├── addtask/
│   └── components/
├── domain/               Pure Kotlin, no Android imports
│   ├── model/            Task, Recurrence, Priority
│   ├── usecase/          AddTask, CompleteTask, ScheduleReminder, ParseTaskFromText
│   └── repository/       TaskRepository interface
├── data/
│   ├── local/            Room entities, DAO, AppDatabase
│   ├── repository/       TaskRepositoryImpl
│   ├── alarm/            AlarmScheduler, BootCompletedReceiver, ReminderReceiver
│   └── agent/            AgentClient, tool-schema DTOs, response validation
└── di/                   Hilt modules
```

The rule that matters: `domain/` never imports `android.*`. That's what makes `ParseTaskFromText` and the other use cases testable on the plain JVM without Robolectric or an emulator, and it's an easy thing for a reviewer to verify by grepping imports.

**Data flow for the agent path:** free-text input → `presentation` calls `ParseTaskFromText` use case → `data/agent/AgentClient` calls the Claude Messages API with the `create_task` tool forced → response validated against the schema in `data/agent` (bounds-check dates, enum-check recurrence/priority, reject if required fields missing) → on success, mapped to a domain `Task` and passed to the existing `AddTask` use case (the same one the manual-entry form uses) → `TaskRepositoryImpl` writes to Room → `AddTask` (or a dedicated `ScheduleReminder` use case) arms the `AlarmManager` alarm. On any failure — network, malformed response, schema validation — fall back to the manual entry form pre-filled with whatever raw text the user typed, never a silent failure.

---

## 5. Milestone plan (~6 weeks)

**Week 1 — Foundation**
Repo/CI setup as in §3. Room schema for `Task` (id, title, dueAt, recurrence, priority, category, isDone, createdAt). Compose list screen reading from Room, seeded with fake data. *Done when:* CI is green on a clean clone, and the list screen renders seeded tasks.

**Week 2 — Manual CRUD, no AI yet**
Add/edit/delete/complete via a manual form. This deliberately proves the entire data layer before any LLM complexity sits on top of it. Today/Upcoming/Overdue/Done grouping and sorting. Unit tests on every domain use case. *Done when:* you can fully use the app (add, edit, complete, delete, see it sorted correctly) with the LLM code not yet written.

**Week 3 — Reliable local reminders**
`AlarmManager` exact-alarm scheduling on task creation, gated on `canScheduleExactAlarms()` with a Settings deep-link when denied. `ReminderReceiver` → notification. `BootCompletedReceiver` re-arming all pending alarms from Room after restart — write an instrumented/Robolectric test that simulates boot and asserts alarms are re-scheduled, since this is the piece nobody can verify just by eyeballing the UI. *Done when:* a scheduled reminder fires after killing the app process, and after a simulated reboot.

**Week 4 — Agent integration**
`AgentClient` calling the Claude API with the forced `create_task` tool. Free-text screen → agent → schema validation → `AddTask`. Fallback to manual form on parse failure, timeout, or no network (check connectivity before the call, not just catch the exception after). Run a deliberately wide set of phrasings ("next Tuesday afternoon," "every other Monday," "tomorrow evening," ambiguous ones like "soon") and use what breaks to tighten the prompt and the schema. *Done when:* a representative phrasing set has a documented success rate and every failure path lands in the manual form, not a crash or a silent no-op.

**Week 5 — Polish + tests**
Compose UI tests for add/complete/reminder-fires flows. Edge cases: past due dates, ambiguous recurrence, empty input, extremely long titles. Empty/loading/error states. Dark mode + dynamic color (Material You). *Done when:* the full test suite (unit + Robolectric + Compose UI) is green in CI and every screen has a defined empty/loading/error state, not just the happy path.

**Week 6 — Ship it properly**
README with architecture diagram, the AlarmManager-vs-WorkManager rationale, the tool-schema design decision, and a demo GIF/video (add task by text → see it scheduled → notification fires, including one clip showing it survive a reboot). Tag `v1.0.0`, publish, pin on profile.

---

## 6. Best practices to hold the line on

**Never trust the LLM output blindly.** Every field from the `create_task` tool call gets validated before it touches Room: `due_at` must parse as a valid ISO-8601 datetime and not be absurdly far in the past/future, `recurrence` and `priority` must be one of the enum values, `title` must be non-empty and length-bounded. Treat validation failure as a normal, expected code path with a test for it, not an edge case.

**Offline-first is a boundary, not a slogan.** The only network call in the entire app is the agent parse at task-creation time. Check that before writing any screen: if a feature needs network to *view* or *edit* an existing task, that's a bug, not a design choice.

**Exact alarms are a scarce, user-granted resource.** Check `canScheduleExactAlarms()` before scheduling, handle the case where the user revokes it later (listen for the permission-changed broadcast where applicable), and never assume the manifest permission alone is sufficient — Android 14+ denies it by default even when declared.

**Don't block the main thread — ever, including "small" work.** Room calls, AlarmManager scheduling, and the Claude API call all go through coroutines dispatched off `Main`. This is table stakes but is exactly the kind of thing a lead-level reviewer greps for.

**Test the domain layer without Android.** If a `domain` use case needs `Context` or any `android.*` import to unit test, that's a sign the abstraction leaked — push the platform dependency behind the `repository` interface instead.

**Secrets never ship unprotected.** API key from `local.properties` → `BuildConfig` → never logged, never committed. Document the backend-proxy alternative in the README as the production-correct approach, even though this project doesn't build one.

**Commit hygiene.** Conventional commits (`feat:`, `fix:`, `test:`, `chore:`), one logical change per commit, CI green before merging to `main`.

---

## 7. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Exact-alarm permission denied or revoked mid-use | Graceful degradation to an inexact `WorkManager`-scheduled notification, with a visible in-app banner explaining reduced precision, rather than a silently-missed reminder. |
| LLM misparses relative dates ("next Tuesday" across a DST boundary, "in two weeks") | Always pass current date/time *and* timezone in the system prompt; log parse failures locally (never remotely, to avoid shipping user task text off-device) during Week 4 testing to build the phrasing test set. |
Highest-SDK targeting (37) surfaces new runtime behavior changes before the ecosystem (some libraries, Play policies) has fully caught up | Read the Android 17 behavior-change docs before Week 1 coding starts; keep an eye on whether AndroidX library majors have caught up to compileSdk 37 when pinning versions, and be ready to hold at compileSdk 36 for a specific dependency if one hasn't shipped support yet. |
| Scope creep into v2 features before v1 is solid | The Week 5 "done when" criteria is the gate — v2 work doesn't start until unit/UI test suite is green and every screen has defined empty/error states. |

---

## 8. Appendix — where things live

- Original product plan: `local-task-agent-plan.md`
- This roadmap: `ROADMAP.md`
- Claude Code project instructions: `CLAUDE.md`

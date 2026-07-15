# Tomo AI — Learning Resources

Curated resources for every technology named in `ROADMAP.md`, organized so you can work through them roughly in the order the Week 1–6 plan needs them. One resource is worth calling out before the rest: **[Now in Android](https://github.com/android/nowinandroid)** is Google's own reference app, and it uses almost this exact stack — Compose, Hilt, Room, Coroutines/Flow, Clean Architecture. Skimming its source alongside these docs will do more for you than any single tutorial; treat it as the answer key.

Last updated: 2026-07-15.

---

## 1. Foundations — Kotlin & Clean Architecture

Read these first; everything else assumes them.

- **Kotlin coroutines & Flow guide** — [kotlinlang.org/docs/coroutines-guide.html](https://kotlinlang.org/docs/coroutines-guide.html). Focus on `suspend` functions, structured concurrency, and `Flow` basics — Room, WorkManager, and your own use cases all expose Flow.
- **Guide to app architecture** — [developer.android.com/topic/architecture](https://developer.android.com/topic/architecture). Google's own Clean-Architecture-flavored guidance (UI / domain / data layers) — this is the exact shape `ROADMAP.md` §4 is built on. Read the [domain layer](https://developer.android.com/topic/architecture/domain-layer) and [UI layer](https://developer.android.com/topic/architecture/ui-layer) pages specifically.
- **Now in Android** — [github.com/android/nowinandroid](https://github.com/android/nowinandroid). Reference implementation of the above, fully modularized. Look at `core/data`, `core/domain`, and one `feature/` module to see the pattern applied end to end.

---

## 2. UI — Jetpack Compose, Material 3, Navigation

Needed starting Week 1.

- **Jetpack Compose for Android Developers** — [developer.android.com/courses/jetpack-compose/course](https://developer.android.com/courses/jetpack-compose/course). Google's official course; covers composables, state, layouts, Material Design, side effects, and testing in sequence.
- **Android Basics with Compose** — [developer.android.com/courses/android-basics-compose/course](https://developer.android.com/courses/android-basics-compose/course). Slower-paced alternative if you want more repetition before moving on.
- **Compose Navigation** — [developer.android.com/develop/ui/compose/navigation](https://developer.android.com/develop/ui/compose/navigation). You'll need this for the task-list ↔ add-task ↔ edit-task flow.
- **Material 3 for Compose** — [m3.material.io](https://m3.material.io) and [developer.android.com/develop/ui/compose/designsystems/material3](https://developer.android.com/develop/ui/compose/designsystems/material3). Skim for dynamic color / dark theme, needed in Week 5.

---

## 3. Dependency injection — Hilt

Needed starting Week 1.

- **Hilt official docs** — [developer.android.com/training/dependency-injection/hilt-android](https://developer.android.com/training/dependency-injection/hilt-android). Start here; it's short.
- **Using Hilt in your Android app (codelab)** — [developer.android.com/codelabs/android-hilt](https://developer.android.com/codelabs/android-hilt). Hands-on, builds the mental model of modules/components/scopes faster than reading alone.

---

## 4. Local data — Room, Coroutines/Flow, serialization, date/time

Needed starting Week 1–2.

- **Room official docs** — [developer.android.com/training/data-storage/room](https://developer.android.com/training/data-storage/room). Cover entities, DAOs, and exposing `Flow<List<T>>` from queries — that's the pattern your task list screen will consume directly.
- **Room with a View / Room codelab** — [developer.android.com/codelabs/android-room-with-a-view-kotlin](https://developer.android.com/codelabs/android-room-with-a-view-kotlin). Practical, short.
- **kotlinx.serialization** — [github.com/Kotlin/kotlinx.serialization](https://github.com/Kotlin/kotlinx.serialization). You'll use this both for the `create_task` tool-call payload and any local JSON needs.
- **kotlinx-datetime** — [github.com/Kotlin/kotlinx-datetime](https://github.com/Kotlin/kotlinx-datetime). Read the README's "Overview of classes" section; that's most of what you'll touch.

---

## 5. Reminders — AlarmManager, WorkManager, boot survival

This is the Week 3 milestone and the highest-signal piece of the whole project — worth reading slowly.

- **Schedule alarms** — [developer.android.com/develop/background-work/services/alarms](https://developer.android.com/develop/background-work/services/alarms). Official guide covering `setExactAndAllowWhileIdle`, `canScheduleExactAlarms()`, and when to prefer an inexact alarm.
- **Exact alarm permission changes (Android 14+)** — [developer.android.com/about/versions/14/changes/schedule-exact-alarms](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms). Read this before writing any scheduling code — it's the permission-denied-by-default behavior `ROADMAP.md` flags as a risk.
- **WorkManager overview** — [developer.android.com/develop/background-work/background-tasks/persistent](https://developer.android.com/develop/background-work/background-tasks/persistent). For the reboot-rescheduling batch job.
- **Broadcast receivers / BOOT_COMPLETED** — [developer.android.com/develop/background-work/background-tasks/broadcasts](https://developer.android.com/develop/background-work/background-tasks/broadcasts). Most to-do-app tutorials skip this; there aren't many good walkthroughs, so expect to lean on the reference docs plus experimentation more than a polished tutorial here.

---

## 6. Recurrence — RRULE / lib-recur

Needed for anything beyond `daily/weekly/monthly` recurrence.

- **RFC 5545 (iCalendar), section 3.3.10** — [datatracker.ietf.org/doc/html/rfc5545#section-3.3.10](https://datatracker.ietf.org/doc/html/rfc5545#section-3.3.10). The actual RRULE spec — dense, but you don't need to read it cover to cover, just this section to understand what a recurrence rule string encodes.
- **dmfs/lib-recur** — [github.com/dmfs/lib-recur](https://github.com/dmfs/lib-recur). README has usage examples; skim the open issues list too, it surfaces real edge cases (infinite rules, DST) worth knowing about upfront.

---

## 7. Networking — Retrofit, OkHttp

Needed for Week 4 (agent integration).

- **Retrofit** — [square.github.io/retrofit](https://square.github.io/retrofit). Official docs; the "Suspend" section is what you'll use with coroutines.
- **OkHttp** — [square.github.io/okhttp](https://square.github.io/okhttp). Mainly for `HttpLoggingInterceptor` — read just enough to set the debug-only `BASIC` logging level correctly.

---

## 8. LLM integration — Claude API, tool use

The core design decision of the project (Week 4). Note the docs moved: `docs.anthropic.com` now redirects to `platform.claude.com`.

- **Claude Platform docs home** — [platform.claude.com/docs/en/home](https://platform.claude.com/docs/en/home).
- **Tool use with Claude** — [platform.claude.com/docs/en/agents-and-tools/tool-use/overview](https://platform.claude.com/docs/en/agents-and-tools/tool-use/overview). This is the page that matters most — read it fully before writing `AgentClient`. Pay attention to forced tool choice (`tool_choice`) since that's what makes `create_task` non-optional in the model's response.
- **Anthropic Academy: build with Claude** — [anthropic.com/learn/build-with-claude](https://www.anthropic.com/learn/build-with-claude). Broader guide if you want more context before diving into the reference docs.

---

## 9. Testing — JUnit, Turbine, MockK, Robolectric, Compose UI tests

Needed incrementally from Week 2 onward, concentrated in Week 5.

- **Turbine** — [github.com/cashapp/turbine](https://github.com/cashapp/turbine). Small library, README is the whole manual — this is how you'll test `Flow<List<Task>>` emissions from Room.
- **MockK** — [mockk.io](https://mockk.io). Kotlin-first mocking; use for anything you need to fake (e.g. `AgentClient` in use-case tests).
- **Robolectric** — [robolectric.org](https://robolectric.org). For testing the boot-receiver / alarm-scheduling logic on the JVM without an emulator.
- **Compose testing** — [developer.android.com/develop/ui/compose/testing](https://developer.android.com/develop/ui/compose/testing). Official guide for `ComposeTestRule` and semantics-based assertions.

---

## 10. Tooling — ktlint, detekt, Timber, GitHub Actions

Wire these in during Week 1, mostly set-and-forget after.

- **ktlint** — [github.com/pinterest/ktlint](https://github.com/pinterest/ktlint). Formatting/linting; the README covers the Gradle plugin setup you'll need.
- **detekt** — [detekt.dev](https://detekt.dev). Structural/complexity linting — the "Getting Started" page covers the Gradle plugin and default rule set.
- **Timber** — [github.com/JakeWharton/timber](https://github.com/JakeWharton/timber). Tiny library, README is sufficient; note the pattern for a no-op release tree.
- **GitHub Actions for Android** — [docs.github.com/en/actions/use-cases-and-examples/building-and-testing/building-and-testing-android](https://docs.github.com/en/actions/use-cases-and-examples/building-and-testing/building-and-testing-android). Official starter workflow for Gradle-based Android CI.

---

## Suggested order

Roughly matches the milestone plan in `ROADMAP.md` §5: read §1 and §2 fully before Week 1 starts; §3 and §4 during Week 1; §5 before Week 3 (don't skip the exact-alarm permission page); §6 whenever `custom-rrule` comes up; §7 and §8 before Week 4; §9 as you go, but especially before Week 5; §10 is a one-time setup read in Week 1.

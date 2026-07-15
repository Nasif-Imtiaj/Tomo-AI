# Local-First Task Agent — Detailed Build Plan (Android/Kotlin)

**One-line pitch:** A task manager where you talk to it in plain language ("remind me to call the dentist next Tuesday afternoon, and add buying groceries for tomorrow evening") and an agent parses that into structured, scheduled tasks — stored fully offline, with reminders that fire even without network.

**Why this project:** No media dependency, so it stands on its own as a "general software engineering + agent integration" piece, separate from your video/graphics work. It's also small enough to actually finish well, which matters more than scope for a portfolio piece.

---

## 1. Feature scope (keep it tight)

**Must-have (v1):**
- Add a task via free text ("pay rent on the 1st every month", "call mom this weekend")
- Agent parses text → structured task (title, due date/time, recurrence, priority, category)
- Task list UI (today / upcoming / overdue / done), grouped and sortable
- Local notifications at the scheduled time, reliable even after app kill/reboot
- Full offline operation — no task ever depends on network to exist or fire
- Edit/delete/complete tasks manually (agent shouldn't be the only way in)

**Nice-to-have (v2, only after v1 is solid):**
- Natural language queries ("what do I have this week?", "show overdue tasks")
- Recurring task intelligence (agent infers "every Monday" from "every week on Monday")
- Voice input (on-device speech-to-text)
- Widget for home screen

Resist scope creep — a finished, polished v1 beats an ambitious half-finished v2.

---

## 2. Architecture

**Pattern:** Clean Architecture, 3 layers — `data`, `domain`, `presentation`. This is worth doing properly here since it's a portfolio piece meant to show engineering judgment, not just working code.

```
presentation/  (Compose UI, ViewModels, UI state)
domain/        (Task model, use cases: AddTask, CompleteTask, ScheduleReminder, ParseTaskFromText)
data/          (Room DB, DAO, Repository impl, AgentClient for LLM calls, AlarmManager/WorkManager scheduling)
```

**Key technical pieces:**

| Concern | Tool |
|---|---|
| UI | Jetpack Compose + Material 3 |
| DI | Hilt |
| Local DB | Room |
| Async | Kotlin Coroutines + Flow |
| Reminders that survive reboot | `AlarmManager` (exact alarms) + a `BOOT_COMPLETED` receiver to reschedule, or `WorkManager` for less time-critical ones — use AlarmManager for exact-time reminders since WorkManager doesn't guarantee exact timing |
| NL parsing | LLM call (Claude/OpenAI) with a strict tool schema — see below |
| Testing | JUnit + Turbine (Flow testing) + Compose UI tests |

**Agent tool schema (the core design decision):**
Don't let the LLM freeform-generate a task object — give it a strict function to call, so output is always valid:

```json
{
  "name": "create_task",
  "parameters": {
    "title": "string",
    "due_at": "ISO-8601 datetime, resolved from relative language using the current date you're given",
    "recurrence": "none | daily | weekly | monthly | custom-rrule",
    "priority": "low | medium | high",
    "category": "string, inferred (e.g. health, work, personal)"
  }
}
```
Always pass the current date/time in the system prompt so "next Tuesday" resolves correctly. Validate the returned JSON against the schema before writing to Room — never trust the LLM output blindly, this is a place where a lead-level reviewer will specifically check your error handling.

**Offline-first principle:** the agent call (LLM) is the *only* thing that needs network — and only at task-creation time. Once a task is parsed and saved, everything else (viewing, editing, notifications) works with zero network. If the LLM call fails or there's no connection, fall back to a manual entry form rather than blocking the user.

---

## 3. Milestone plan (~5–6 weeks at a steady pace)

**Week 1 — Foundation**
- Repo setup, GitHub Actions CI (ktlint + unit tests on push)
- Clean Architecture skeleton, Hilt wired up
- Room schema: `Task` entity (id, title, dueAt, recurrence, priority, category, isDone, createdAt)
- Basic Compose list screen reading from Room (seed with fake data first)

**Week 2 — Manual CRUD working end-to-end**
- Add/edit/delete task via a manual form (no AI yet) — this validates your whole data layer before you add LLM complexity on top
- Today/Upcoming/Overdue/Done grouping and sorting
- Unit tests on the domain use cases

**Week 3 — Reliable local reminders**
- AlarmManager exact-alarm scheduling on task creation
- BroadcastReceiver to show the notification
- BOOT_COMPLETED receiver to reschedule all pending alarms after device restart (this is the part most tutorials skip — doing it right is a genuine signal of experience)
- Handle Android 12+ exact alarm permission properly

**Week 4 — Agent integration**
- Build the `AgentClient` (calls Claude/OpenAI API with the tool schema above)
- Free-text input screen → agent → validated Task → save
- Fallback to manual form on parse failure or no network
- Test with a wide range of phrasing to see where parsing breaks, tighten the prompt/schema

**Week 5 — Polish + tests**
- Compose UI tests for core flows (add task, complete task, reminder fires)
- Edge cases: past dates, ambiguous recurrence, empty input
- Empty states, loading states, error states in the UI
- Dark mode / dynamic color (Material You) — small effort, looks intentional

**Week 6 — Ship it properly**
- README: architecture diagram, why AlarmManager over WorkManager for this use case, the tool-schema design decision, demo GIF
- Record a short demo (add task by voice/text → see it scheduled → notification fires)
- Publish, pin on profile

---

## 4. What to highlight in the README (this is what gets read)

1. **The reboot-survival reminder logic** — most portfolio to-do apps don't handle this; it's a concrete "I thought about production reliability" signal.
2. **The strict tool-schema + validation approach** to LLM output — shows you don't just prompt-and-pray.
3. **Offline-first boundary** — explicitly state what needs network (only task creation via the agent) and what doesn't (everything else).

---

## 5. Stretch ideas once v1 ships

- Swap AlarmManager scheduling logic to also support snooze/reschedule from the notification itself
- Add a natural-language query mode ("what's overdue?") using the same agent pattern, read-only this time
- Home screen widget (Glance API) showing today's tasks — good if you want one more Compose-adjacent skill on display

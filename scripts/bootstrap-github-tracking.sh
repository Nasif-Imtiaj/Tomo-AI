#!/usr/bin/env bash
# Bootstrap GitHub Issues + Milestones for Tomo AI, seeded from ROADMAP.md.
#
# Run this ON YOUR OWN MACHINE (not in a sandbox) — it needs full internet
# access to api.github.com, which the Cowork sandbox's proxy blocks.
#
# Prereqs:
#   1. GitHub CLI installed:  brew install gh
#   2. Authenticated:         gh auth login
#      (needs the "repo" scope, which the default login flow grants)
#
# Usage:
#   chmod +x scripts/bootstrap-github-tracking.sh
#   ./scripts/bootstrap-github-tracking.sh
#
# Safe to re-run: milestone/label creation is idempotent (ignores "already
# exists" errors); issue creation is NOT deduplicated, so only re-run the
# whole script once, or comment out sections you've already applied.

set -euo pipefail

REPO="Nasif-Imtiaj/Tomo-AI"

if ! command -v gh &> /dev/null; then
  echo "GitHub CLI (gh) not found. Install it first: brew install gh"
  exit 1
fi

if ! gh auth status &> /dev/null; then
  echo "Not logged in. Run: gh auth login"
  exit 1
fi

echo "== Creating labels =="
for wk in week-1 week-2 week-3 week-4 week-5 week-6; do
  gh label create "$wk" --repo "$REPO" --color "5319E7" --description "Roadmap $wk" 2>/dev/null || true
done
gh label create "setup"    --repo "$REPO" --color "0E8A16" --description "Project/tooling setup" 2>/dev/null || true
gh label create "test"     --repo "$REPO" --color "FBCA04" --description "Testing" 2>/dev/null || true
gh label create "polish"   --repo "$REPO" --color "C5DEF5" --description "UX polish / edge cases" 2>/dev/null || true

echo "== Creating milestones =="

create_milestone() {
  local title="$1" desc="$2"
  gh api "repos/$REPO/milestones" -f title="$title" -f description="$desc" -f state="open" &> /dev/null || \
    echo "  (milestone '$title' likely already exists, skipping)"
}

create_milestone "Week 1 — Foundation" "Done when: CI is green on a clean clone, and the list screen renders seeded tasks. See ROADMAP.md §5."
create_milestone "Week 2 — Manual CRUD" "Done when: full add/edit/complete/delete works correctly sorted, with no LLM code written yet. See ROADMAP.md §5."
create_milestone "Week 3 — Reliable local reminders" "Done when: a scheduled reminder fires after killing the app process, and after a simulated reboot. See ROADMAP.md §5."
create_milestone "Week 4 — Agent integration" "Done when: a representative phrasing set has a documented success rate and every failure path lands in the manual form. See ROADMAP.md §5."
create_milestone "Week 5 — Polish + tests" "Done when: full test suite is green in CI and every screen has a defined empty/loading/error state. See ROADMAP.md §5."
create_milestone "Week 6 — Ship it properly" "Done when: README, demo, and v1.0.0 tag are published. See ROADMAP.md §5."

echo "== Creating issues =="

create_issue() {
  local title="$1" body="$2" milestone="$3" label="$4"
  gh issue create --repo "$REPO" --title "$title" --body "$body" --milestone "$milestone" --label "$label"
}

# Week 1
create_issue "Bump compileSdk/targetSdk to 37" "Per the SDK decision in ROADMAP.md — Android 17, highest available SDK." "Week 1 — Foundation" "week-1,setup"
create_issue "Wire up Compose Compiler plugin + BOM" "Add the Compose Compiler Gradle plugin and Compose BOM (2026.06.00 or newer compatible with compileSdk 37)." "Week 1 — Foundation" "week-1,setup"
create_issue "Wire up Hilt + KSP, add @HiltAndroidApp Application class" "Hilt 2.59+ (AGP 9 compatible), via KSP not kapt." "Week 1 — Foundation" "week-1,setup"
create_issue "Wire up Room + KSP, stub Task entity and AppDatabase" "Task entity: id, title, dueAt, recurrence, priority, category, isDone, createdAt." "Week 1 — Foundation" "week-1,setup"
create_issue "Enable core library desugaring for java.time" "Needed since minSdk stays 24 and java.time requires desugaring below API 26." "Week 1 — Foundation" "week-1,setup"
create_issue "Wire ktlint + detekt + GitHub Actions CI" "CI must run ktlint, detekt, and testDebugUnitTest on every push." "Week 1 — Foundation" "week-1,setup"
create_issue "Set up Clean Architecture package skeleton" "presentation/ domain/ data/ di/ packages per ROADMAP.md §4, even before real content exists." "Week 1 — Foundation" "week-1,setup"
create_issue "Compose list screen reading seeded fake data from Room" "First real UI screen — proves Room -> Flow -> Compose wiring end to end." "Week 1 — Foundation" "week-1"

# Week 2
create_issue "AddTask use case + manual entry form" "Manual entry is the primary fallback path and must exist before any agent code." "Week 2 — Manual CRUD" "week-2"
create_issue "EditTask, DeleteTask, CompleteTask use cases" "Round out manual CRUD." "Week 2 — Manual CRUD" "week-2"
create_issue "Today/Upcoming/Overdue/Done grouping and sorting" "Core list screen logic." "Week 2 — Manual CRUD" "week-2"
create_issue "Unit tests for every domain use case" "Every use case in domain/usecase/ needs a test before Week 2 is done, per CLAUDE.md." "Week 2 — Manual CRUD" "week-2,test"

# Week 3
create_issue "AlarmManager exact-alarm scheduling on task creation" "Gate on canScheduleExactAlarms(), deep-link to Settings when denied." "Week 3 — Reliable local reminders" "week-3"
create_issue "ReminderReceiver -> notification" "Fires the actual local notification when an alarm goes off." "Week 3 — Reliable local reminders" "week-3"
create_issue "BootCompletedReceiver re-arms all pending alarms" "The highest-signal piece of the whole project — re-reads Room and re-arms AlarmManager after reboot." "Week 3 — Reliable local reminders" "week-3"
create_issue "Test: reminder fires after app process is killed" "" "Week 3 — Reliable local reminders" "week-3,test"
create_issue "Test: simulated reboot re-arms alarms (Robolectric)" "" "Week 3 — Reliable local reminders" "week-3,test"

# Week 4
create_issue "AgentClient calling Claude API with forced create_task tool" "Messages API, tool_choice forced, per ROADMAP.md §2." "Week 4 — Agent integration" "week-4"
create_issue "Free-text screen -> agent -> schema validation -> AddTask" "Wire the full happy path." "Week 4 — Agent integration" "week-4"
create_issue "Fallback to manual form on parse failure/timeout/no network" "Never a silent failure or crash, per CLAUDE.md non-negotiable #6." "Week 4 — Agent integration" "week-4"
create_issue "Build phrasing test set, tighten prompt/schema" "Wide range of phrasings, document success rate." "Week 4 — Agent integration" "week-4,test"

# Week 5
create_issue "Compose UI tests: add/complete/reminder-fires flows" "" "Week 5 — Polish + tests" "week-5,test"
create_issue "Edge cases: past dates, ambiguous recurrence, empty/long input" "" "Week 5 — Polish + tests" "week-5,polish"
create_issue "Empty/loading/error states for every screen" "No bare happy-path-only composables, per CLAUDE.md." "Week 5 — Polish + tests" "week-5,polish"
create_issue "Dark mode + dynamic color (Material You)" "" "Week 5 — Polish + tests" "week-5,polish"

# Week 6
create_issue "Write README: architecture, design decisions, demo" "AlarmManager-vs-WorkManager rationale, tool-schema decision, architecture diagram." "Week 6 — Ship it properly" "week-6"
create_issue "Record demo GIF/video" "Add task by text -> scheduled -> notification fires -> survives reboot." "Week 6 — Ship it properly" "week-6"
create_issue "Tag v1.0.0 and publish" "" "Week 6 — Ship it properly" "week-6"

echo "== Done =="
echo "Next: open https://github.com/$REPO and create a Project (Projects tab -> New project -> Board template)."
echo "Then in the project's ... menu -> Workflows, turn on 'Item added to project' / 'Auto-add to project' for this repo so every issue above shows up on the board automatically."

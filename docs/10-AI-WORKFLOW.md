# AI Workflow — NOCTURNE

> Workflow update, 2026-09-11: take current work from [Re-innovation milestones](19-REINNOVATION-ROADMAP.md), not the historical milestone queue. Use the original-request mapping, render and inspect the affected section, and distinguish implementation from visual acceptance. Keep the session worklog current; do not backfill invented history.

How to run this project with coding agents. Written for someone who has not set up an agent workflow before.

---

## 1. Why the documents exist

An agent starts every session knowing nothing about your project. Left unconstrained it invents: a colour, a folder structure, a state pattern. Next session it invents different ones. Three sessions in, the codebase contains three architectures.

This is the normal failure mode for AI-built projects and it is why most of them look like demos. The code runs. It just isn't a coherent thing.

The fix is that the specification lives in the repository and the agent reads it before touching anything. `AGENTS.md` is a filename convention that Codex, Antigravity and Claude Code all look for automatically. It points at everything else.

The worklog is the other half. Every session, the agent writes down what it did and decided. Next session — possibly a different tool — reads the last three entries before starting. That is how one agent picks up where another stopped.

Without this you get an expensive mess. With it you get a codebase that looks like one person built it carefully.

---

## 2. Setup, once

```bash
fvm install 3.47.2
fvm spawn 3.47.2 create --org com.ahmedelsherbini --platforms web nocturne
cd nocturne
fvm use 3.47.2
git init
```

Full setup, including the VS Code settings that point the analyzer at the pinned SDK, is in `START-HERE.md`.

Copy the documents in:

```
nocturne/
  AGENTS.md
  README.md
  CHANGELOG.md
  docs/
    00-PROJECT-BRIEF.md
    01-DESIGN-SYSTEM.md
    02-SCREEN-SPECS.md
    03-ARCHITECTURE.md
    04-FLUTTER-STANDARDS.md
    05-TESTING.md
    06-ANALYTICS-AND-PRIVACY.md
    07-CONTENT-SCHEMA.md
    08-GIT-AND-CI.md
    09-ROADMAP.md
    10-AI-WORKFLOW.md
    worklog/
  .fvmrc
  .vscode/settings.json
```

Commit before any code:

```bash
git add . && git commit -m "docs: project specification and agent operating rules"
```

Specification before implementation. Every agent then starts from an unambiguous state, and the history reads well to anyone who looks.

**Tool-specific:** if your tool wants a different filename (`CLAUDE.md`, `GEMINI.md`, `.cursorrules`), create it as a one-line file pointing at `AGENTS.md` rather than duplicating content. Two copies of the rules will drift and you will not notice which one the agent read.

---

## 3. The session loop

**One task per session.** Tasks come from `09-ROADMAP.md` in order, committed onto the current phase branch. Nothing goes to `main` until the whole milestone is done — merging to `main` publishes the site.

### Start

Paste the task's prompt from the roadmap. Every prompt should begin by telling the agent to read `AGENTS.md` and the relevant docs.

`AGENTS.md` §2 requires it to propose a plan and wait for your approval before writing anything. Hold it to that. If it starts editing files without a plan, stop it and point at §2 — an agent that skips the confirmation step on a small task will skip it on a large one.

When the plan arrives, check three things: does it match the task, does it touch only files the task needs, and does it flag anything it is unsure about? A plan with no uncertainties on a non-trivial task usually means the agent has quietly assumed something.

Correcting an agent's understanding costs one message. Correcting its output costs a session.

### During

Watch for four failure signs:

| Sign | What it means | Do |
|---|---|---|
| Raw hex, pixel values, or `Duration(milliseconds:)` in feature code | Ignoring the token system | Stop. Point at `04-FLUTTER-STANDARDS.md` §10. |
| `Widget _buildSomething(...)` | Ignoring the widget rule | Stop. Point at §2. Explain the repaint cost. |
| `import 'package:flutter/material.dart'` | Training-data habit, pre-3.47 | Stop. Run `fvm dart fix --apply --code=migrate_design_widgets`. |
| Bare `flutter test` or `dart run`, no `fvm` prefix | Ignoring the SDK pin | Stop. It may have run against a different Flutter entirely, so the result means nothing. Re-run with `fvm`. |
| Editing files outside the task | Scope drift | Stop. Revert. Re-scope. |
| Acting before you approved a plan | Ignoring `AGENTS.md` §2 | Stop. Revert anything written. Restate the rule. |
| A specific metric, date or claim you never supplied | Invention | Stop. Check `assets/content/`. If it isn't there, the agent made it up — and it will do it again unless corrected explicitly. |
| Committing to `main` | Ignoring the phase-branch rule | Stop. `main` is the published site. |

Stopping early is much cheaper than reviewing a large wrong diff. Agents are confident when wrong, and a plausible 600-line diff takes longer to audit than to redo.

### End

The agent runs all four verification commands and writes the worklog. **Do not accept a session without a worklog entry.** It is the only thing that makes the next session possible.

Read the "Known issues" section specifically. That is where an honest agent tells you what it stubbed. If it is always empty, the agent is not being honest with you — something is always left open.

---

## 4. Reviewing output

You cannot read every line, and you do not need to. Check these six:

1. **Does it run?** Not "does it compile."
2. **Does it look like the spec?** Open `02-SCREEN-SPECS.md` next to the screen.
3. **Any raw values?** `grep -rn "0xFF" lib/` should return nothing outside `tokens.dart`.
4. **Any widget functions?** `grep -rn "Widget _build" lib/` should return nothing.
5. **Legacy imports?** `grep -rn "package:flutter/material.dart" lib/` should return nothing.
6. **Do tests actually test something?** A test that asserts a widget exists is not a test.

```bash
grep -rn "0xFF" lib/ --include=*.dart | grep -v tokens.dart
grep -rn "Widget _build" lib/
grep -rn "package:flutter/material.dart\|package:flutter/cupertino.dart" lib/
fvm flutter --version | head -1        # confirm 3.47.2
```

Four commands, ten seconds, catches most drift.

---

## 5. Rejecting work

Be specific and cite the document. Vague correction produces vague fixes.

Weak: *"this doesn't look right, make it better"*

Strong: *"The hero is centred. `02-SCREEN-SPECS.md` specifies left-aligned to the rail, and the amber rule is 120px not full-width. Also `station_header.dart` has `Color(0xFF05070A)` inline — that must come from tokens per `04-FLUTTER-STANDARDS.md` §10. Fix both, re-run verification, update the worklog."*

If an agent produces the same violation three times, the document is unclear rather than the agent being careless. Fix the document. That is the durable repair.

---

## 6. Switching tools

Fine, and expected. The handoff:

1. Finish the current task and its worklog before switching.
2. Commit.
3. New tool's first prompt: *"Read `AGENTS.md`, then the three most recent files in `docs/worklog/`. Tell me the current state and what you think comes next before doing anything."*
4. If its summary matches reality, continue. If not, the worklogs are too thin — say so and tighten the template.

Agents differ in strengths. Longer reasoning suits the trace and the map projection; faster iteration suits the ledger and content layer. Use whichever, but never mid-task.

---

## 7. Context

Long sessions degrade. The agent forgets earlier decisions and starts contradicting itself. Symptoms: re-explaining things it already knows, reintroducing patterns it removed, forgetting a constraint from an hour ago.

When that starts, end the session. Have it write the worklog and start fresh. The worklog is what makes a fresh start cheap.

This is why tasks are scoped small. A task that fits one clean session produces better code than one spanning three degrading ones.

---

## 8. What to do yourself

Agents should not write:

- **Content.** Your career, your case studies, your Arabic copy. An agent asked for missing content will invent it — plausible, specific, and false. On a portfolio a fabricated metric is the fastest way to fail an interview that probes it.
- **Anything about you.** Marks, dates, employment history, the City Loom status line.
- **The privacy notice.** You are the data controller. It has to be true.

Everything else is fair game.

---

## 9. Cost

Roughly, by expense:

1. The telemetry trace — iterative, visual, hard to specify completely
2. The map — projection maths plus interaction
3. Case study scrubbing
4. Everything else

Foundation tasks (1.1–1.4) are cheap and high-leverage — they are almost pure specification transcription. Do them properly. Every shortcut there gets paid for repeatedly later.

If budget gets tight, cut Milestone 3 entirely and trim Milestone 2 to case studies and the console. Milestone 1 alone is a live, indexable, well-built portfolio with real analytics. That is already ahead of nearly every portfolio a recruiter sees.

# AGENTS.md

Operating rules for any AI agent working in this repository. Read this file and `docs/00-PROJECT-BRIEF.md` before your first change in a session.

Multiple different agents work on this project. The worklog is how you find out what happened before you and how the next one finds out what you did. It is not optional.

---

## 1. Before you start

1. Read `docs/00-PROJECT-BRIEF.md`, `docs/01-DESIGN-SYSTEM.md`, `docs/03-ARCHITECTURE.md` and `docs/04-FLUTTER-STANDARDS.md`.
2. Read the **three most recent** files in `docs/worklog/`.
3. Read `CHANGELOG.md`.
4. State in your first message: what you understood the current state to be, and what you intend to change.

If the three most recent worklogs contradict each other, stop and say so rather than guessing.

---

## 2. Confirm before you act

**Propose first. Wait for approval. Then write code.**

Before creating, modifying or deleting anything, state:

1. What you are about to do, specifically — which files, which approach.
2. Anything the task did not specify that you would otherwise decide yourself.
3. Anything you are unsure about.

Then stop and wait. Do not begin because the plan seems obviously right. An unwanted change is more expensive to find and unpick than a message asking first, and by the time it is spotted it may be three commits down.

This applies to every session, including small ones.

## 3. Never invent

If information is missing, **stop and ask.** Do not fill the gap with something plausible.

You must never fabricate:

- **Content.** Career details, dates, employers, metrics, case study text, Arabic translations. If `assets/content/` lacks something, say so and stop. This site makes claims about a real person to real employers, and a plausible invented metric is one interview question away from being exposed.
- **Numbers.** Download counts, percentage improvements, performance figures, team sizes. Every number on this site must be traceable to something the owner supplied.
- **Package versions or APIs.** If you are unsure whether a method exists in this version, check. A confidently wrong API call wastes a whole session.
- **Test results.** Never report a command as passing without running it. Never describe work as done when it is partial.
- **Prior context.** If the worklogs do not say why something was done a certain way, say the worklogs do not say. Do not reconstruct a plausible reason.

"I don't know" and "this isn't specified — how do you want it?" are correct, useful answers. A confident guess is worse than a question, because a question costs one message and a wrong guess costs a session plus whatever it silently broke downstream.

Where you must make an assumption to continue, mark it clearly as an assumption in your response and in the worklog. Do not bury it.

---

## 4. Before you report finished

Run all four, through `fvm`. All four must pass. Do not report completion on a partial run — and a run without the `fvm` prefix does not count, because it may have used a different SDK.

```bash
fvm dart format --set-exit-if-changed .
fvm flutter analyze
fvm flutter test
fvm flutter build web --wasm
```

If a test fails, fix it or explain precisely why it cannot be fixed. Never delete or skip a failing test to get a green run. Never mark a test `skip:` without recording why in the worklog.

---

## 5. Worklog — required after every session

Write `docs/worklog/YYYY-MM-DD-NN-short-slug.md`, where `NN` increments within the day (`01`, `02`, …).

Use this template exactly:

```markdown
# YYYY-MM-DD-NN — <short title>

**Agent:** <model / tool name>
**Milestone:** <1 | 2 | 3>
**Started from:** <commit sha or previous worklog filename>

## Goal
What this session set out to do, in one or two sentences.

## What changed
- Concrete, specific changes. Not "improved the map" — say what.

## Files touched
- `path/to/file.dart` — created | modified | deleted — one-line reason

## Decisions made
Any choice a future agent could reasonably have made differently, and why this one was taken. If a package, pattern or token was added or substituted, it goes here with its justification.

## Tests
- Added: <names>
- Modified: <names>
- Full suite: <pass/fail>, <N> passing, <N> failing
- Coverage delta: <if measured>

## Verification run
```
fvm dart format --set-exit-if-changed .   <result>
fvm flutter analyze                        <result>
fvm flutter test                           <result>
fvm flutter build web --wasm               <result>
```

## Known issues left open
Anything broken, stubbed, hard-coded, or deferred. Be honest — an undisclosed stub costs the next agent more time than it saved you.

## Next
The single most useful thing to do next, and why.
```

**An empty or vague worklog is worse than none.** "Made various improvements" tells the next agent nothing and they will re-read the whole diff.

---

## 6. Hard rules

**Design tokens.** Never write a raw hex value, spacing number, duration or radius in feature code. Everything comes from `app/theme/tokens.dart`. If a value you need does not exist, add it to tokens with a name, and say so in the worklog.

**Content.** Never edit files under `assets/content/` unless the task explicitly says to. That is the owner's data, not implementation detail. If content is missing for a feature you are building, add a clearly-marked placeholder in code and flag it under Known issues.

**Secrets.** No API keys, tokens, credentials or personal data in source, in tests, or in worklogs. Config comes from `--dart-define` or CI secrets. If you find a committed secret, stop and report it.

**Privacy.** No analytics call, no network request carrying viewer information, and no storage write may occur before consent is granted. See `docs/06-ANALYTICS-AND-PRIVACY.md`. This constraint outranks any feature request. If a task appears to require breaking it, refuse and explain.

**Scope.** Do what was asked. Do not refactor adjacent code, rename things, upgrade packages, or "clean up" files outside the task. If you see something that needs doing, record it under Known issues.

**Platform.** This is a **web-only** project — no iOS, Android or desktop build, no `dart:io`, no `cupertino_ui`. Phone browsers are a primary target, but that is responsive design and input-type handling, not a native concern. Never branch on viewport width or user agent in feature code; ask `core/platform/platform_service.dart`.

**FVM.** The SDK is pinned by `.fvmrc`. **Every Flutter and Dart command runs through `fvm`** — `fvm flutter test`, `fvm dart format`, `fvm dart run build_runner`. A bare `flutter` command invokes whatever version is on the machine's PATH, so its result tells you nothing about whether the code works on the pinned version. Never edit `.fvmrc` as a side effect of another task.

**Flutter version.** This project targets Flutter 3.47 / Dart 3.13 and uses the standalone `material_ui` and `cupertino_ui` packages. `package:flutter/material.dart` is deprecated and banned here. If you catch yourself importing it out of habit, run `fvm dart fix --apply --code=migrate_design_widgets` and note it in the worklog.

**Palette.** Amber is the only chroma in this design system. Never introduce a second hue — not for success states, not for chart series, not for categories. See `docs/01-DESIGN-SYSTEM.md` §2.

**Code standards.** `docs/04-FLUTTER-STANDARDS.md` is enforceable, not advisory. Widgets are classes, never functions. No raw values in feature code. Enums over string constants. Exhaustive switches with no `default`.

**Motion.** Every animation must handle reduced motion. A widget with an animation and no reduced-motion path is incomplete.

**Accessibility.** Every interactive element needs a semantic label and a visible focus state. This is part of "done", not a follow-up task.

---

## 7. Commits

Conventional Commits, and one branch per phase. See `docs/08-GIT-AND-CI.md`. Never commit directly to `main` — `main` is the published site.

Commit in logical units. One commit per coherent change, not one commit per session and not one per file.

---

## 8. Asking versus assuming

Section 2 means you confirm your plan before every task. Beyond that, these always require an explicit answer and must never be decided unilaterally:
- Adding a package not in `docs/03-ARCHITECTURE.md` §4
- Changing the Flutter version in `.fvmrc`
- Changing a design token value
- Changing a route path
- Anything touching consent, analytics or data collection
- Anything that changes what the site claims about the owner
- Deleting or overwriting any existing file
- Anything that would go live on `main`

These you may decide yourself once the plan is approved, recording them in the worklog:
- Widget composition and internal structure
- Test strategy for a given unit
- Private helper naming
- Painter implementation detail

---

## 9. Reporting style

State what you did and what state it is in. If something is stubbed, incomplete, or you are unsure it works, say so plainly. Do not describe partial work as finished. An accurate report of 60% done is more useful than a confident report of "done" that turns out to be 60%.

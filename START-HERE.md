# Start here

From an empty folder to a repository ready for the first agent session.

---

## 1. Create the project

```bash
# Install the pinned SDK first, so the project is scaffolded by the right version
fvm install 3.47.2

# Web only — this ships to browsers, never to an app store
fvm spawn 3.47.2 create --org com.ahmedelsherbini --platforms web nocturne
cd nocturne

fvm use 3.47.2          # writes .fvmrc and links .fvm/flutter_sdk
git init
```

Verify before going further:

```bash
fvm flutter --version   # must report 3.47.2 / Dart 3.13.2
cat .fvmrc
```

If the version is wrong, stop and fix it. Everything downstream assumes 3.47, and scaffolding on an older SDK produces a project targeting the deprecated in-framework Material libraries.

Then create `.vscode/settings.json` so the analyzer uses the same SDK as your terminal:

```json
{
  "dart.flutterSdkPath": ".fvm/flutter_sdk",
  "search.exclude": { "**/.fvm": true },
  "files.watcherExclude": { "**/.fvm": true }
}
```

Without this the editor analyses with one Flutter version while the terminal builds with another, and you get errors that vanish on the command line.

---

## 2. Drop the docs in

```
nocturne/
  AGENTS.md
  START-HERE.md
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

`docs/worklog/` must exist and be tracked, but git ignores empty directories. Create a placeholder:

```bash
mkdir -p docs/worklog
printf '# Worklog\n\nOne file per agent session. Format in AGENTS.md section 5.\n' > docs/worklog/README.md
```

---

## 3. Write `.gitignore` before the first commit

**Order matters.** Commit first and you permanently track `build/`, `.dart_tool/` and the `.fvm/` symlink. Untracking them later leaves a messy commit in a history a recruiter may read.

Create `.gitignore` at the repository root using the full contents in `docs/08-GIT-AND-CI.md`. The critical lines:

```gitignore
.fvm/
.dart_tool/
build/
*.g.dart
*.freezed.dart
web/cv/index.html
web/brief/index.html
.vscode/*
!.vscode/settings.json
ios/
android/
macos/
```

Then check what would actually be committed:

```bash
git add -A
git status --short
```

You should see docs, `web/`, `lib/`, `pubspec.yaml`, `.fvmrc`, `.vscode/settings.json`. If `build/`, `.dart_tool/` or `.fvm/` appear, the ignore file is wrong or in the wrong directory. Fix it before committing.

---

## 4. First commit

```bash
git add -A
git commit -m "docs: project specification and agent operating rules"
```

Specification before implementation. Every agent starts from an unambiguous state, and it reads well to anyone who opens the history.

---

## 5. Create the GitHub repository

**First, check the name is free.** Open `https://github.com/asherbinyy?tab=repositories` and look for an existing `asherbinyy.github.io`. Your `cityloom-prototype` repo publishes to `asherbinyy.github.io/cityloom-prototype/` — that is a *project* page and does not conflict. But if a repo named exactly `asherbinyy.github.io` already exists and serves something, decide now whether the portfolio replaces it.

Then:

1. GitHub → **New repository**
2. Name: **`asherbinyy.github.io`** — exactly this, lowercase, matching your username
3. Visibility: **Public**. Pages requires it on the free plan, and the repo is a portfolio surface in its own right
4. Do **not** initialise with a README, `.gitignore` or licence — you already have them locally, and the merge conflict is avoidable friction
5. Create

Connect and push:

```bash
git remote add origin https://github.com/asherbinyy/asherbinyy.github.io.git
git branch -M main
git push -u origin main
```

**Why this name.** A repo named anything else serves from `https://asherbinyy.github.io/<repo-name>/`, which forces `--base-href` to match, bakes the repo name into every asset path, and turns the eventual move to a custom domain into a rebuild rather than a DNS change. Named as your username, it serves from the root and `--base-href` stays `/` permanently.

---

## 6. Enable Pages

Repository → **Settings** → **Pages** → Build and deployment → Source → **GitHub Actions**.

Not "Deploy from a branch". That mode expects committed static files; the workflow builds the site and uploads it as an artifact instead.

Nothing publishes yet — there is no workflow until roadmap task 1.12. This step only tells GitHub to accept a deployment when one arrives.

---

## 7. Protect `main` (optional, recommended)

`main` is the published site. Even working alone, a guard rail stops an agent committing straight to it.

Settings → **Rules** → **Rulesets** → New branch ruleset:
- Target: `main`
- Require a pull request before merging
- Require status checks to pass — add `verify` once the workflow exists
- Leave "Do not allow bypassing" **off**, so you can override in an emergency

Skip it if the friction outweighs the benefit for you — but then read every agent diff carefully, because nothing else will stop a push to `main`.

---

## 8. Create the phase branch

All Milestone 1 work happens here. Nothing reaches `main` until the milestone is complete.

```bash
git checkout -b phase/1-ground-station
git push -u origin phase/1-ground-station
```

---

## 9. Fonts

Four families, bundled locally — no CDN, no network fetch, no layout shift.

| Family | Weights | Source |
|---|---|---|
| Space Grotesk | 500, 700 | fonts.google.com |
| IBM Plex Sans | 400, 500, 600 | github.com/IBM/plex |
| IBM Plex Sans Arabic | 400, 500, 600 | github.com/IBM/plex |
| IBM Plex Mono | 400, 500 | github.com/IBM/plex |

Download the `.ttf` files into `assets/fonts/`. **Flutter bundles TTF and OTF, not WOFF2** — do not convert.

### Subsetting

Unsubsetted IBM Plex Sans Arabic is around 400KB on its own and would consume the entire font budget in `03-ARCHITECTURE.md` section 5.

```bash
pip install fonttools brotli
```

Latin faces — Space Grotesk, Plex Sans, Plex Mono:

```bash
pyftsubset SpaceGrotesk-Bold.ttf \
  --unicodes="U+0000-00FF,U+0131,U+0152-0153,U+2000-206F,U+2074,U+20AC,U+2122,U+2212" \
  --layout-features="kern,liga,tnum,onum" \
  --output-file="SpaceGrotesk-Bold-subset.ttf"
```

Arabic — **different flags, and the difference is not cosmetic**:

```bash
pyftsubset IBMPlexSansArabic-Regular.ttf \
  --unicodes="U+0600-06FF,U+0750-077F,U+08A0-08FF,U+FB50-FDFF,U+FE70-FEFF,U+0000-00FF,U+2000-206F" \
  --layout-features="*" \
  --output-file="IBMPlexSansArabic-Regular-subset.ttf"
```

Arabic is a joining script: letters change shape by position, driven by OpenType features (`init`, `medi`, `fina`, `isol`, `rlig`, `mark`). Strip those and the text renders as disconnected, wrong-shaped letterforms — technically present, visibly broken. `--layout-features="*"` keeps them. This is the most common way bundled Arabic fails.

Verify before moving on:

```bash
ls -lh assets/fonts/*subset*      # total comfortably under 480KB
```

---

## 10. Accounts to create

Only when the relevant task arrives. None of these block task 1.1.

| Service | Needed for | When | Cost |
|---|---|---|---|
| Cloudflare | Analytics Worker + KV | Task 1.10 | Free, no card required |
| Resend | Daily digest email | Milestone 2 | Free tier |
| Porkbun | Custom domain | Whenever | ~£8/year |

Firebase is not used. Hosting is GitHub Pages; the analytics endpoint is a Cloudflare Worker.

---

## 11. What only you can write

The agent must never invent these — `AGENTS.md` section 3. Have each ready before the task that needs it.

**Before task 1.3, content layer:**
- `assets/content/` files per `07-CONTENT-SCHEMA.md`, in English
- Verify all twelve store links resolve. A dead App Store link is worse than omitting the app

**Before task 1.2, localisation:**
- Arabic copy for `profile.json` and `career.json`. Placeholders are fine to start, but it must be real Arabic before Milestone 1 merges to `main`

**Before Milestone 2:**
- The three case studies written out — Mokaf, AZ Courses, City Loom
- Screenshots from each
- Your portrait, shot brief in `01-DESIGN-SYSTEM.md` section 10

Separately: fix the CV inconsistencies already flagged.

---

## 12. Then what

- **`docs/09-ROADMAP.md`** — every task in build order, each with a definition of done and a prompt.
- **`docs/10-AI-WORKFLOW.md`** — how to run a session, spot drift, reject work, hand between tools. **Read this before your first session.**

Task order for Milestone 1: **1.1, then 1.12, then 1.2 onward.** CI moves up because a deploy pipeline that has never run is not a pipeline — better to hit the `.nojekyll` and `404.html` problems on day one than at the merge.

One task per session. The agent proposes, you approve, then it writes.

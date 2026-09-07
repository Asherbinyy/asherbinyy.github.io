# Content Schema — KEMET

> **Milestone 4 changed this schema substantially.** Every field added there is
> documented below and marked *(4)*. The largest change is that several fields
> that were plain strings became `LocalizedText`: app roles, institutions,
> awards, academic status, module names and course highlights could not hold
> Arabic at all, which is why the language toggle used to change the furniture
> and leave the content in English.

All site content lives in `assets/content/`. Editing these files and redeploying is the entire content workflow. No CMS, no database.

```
assets/content/
  profile.json      identity, positioning, contact, current status
  career.json       roles — drives the map and the trace
  apps.json         shipped applications
  studies/          one file per case study
  education.json
  writing.json      Medium fallback if RSS fails
  strings_en.json   UI copy
  strings_ar.json
```

Every file is validated on load. A malformed file falls back to `assets/content/fallback.json` rather than crashing.

---

## profile.json

```json
{
  "name": { "en": "Ahmed Elsherbini", "ar": "أحمد الشربيني" },
  "displayName": { "en": "Sherbini", "ar": "الشربيني" },
  "positioning": {
    "en": "Mobile engineer. 25+ applications shipped across six countries.",
    "ar": "..."
  },
  "location": { "en": "Manchester, United Kingdom", "ar": "..." },
  "status": {
    "en": "MSc Managing Innovation & IT, University of Salford — predicted Distinction",
    "ar": "..."
  },
  "venture": {
    "label": { "en": "Co-founder, City Loom (early stage)", "ar": "..." },
    "url": null
  },
  "contact": {
    "email": "ahmed.elsherbini.tech@gmail.com",
    "phone": "+447741204235",
    "linkedin": "https://www.linkedin.com/in/ahmedelsherbini/",
    "github": "https://github.com/Asherbinyy",
    "gitlab": "https://gitlab.com/sherbini",
    "medium": "https://sherbini.medium.com/",
    "calendly": "<calendly url>"
  },
  "cvFile": "assets/docs/ahmed-elsherbini-cv.pdf",
  "portrait": { "src": "assets/media/portrait.jpg", "isPlaceholder": false }
}
```

**On `venture`:** keep the "(early stage)" qualifier until City Loom has a live product. An unqualified co-founder claim on an unlaunched venture is the kind of thing a recruiter checks and holds against you. Qualified, it reads as initiative.

**On `status`:** the award is confirmed. It read "predicted Distinction" until the owner supplied his CV, and the hedge was removed then — see `docs/worklog/`. The rule that produced the hedge still stands for anything not yet awarded.

**On `displayName` *(4)*:** optional, and the name a reader is shown. `name` is the legal name. They are separate because they have different jobs: an ATS parser and the JSON-LD `Person` record need the name on his passport, and a visitor should meet the name he uses. `Profile.shownName` resolves the rule once — `displayName ?? name` — so no surface has to remember it, and the two places that deliberately want the legal name (`/cv`, and every `<title>`, Open Graph tag and JSON-LD record) read as decisions rather than oversights.

**On `cvFile` *(4)*:** an asset path, validated to sit under `assets/`. Its presence changes the hero's second action from "Read the CV", which opens the static HTML page, to "Download the CV". Flutter serves a declared asset under its own `assets/` prefix, so the URL is `assets/$cvFile` — built in `cv_button.dart`, not stored here, because it is a fact about the build output rather than something the owner should know when editing JSON.

**On `portrait`:** `isPlaceholder: true` renders the empty frame rather than the image. A placeholder is not the owner, so it is not shown as him.

---

## career.json

Drives both the propagation map and the telemetry trace. Order is chronological ascending.

```json
{
  "roles": [
    {
      "id": "ci-company",
      "company": "CI Company",
      "title": { "en": "Flutter Developer & Team Leader", "ar": "..." },
      "country": "EG",
      "city": "Mansoura",
      "coords": [31.0409, 31.3785],
      "start": "2021-10",
      "end": "2023-04",
      "employment": "full-time",
      "summary": { "en": "Led development of 16+ Flutter applications. Mentored a team of three.", "ar": "..." },
      "stack": ["Flutter", "Dart", "Firebase", "REST"],
      "appIds": ["az-courses", "enjoy", "snunu", "mostaqbaly"],
      "traceWeight": 0.9
    },
    {
      "id": "minextstep",
      "company": "MiNextStep",
      "country": "CA",
      "city": "Toronto",
      "coords": [43.6532, -79.3832],
      "start": "2023-05",
      "end": "2025-08",
      "employment": "full-time then part-time",
      "..." : "..."
    },
    { "id": "hwzn-tech", "country": "SA", "city": "Riyadh", "coords": [24.7136, 46.6753], "start": "2023-08", "end": "2025-08" },
    { "id": "ar-plus-plus", "country": "AM", "city": "Yerevan", "coords": [40.1792, 44.4991], "start": "2024-01", "end": "2025-04" },
    { "id": "techlabs", "country": "QA", "city": "Doha", "coords": [25.2854, 51.5310], "start": "2025-02", "end": "2025-05" },
    { "id": "university-of-salford", "kind": "study", "country": "GB", "city": "Manchester", "coords": [53.4808, -2.2426], "start": "2025-09", "end": "2026-09", "company": "University of Salford" }
  ]
}
```

`traceWeight` (0–1) sets burst amplitude. `coords` are `[lat, lon]` and feed `core/painting/projection.dart`.

**On `kind` *(4)*:** `role` (the default) or `study`. The map showed employment
only until milestone 4, so it began at a first job and said nothing about where
the person came from. Two study stops carry the journey now — Mansoura
University in 2015 and Salford in 2026 — and both were already in
`education.json`, so the map gained an origin and a present **without a single
new claim** and without needing a birth year nobody had sourced.

**On Evri:** removed on the owner's instruction, 2026-09-07. The guidance that
stood here — include a non-engineering role rather than leave a gap — is sound
and worth keeping for the next such decision, but it was his call to make.

---

## apps.json

Real, verifiable, publicly linked. This is the strongest evidence on the site and it should be impossible to miss.

```json
{
  "apps": [
    { "id": "tripster", "name": "Tripster", "platforms": ["ios"],
      "store": { "ios": "https://apps.apple.com/ru/app/id1479200934" },
      "role": { "en": "Legacy Android to Flutter migration", "ar": "..." },
      "domain": "Travel", "featured": true },

    { "id": "mokaf", "name": "Mokaf", "platforms": ["ios", "android"],
      "store": {},
      "role": "Smart parking — real-time maps, QR, TAP / Apple Pay / STC Pay",
      "domain": "Mobility", "featured": true },

    { "id": "az-courses", "name": "AZ Courses", "platforms": ["ios", "android"],
      "store": {
        "ios": "https://apps.apple.com/us/app/azcourses/id1592327429",
        "android": "https://play.google.com/store/apps/details?id=com.crazyidea.coursesexams"
      },
      "role": "Redesign and rebuild — video, PDF, audio delivery",
      "metric": "15,000+ downloads",
      "domain": "Education", "featured": true },

    { "id": "enjoy", "name": "Enjoy", "platforms": ["ios"],
      "store": { "ios": "https://apps.apple.com/us/app/enjoy4/id6447956809" },
      "role": "E-scooter rental — BLE QR unlock, in-app navigation",
      "domain": "Mobility", "featured": true },

    { "id": "malboos", "name": "Malboos", "platforms": ["ios"],
      "store": { "ios": "https://apps.apple.com/us/app/malboos/id6736588728" },
      "domain": "Retail", "featured": true },

    { "id": "tiara-beauty", "name": "Tiara Beauty", "platforms": ["ios"],
      "store": { "ios": "https://apps.apple.com/us/app/tiara-beauty/id6502843404" },
      "domain": "Services", "featured": true },

    { "id": "tekrar", "name": "Tekrar", "platforms": ["ios"],
      "store": { "ios": "https://apps.apple.com/us/app/tekrar/id6499494802" }, "domain": "Education" },
    { "id": "wasset", "name": "Wasset", "platforms": ["ios"],
      "store": { "ios": "https://apps.apple.com/sa/app/wasset/id6474965574" }, "domain": "Marketplace" },
    { "id": "snunu", "name": "Snunu", "platforms": ["ios"],
      "store": { "ios": "https://apps.apple.com/us/app/snunu/id1627473292" }, "domain": "Consumer" },
    { "id": "mostaqbaly", "name": "Mostaqbaly", "platforms": ["ios"],
      "store": { "ios": "https://apps.apple.com/us/app/mostaqbaly/id6444834706" }, "domain": "Education" },
    { "id": "az-exams", "name": "AZ Exams", "platforms": ["android"],
      "store": { "android": "https://play.google.com/store/apps/details?id=com.crazyidea.coursesexams" }, "domain": "Education" }
  ]
}
```

Six `featured: true` maximum — those appear in Recruiter Mode and on `/brief`. The rest live on `/work`.

**Verify every store link resolves before Milestone 1 ships.** A dead App Store link on a portfolio is worse than omitting the app.

---

### Fields added in milestone 4

| Field | Notes |
|---|---|
| `role` | **Now `LocalizedText`, not a string.** It could not hold Arabic, which is most of what a reader sees on `/work`. |
| `engagement` | `freelance` or `contract`, absent where the content does not say. "Shipped 25+ applications" reads differently once a reader can see which he was hired directly to build, and that distinction is the owner's to claim rather than one a reader should infer. |
| `screenshot` | Asset path. Absent, the row draws its procedural station card — a designed treatment rather than a gap. A path pointing at nothing falls back to the same card, so a typo degrades quietly instead of breaking a row. Convention in `assets/media/apps/README.md`. |
| `country` | Two-letter code, used to place the card's origin mark. |

**Platforms.** `ios`, `android`, and `pub` *(4)*. A pub.dev package has a
public listing anyone can open, which satisfies the owner's live-links rule,
but it is not something a person installs — so the ledger offers it as
"pub.dev" rather than under a store's name. That distinction is why it needed
its own value rather than being squeezed into an existing one.

**Domains.** `Travel`, `Mobility`, `Education`, `Retail`, `Services`,
`Marketplace`, `Consumer`, `Safety` *(4)*, `Open source` *(4)*. The enum is
exhaustive in `work_domain_label.dart` on purpose: adding a domain must fail to
compile there rather than fall through to a default.

**Featured.** At most six, enforced by the parser. `/brief` and Recruiter Mode
render exactly this set.

---

## studies/{slug}.json

Three case studies at Milestone 2. Recommended: **Mokaf** (payments, hard integration, tight delivery), **AZ Courses** (scale, 15k downloads, multi-format media), **Tripster** (legacy migration, measurable performance gain).

```json
{
  "id": "mokaf",
  "title": { "en": "Mokaf", "ar": "..." },
  "context": { "en": "...", "ar": "..." },
  "problem": { "en": "...", "ar": "..." },
  "approach": { "en": "...", "ar": "..." },
  "outcome": { "en": "...", "ar": "..." },
  "stack": ["Flutter", "Google Maps SDK", "TAP SDK", "Apple Pay", "STC Pay"],
  "screens": [
    { "src": "assets/screens/mokaf/01.webp", "caption": { "en": "...", "ar": "..." } }
  ],
  "prototype": {
    "url": "https://example.com/prototype",
    "status": { "en": "Early-stage prototype. No company formed.", "ar": "..." }
  }
}
```

`prototype` is **optional** and only City Loom is expected to carry one.
`02-SCREEN-SPECS.md` embeds its walking-tour prototype live at the top of that
study, behind a poster and a click-to-load control, with one honest status line
above it — and no field carried either, so this was added when `/work/:slug`
was built. Omit the key entirely for a study with no prototype.

**Which three studies.** This section recommends Mokaf, AZ Courses and
Tripster. `02-SCREEN-SPECS.md` and `09-ROADMAP.md` both say Mokaf, AZ Courses
and **City Loom**, and give City Loom its own section and the embedded
prototype. The two later documents agree with each other, so they are treated
as current; this recommendation is the outlier. Recorded in
`docs/11-OPEN-ISSUES.md`.

Structure every study as context → problem → approach → outcome. Outcome carries a number wherever one honestly exists. Where no number exists, say what changed qualitatively rather than inventing a percentage.

---

## education.json

Every text field here became `LocalizedText` in milestone 4. They were plain
strings, so `/about` printed English awards and module names in the Arabic
channel no matter what the content said.

```json
{
  "entries": [
    {
      "institution": { "en": "University of Salford", "ar": "جامعة سالفورد" },
      "award": {
        "en": "MSc Managing Innovation & Information Technology",
        "ar": "..."
      },
      "start": "2025-09", "end": "2026-09",
      "status": { "en": "Distinction", "ar": "امتياز" },
      "overallMark": 79,
      "modules": [
        {
          "name": { "en": "Business Data Insights & Analytics", "ar": "..." },
          "mark": 94,
          "evidence": {
            "src": "assets/media/bdia-dashboard.jpg",
            "caption": {
              "en": "Power BI dashboard built for the module",
              "ar": "..."
            }
          }
        },
        { "name": { "en": "Research Methods for Managers", "ar": "..." }, "mark": 72 }
      ],
      "highlights": [
        { "en": "Dissertation: human oversight and accountability in generative AI adoption within Big Four consulting firms", "ar": "..." }
      ]
    }
  ]
}
```

**Keep every mark here.** This file is the record. `/about` publishes only
modules at or above `EducationTable.publishableMark` (80), because the owner
asked for his strongest results rather than a transcript — but the filter is
presentation, and trimming the content to achieve a layout would destroy data.
The static `/cv` renders from the same file and prints all of them, which is
the right split: an ATS reads everything, a skimming human reads the best four.

**On `evidence` *(4)*:** optional, per module. A mark is a number a reader
takes on trust; the coursework behind it is what turns it into evidence, which
is `14-PROVENANCE.md`'s argument applied to a transcript. Only two modules
carry one because only two artefacts were supplied — not because the rest were
filtered.

Evidence renders as a card in a row beneath the transcript, naming its module
and leading with its mark, and opens full size on a press. It is deliberately
not attached under its own module row: stacked there the cards pushed the marks
apart and read as a column of unrelated pictures.

Anything published here ships in the repository and on the live site. The
research poster was cropped before it shipped, to remove a header band carrying
the owner's name and student number — a matriculation number has no reason to
be on a public page.

---

## interests.json *(4)*

What the owner does when he is not working. A separate document from
`profile.json` because it is the part a recruiter may never read and the owner
cares most about — so it can grow, or be pulled entirely, without touching the
identity every other surface depends on.

```json
{
  "interests": [
    { "id": "gym", "label": { "en": "The gym", "ar": "النادي الرياضي" } },
    {
      "id": "television",
      "label": { "en": "Television", "ar": "المسلسلات" },
      "note": { "en": "Better Call Saul", "ar": "Better Call Saul" }
    }
  ]
}
```

| Field | Required | Notes |
|---|---|---|
| `id` | yes | Unique. Seeds the tile's procedural mark, so it must be stable — changing it redraws the art. |
| `label` | yes | What the interest is. |
| `note` | no | The specific the owner named. Absent where he named none, and nothing infers one: a favourite show is a claim about a person exactly as a download count is. |

**On `note`:** "television" says nothing and "Better Call Saul" says a great
deal. That is the whole reason the field exists. It renders as always-visible
text beneath the label rather than behind a hover — a fact worth putting on the
page is worth a touch user and a screen reader getting it.

---

## Static route generation

`tool/generate_static.dart` reads `profile.json`, `career.json`, `apps.json` and `education.json` and writes `web/cv/index.html` and `web/brief/index.html`.

Contract:
- Runs in CI before `fvm flutter build web`
- Output is committed-ignored; generated fresh each build
- Pure semantic HTML with inline critical CSS. No JavaScript. No external requests.
- `/cv` includes JSON-LD `Person` with `alumniOf`, `knowsAbout`, `sameAs`

This guarantees the indexable pages can never drift out of sync with the app.

---

## Skills — what to list and what not to

List with confidence: Flutter, Dart, Swift/SwiftUI/UIKit, Firebase, REST, CI/CD (GitHub Actions, Codemagic, Fastlane), testing, clean architecture, Git, Jira, Azure DevOps, Power BI.

**Do not list n8n, RAG or AI automation as a skill.** The learning is weeks old and a recruiter who probes it will find the floor immediately. Instead, the n8n digest pipeline (see `06-ANALYTICS-AND-PRIVACY.md` §7) runs this site's own reporting, and it is described on `/how-it-was-built` as part of the build. Demonstrated beats claimed, and it converts a weak line into a strong one.

Revisit once two or three real workflows are running in production.

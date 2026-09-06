# Content Schema — NOCTURNE

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
  "cvFile": "assets/cv/Ahmed_Elsherbini_Mobile.pdf",
  "portrait": { "src": "assets/img/portrait.webp", "isPlaceholder": true }
}
```

**On `venture`:** keep the "(early stage)" qualifier until City Loom has a live product. An unqualified co-founder claim on an unlaunched venture is the kind of thing a recruiter checks and holds against you. Qualified, it reads as initiative.

**On `status`:** "predicted Distinction" only. The dissertation is not marked. Do not write "Distinction" or "MSc graduate" anywhere on this site until the award is confirmed.

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
    { "id": "evri", "country": "GB", "city": "Manchester", "coords": [53.4808, -2.2426], "start": "2025-11", "end": null }
  ]
}
```

`traceWeight` (0–1) sets burst amplitude. `coords` are `[lat, lon]` and feed `core/painting/projection.dart`.

**On Evri:** include it. A recruiter who sees an unexplained gap assumes the worst; a warehouse role alongside an MSc reads as someone who works. Keep the summary to one factual line and let it sit quietly in the sequence — the trace weight should be low so it does not compete with the engineering roles.

---

## apps.json

Real, verifiable, publicly linked. This is the strongest evidence on the site and it should be impossible to miss.

```json
{
  "apps": [
    { "id": "tripster", "name": "Tripster", "platforms": ["ios"],
      "store": { "ios": "https://apps.apple.com/ru/app/id1479200934" },
      "role": "Legacy Android to Flutter migration",
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

```json
{
  "entries": [
    {
      "institution": "University of Salford",
      "award": "MSc Managing Innovation & Information Technology",
      "start": "2025-09", "end": "2026-09",
      "status": "In progress — predicted Distinction",
      "overallMark": 79,
      "modules": [
        { "name": "Business Data Insights & Analytics", "mark": 94 },
        { "name": "Managing Information Systems & Transformation", "mark": 86 },
        { "name": "Cybersecurity & Information Management", "mark": 81 },
        { "name": "Responsible Technologies", "mark": 80 },
        { "name": "Managing Project Deployment & Delivery", "mark": 75 },
        { "name": "Research Methods for Managers", "mark": 72 },
        { "name": "Managing Innovation & Creativity", "mark": 70 }
      ],
      "highlights": [
        "Dissertation: human oversight and accountability in generative AI adoption within Big Four consulting firms",
        "Led a smartphone manufacturer in the Edumundo strategy simulation — 2nd of cohort"
      ]
    },
    {
      "institution": "Mansoura University",
      "award": "BEng Communications & Electronics Engineering",
      "start": "2015-09", "end": "2020-08"
    }
  ]
}
```

The 94 in Business Data Insights & Analytics is the highest mark on the transcript and currently appears on none of the CVs. It belongs on the site, and it is the strongest single number for any data or analytics route.

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

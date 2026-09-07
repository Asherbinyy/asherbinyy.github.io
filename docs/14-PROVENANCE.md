# Provenance — KEMET

Every claim this site makes about the owner, and where it came from.

**A number without a row here does not ship.** `AGENTS.md` §3 already forbade
inventing figures; this file makes the rule checkable instead of a matter of
trust. It exists because the owner asked, reasonably, why the site was making
things up — and the answer turned out to be that it mostly was not, but nothing
in the repository could demonstrate that.

Last reviewed: 2026-09-07.

---

## 0. Sources

| Key | Source | Held where |
|---|---|---|
| **CV1**, **CV2** | `main resume.pdf`, pages 1 and 2 | `supporting files/` — not in git |
| **LI-P** | LinkedIn profile screenshot | `supporting files/Linkedin profile 1.png` |
| **LI-X** | LinkedIn projects screenshot, 16 entries | `supporting files/Linkedin profile 2.png.png` |
| **MED** | Medium profile screenshot, 6 articles | `supporting files/medium.png` |
| **OWN** | The owner, stated directly in conversation | Dated in the row |
| **PUB** | A public page, fetched and verified | URL in the row |

`supporting files/` is **excluded from git** and stays that way — it holds a CV
with a phone number, coursework and personal photographs. Individual assets may
be copied into `assets/` when a feature needs them, per the owner's permission
of 2026-09-07.

---

## 1. Claims currently on the site

| Claim | Where rendered | Source | Status |
|---|---|---|---|
| "25+ applications shipped" | `profile.json` positioning, stat panel | **CV1** — "Delivered 25+ projects" | ✅ |
| "6 countries" | positioning, stat panel, `/brief` | — | ⚠️ **See §2.1** |
| "4+ years commercial" | stat panel | **CV1** — "4+ years of commercial experience" | ✅ |
| "16+ Flutter applications" | CI Company summary | **CV2** — "16+ mobile apps using Flutter and Dart" | ✅ |
| "Mentored a team of three" | CI Company summary | **CV2** — "Led and mentored a team of 3 developers" | ✅ |
| "15,000+ downloads" | AZ Courses metric | **CV2** | ⚠️ **See §2.2** |
| "reducing development time by 50%" | Hwzn Tech summary | **CV2** | ✅ |
| "delivery time by a further 20%" | Hwzn Tech summary | **CV2** — "cutting project delivery time by 20%" | ✅ |
| "improving performance by 20%" | Ar++ summary | **CV2** | ✅ |
| "reducing bug rates by 30%" | Ar++ summary | **CV2** | ✅ |
| "MVP delivered in under eight weeks" | Techlabs summary | **CV1** | ✅ |
| MSc, Distinction, overall 79 | `education.json`, `/about`, `/brief` | **OWN**, corroborated **CV1**/**LI-P** for award and dates | ✅ |
| Seven module marks | `/about` education table | **OWN** | ⚠️ **See §2.3** |
| "Edumundo simulation — 2nd of cohort" | education highlight | **OWN**, corroborated **MED** (*NEXO: My First Time as CEO*) | ✅ |
| Dissertation topic | education highlight | **OWN** | ⚠️ Owner asked to withhold until published — **§3.4** |
| BEng, Mansoura, 2015–2020 | `education.json` | **CV1**, **LI-P** | ✅ |
| Employer names, titles, dates | `career.json` | **CV1**/**CV2**, corroborated **LI-P** | ⚠️ one conflict — **§2.4** |
| Eleven application entries | `/work` ledger | `apps.json`; store links hand-verified milestone 1 | ✅ |
| Contact details, profile links | `profile.json` | **CV1**, **OWN** | ✅ |

---

## 2. Conflicts and overstatements — resolve before milestone 4 ships

### 2.1 "Six countries" is currently an overstatement

**CV1** names five countries of delivery: Canada, Qatar, Saudi Arabia, Armenia,
Egypt. The site counts six by adding the United Kingdom, which is where the
owner lives and studies — not somewhere an application was shipped from or for.

The honest reading changes with Guardy: a German product, built as a
freelancer, gives a genuine sixth. **Resolution: confirm Guardy (§3.1), then
six is true.** Until then the figure is five, or the phrasing changes to
"across five countries, from six".

### 2.2 AZ Courses downloads: 15,000 or 8,000

**CV2** says "over 15,000 downloads on Android and iOS". **LI-X** says "Over
8,000 downloads on both Android and iOS platforms". The site shows 15,000+.

Same app, two figures the owner wrote himself, most likely at different times.
Not resolvable from the sources. **Owner decides — §3.2.**

### 2.3 Module marks — trim and correct

The owner asked on 2026-09-07 to show only the top-performing modules, and to
correct a mark of 74% to 75%. `education.json` currently holds seven modules
and contains **no 74**. The nearest is Managing Project Deployment & Delivery at
75, which is already the requested value.

**Unresolved: which mark is the 74.** Possibly the dissertation, which is not in
the file. Do not guess — **§3.3.**

### 2.4 CI Company end date

**CV2** gives 10/2021 – 04/2023. **LI-P** gives Oct 2021 – Jul 2023, "1 yr 10
mos". `career.json` follows the CV. A three-month difference across a job
boundary is the kind of thing an interviewer notices. **Owner confirms — §3.5.**

---

## 3. Open — needed from the owner before the claim can ship

| # | Needed | Blocks |
|---|---|---|
| **3.1** | **Guardy.** Dates, engagement type (freelance/contract), and what was built in v1. Verified so far: Guardy GmbH, Düsseldorf; personal-safety app with live location sharing, live streaming and community alerts (**PUB** guardyapp.de, fetched 2026-09-07). Store listing `apps.apple.com/de/app/guardy/id6504706012` not yet verified — the fetch was rate-limited. | 4.2, and §2.1 |
| **3.2** | **AZ Courses downloads** — 15,000 or 8,000. | 4.1 |
| **3.3** | **The 74% → 75%** — which module or component. And which modules count as "top performing", or a cutoff. | 4.6 |
| **3.4** | **Dissertation** — withheld until published. Confirm what, if anything, may be said meanwhile. | 4.6 |
| **3.5** | **CI Company end date** — April or July 2023. | 4.1 |
| **3.6** | **Tiara Beauty** — freelance? dates? what was built? Currently in `apps.json` with a store link and no role. | 4.2 |
| **3.7** | **Origins.** Born in Saudi Arabia — which city. Raised in Egypt — Mansoura, and from what year. Left Egypt 2025 at 28. Manchester 2025–present. Birth year is inferable as ~1997 but **inference is not a source**. | 4.3 |
| **3.8** | **The 16 LinkedIn projects** (**LI-X**) — which may be published. Several are client work under a former employer and that is the owner's call, not an agent's. Full list in §4. | 4.2 |
| **3.9** | **Hobbies.** Stated: gym, football, padel, TV (*Better Call Saul*), reading, e-sports (FIFA, Valorant). Needed: anything to avoid, and whether a favourite book or team should appear. | 4.4 |
| **3.10** | **Name recording** — the owner saying "Sherbini". Owner to supply. | 4.7 |
| **3.11** | **App screenshots** — Mokaf, AZ Courses, City Loom, and any others. Long outstanding as `11-OPEN-ISSUES.md` 1.10. | 4.13, 2.1 |
| **3.12** | **CV PDF** — may `main resume.pdf` be committed to `assets/`? It carries a phone number already published in `profile.json`. | 4.12 |
| **3.13** | **Portrait** — `supporting files/profile/` holds two candidates. Which, and may it be committed? | 4.4 |
| **3.14** | **Cartouche transliteration** — š-r-b-i-n-i needs a check by someone who reads Egyptian (`12-MOTIF-LIBRARY.md` §2). | 5.5 |
| **3.15** | **Evri.** Still the one role the CV does not cover, open since milestone 1 as `11-OPEN-ISSUES.md` 1.7. Started 2025-11 per `career.json`. | 4.2 |

---

## 4. The sixteen LinkedIn projects (LI-X)

Not on the site. All descriptions below are the owner's own words from
LinkedIn, transcribed, not summarised. Publication is gated on §3.8.

| Project | Dates | Attributed to |
|---|---|---|
| Tripster | Feb 2024 – present | Ar++ |
| MiNextStep | Jun 2023 – Feb 2024 | MiNextStep |
| Az Courses | Apr 2023 – Jul 2023 | Crazy Idea |
| Meswak — medical care platform | Feb 2023 – May 2023 | Crazy Idea |
| SMS — bulk messaging platform | Feb 2023 – May 2023 | Crazy Idea |
| Enjoy — e-scooter and bicycle rental, Saudi Arabia | Jan 2022 – Apr 2023 | Crazy Idea |
| Spix — parcel shipping | Dec 2022 – Apr 2023 | Crazy Idea |
| **Easy Go — a Flutter navigation package** | Dec 2022 – Jan 2023 | **Self-employed** |
| Moawda — classified-ads marketplace | Nov 2022 – Jan 2023 | Crazy Idea |
| Courses Exams | Sep 2022 – Dec 2022 | Crazy Idea |
| Kafu — second-hand marketplace | Oct 2022 – Dec 2022 | Crazy Idea |
| Ayrobot — financial CMS | Sep 2022 – Oct 2022 | Crazy Idea |
| Mostaqbaly — education | Sep 2022 – Oct 2022 | Crazy Idea |
| Weze — travel and tourism | Jul 2022 – Oct 2022 | Crazy Idea |
| Jumper — recruitment platform | May 2022 – Sep 2022 | Crazy Idea |
| Absher — medical directory | Jul 2022 – Aug 2022 | Crazy Idea |

Two things worth the owner's attention:

- **"Crazy Idea" is the employer the CV calls "CI Company."** `career.json` uses "CI Company". LinkedIn shows "Crazy Idea" publicly. One of the two should win, and the site should not show a name the owner's own LinkedIn contradicts.
- **Easy Go is an open-source Flutter package**, published as self-employed work. It is the only open-source artifact in the whole record and it is currently invisible on a portfolio for a Flutter engineer. Worth surfacing on its own terms.

---

## 5. The six Medium articles (MED)

Rendered on `/writing` from the live RSS relay, so titles and dates are
authoritative from the feed rather than this file. Recorded here because
milestone 4 pairs each with its real cover image.

| Article | Published |
|---|---|
| NEXO: My First Time as CEO | 2 Dec 2025 |
| Is TikTok Helping Students Cope or Just Helping Them Procrastinate? | 1 Dec 2025 |
| When Chatbots become your new colleague | 20 Nov 2025 |
| Parliament 2.0: Meet Diella, the First AI Minister | 17 Nov 2025 |
| BritCard or Big Brother? | 9 Oct 2025 |
| Flutter – How to make News Ticker Widget | 1 Jan 2023 |

Cover images belong to Medium and are hotlinked from the feed, not copied into
the repository.

---

## 6. Corrections already made

| Date | Was | Now | Source |
|---|---|---|---|
| 2026-09-06 | Award hedged as "expected" | Distinction stated | Owner's CV |
| 2026-09-07 | — | This ledger created | Owner asked why figures appeared invented |

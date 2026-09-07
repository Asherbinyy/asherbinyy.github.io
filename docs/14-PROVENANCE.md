# Provenance — KEMET

Every claim this site makes about the owner, and where it came from.

**A number without a row here does not ship.** `AGENTS.md` §3 already forbade
inventing figures; this file makes the rule checkable instead of a matter of
trust. It exists because the owner asked, reasonably, why the site was making
things up — and the answer turned out to be that it mostly was not, but nothing
in the repository could demonstrate that.

Last reviewed: 2026-09-07, at the close of Milestone 4.

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

### 2.2 AZ Courses downloads — RESOLVED 2026-09-07

**CV2** said "over 15,000 downloads"; **LI-X** said "Over 8,000". The owner
confirmed the CV figure is current and the LinkedIn entry is stale. The site
keeps **15,000+**, sourced to CV2.

Recorded so the next agent does not re-open it: the LinkedIn discrepancy is
known and is not evidence the site is inflating anything.

### 2.3 Module marks — PARTLY RESOLVED 2026-09-07

The owner confirmed the "74% → 75%" refers to **Managing Project Deployment &
Delivery, already recorded at 75**. No change is needed and the module stays in
the published set.

Still open: which modules count as "top performing", since the owner asked for
the table to be trimmed. Seven are recorded (94, 86, 81, 80, 75, 72, 70) and
the request was for the strongest only. **§3.3.**

### 2.4 CI Company — name RESOLVED, date still open

**Name.** The owner chose to keep **"CI Company"**, the CV's name, over the
"Crazy Idea" shown publicly on LinkedIn. The site now matches the document that
reaches recruiters first. Closes `11-OPEN-ISSUES.md` 0b.5.

Worth the owner knowing: the two public records still disagree, and updating the
LinkedIn entry would close it from the other side.

**Date.** Unresolved. **CV2** gives 10/2021 – 04/2023; **LI-P** gives Oct 2021 –
Jul 2023. `career.json` follows the CV. **§3.5.**

---

## 3. Open — needed from the owner before the claim can ship

| # | Needed | Blocks |
|---|---|---|
| ~~3.1~~ | **Closed.** The owner described the work on 2026-09-07: showcase and shop features, cloud functions, structural and UI improvements, and bug fixes. Listing verified live — Guardy GmbH, Navigation, first released 2024-07-17, now v3.0.1. **He did not give engagement dates**, so Guardy ships as an application rather than a career stop: an application needs no date range and a map stop does. Germany is now his sixth country. Original entry: **Guardy.** Dates, engagement type (freelance/contract), and what was built in v1. **Store listing verified 2026-09-07** via the iTunes lookup API: *Guardy*, seller **Guardy GmbH**, Navigation category, first released **17 July 2024**, currently v3.0.1. Product verified at **PUB** guardyapp.de — personal-safety app with live location sharing, live streaming and community alerts. The 2024 release date is consistent with the owner's account of building v1 as a freelancer. What is still needed is his engagement dates and what he specifically built. | 4.2, and §2.1 |
| **3.2** | **AZ Courses downloads** — 15,000 or 8,000. | 4.1 |
| ~~3.3~~ | **Closed.** The 74 was MPDD, already recorded at 75. The owner set the publish line at 80, so `/about` shows four of seven modules and `/cv` keeps the full transcript. Original entry: **The 74% → 75%** — which module or component. And which modules count as "top performing", or a cutoff. | 4.6 |
| ~~3.4~~ | **Closed.** The topic stays, findings and paper do not, until it is published. Original entry: **Dissertation** — withheld until published. Confirm what, if anything, may be said meanwhile. | 4.6 |
| ~~3.5~~ | **Closed.** April 2023, the CV's figure. LinkedIn still shows July 2023; correcting it there is the owner's to do. Original entry: **CI Company end date** — April or July 2023. | 4.1 |
| ~~3.6~~ | **Closed.** Freelance, late 2024, built with one other developer. Dates not recorded to the month because the owner does not remember them, and `apps.json` needs none. Original entry: **Tiara Beauty** — freelance? dates? what was built? Currently in `apps.json` with a store link and no role. | 4.2 |
| ~~3.7~~ | **Closed, and narrowed.** The owner withdrew Saudi Arabia: he is from **Mansoura, Egypt**, and that is all the site says. The journey now opens at Mansoura University in 2015 and closes at Salford in 2026 — both already in `education.json`, so the map gained an origin and a present **without a single new claim** and without needing a birth year nobody sourced. Original entry: **Origins.** Born in Saudi Arabia — which city. Raised in Egypt — Mansoura, and from what year. Left Egypt 2025 at 28. Manchester 2025–present. Birth year is inferable as ~1997 but **inference is not a source**. | 4.3 |
| ~~3.8~~ | **Resolved 2026-09-07.** The owner's rule is **live store links only**. A sweep of the App Store found no live listing for Meswak, Spix, Moawda, Kafu, Weze, Jumper or Absher, so most of the sixteen are excluded by that rule rather than by judgement. See §4. | — |
| ~~3.9~~ | **Closed.** Gym, football, padel, reading, television (*Better Call Saul*), e-sports (FIFA and Valorant). In `interests.json`, in his own terms, with nothing added. Original entry: **Hobbies.** Stated: gym, football, padel, TV (*Better Call Saul*), reading, e-sports (FIFA, Valorant). Needed: anything to avoid, and whether a favourite book or team should appear. | 4.4 |
| **3.10** | **Name recording** — the owner saying "Sherbini". Owner to supply. | 4.7 |
| **3.11** | **App screenshots** — Mokaf, AZ Courses, City Loom, and any others. Long outstanding as `11-OPEN-ISSUES.md` 1.10. | 4.13, 2.1 |
| ~~3.12~~ | **Closed.** Committed to `assets/docs/`, `profile.cvFile` is set, and the hero's second action now reads *Download the CV*. Original entry: **CV PDF** — may `main resume.pdf` be committed to `assets/`? It carries a phone number already published in `profile.json`. | 4.12 |
| ~~3.13~~ | **Closed.** The studio frame, matching the shot brief. Cropped to 4:5, 107KB. Original entry: **Portrait** — `supporting files/profile/` holds two candidates. Which, and may it be committed? | 4.4 |
| **3.14** | **Cartouche transliteration** — š-r-b-i-n-i needs a check by someone who reads Egyptian (`12-MOTIF-LIBRARY.md` §2). | 5.5 |
| ~~3.15~~ | **Closed by removal.** The owner instructed on 2026-09-07 to drop Evri entirely. It was the one role his CV never covered and had been open since milestone 1. Original entry: **Evri.** Still the one role the CV does not cover, open since milestone 1 as `11-OPEN-ISSUES.md` 1.7. Started 2025-11 per `career.json`. | 4.2 |

---

## 4. The sixteen LinkedIn projects (LI-X)

All descriptions are the owner's own words from LinkedIn, transcribed, not
summarised.

**Publication rule, set by the owner on 2026-09-07: live store links only.** A
sweep on that date found no live App Store listing for Meswak, Spix, Moawda,
Kafu, Weze, Jumper or Absher, so they do not ship. This is not a judgement that
the work is unimportant — it is that a portfolio row a recruiter cannot open is
a claim rather than evidence, which is the whole argument of this file.

They stay recorded here so the record is complete and so a future agent does not
rediscover them and assume they were missed.

| Project | Dates | Attributed to |
|---|---|---|
| Tripster | Feb 2024 – present | Ar++ |
| MiNextStep | Jun 2023 – Feb 2024 | MiNextStep |
| Az Courses | Apr 2023 – Jul 2023 | Crazy Idea |
| Meswak — medical care platform | Feb 2023 – May 2023 | Crazy Idea |
| SMS — bulk messaging platform | Feb 2023 – May 2023 | Crazy Idea |
| Enjoy — e-scooter and bicycle rental, Saudi Arabia | Jan 2022 – Apr 2023 | Crazy Idea |
| Spix — parcel shipping | Dec 2022 – Apr 2023 | Crazy Idea |
| **Easy Go — a Flutter navigation package** | Dec 2022 – Jan 2023 | **Self-employed** — **now published**, see §3c |
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

## 3b. Added in Milestone 4, and where it came from

| Claim | Source |
|---|---|
| Guardy's role text | **OWN**, 2026-09-07, transcribed not summarised |
| Guardy is a German product | **PUB** guardyapp.de and the App Store listing, both fetched 2026-09-07 |
| Tiara Beauty is freelance, built with one other developer | **OWN**, 2026-09-07 |
| The journey opens at Mansoura University, 2015–2020 | **CV1**, already in `education.json` |
| The journey closes at Salford, 2025–2026 | **CV1**, already in `education.json` |
| Six interests, and the two specifics | **OWN**, 2026-09-07, verbatim |
| Power BI dashboard beside the 94 | Owner's coursework, supplied and cleared 2026-09-07 |
| Research poster beside the 80 | Owner's coursework, supplied and cleared 2026-09-07. **Cropped**: the original carries his name and student number in a header band, and a matriculation number is an identifier with no reason to be on a public page. The caption carries the title instead. |
| The portrait | Owner's photograph, cleared 2026-09-07 |
| The CV PDF | `main resume.pdf`, cleared 2026-09-07 |

Nothing in this milestone was inferred. Where a fact was missing — Guardy's
engagement dates, Tiara's months, a birth year — the feature was shaped around
the gap rather than the gap being filled.

---

## 3c. Easy Go

Published on the owner's instruction of 2026-09-07, after he supplied the link.

| Field | Source |
|---|---|
| Listing | **PUB** <https://pub.dev/packages/easy_go>, verified live 2026-09-07: v1.0.1, MIT |
| What it does | The package's own description: routing and navigation, custom page transitions, named routes, data passing |
| Self-employed | **LI-X**, the owner's own attribution |

**Two things the owner should know.** pub.dev lists the author as *Ahmed
Elsherbiny* at `ahmed.elsherbiny2020@gmail.com` — a different spelling of the
surname and a different address from the one on this site. It is plainly his
package and he supplied the link, but a recruiter comparing the two will see
the mismatch, and only he can correct the pub.dev side. Second, the listing is
marked **unverified uploader**; claiming a verified publisher domain would
strengthen it.

**No engagement figures are published.** pub.dev reports likes, pub points and
a download count; none appears on the site. They are small numbers that would
weaken a genuinely strong fact — that he has shipped an open-source package at
all — and `AGENTS.md` §3 does not require a figure to be published merely
because it exists.

---

## 4b. Store-link verification, 2026-09-07

Every iOS link in `apps.json` was re-checked against the iTunes lookup API in
its own storefront. `05-TESTING.md` requires links be verified by hand; this is
the machine sweep that says which need looking at, not a replacement for it.

**All eight live links still resolve.** No rot since milestone 1.

| App | Result |
|---|---|
| Tripster | LIVE — *Tripster: экскурсии, аудиогиды*, Mego.travel, v2.5.1 |
| AZ Courses | LIVE — *azcourses*, Abdallah Abou El Ezz, v20.0.1 |
| Enjoy | LIVE — *ENJOY4*, ibrahim el refaey, v1.1.1 |
| Malboos | LIVE — *Malbos*, HWZN TECH, v1.3.2 |
| Tiara Beauty | LIVE — *Tiara Beauty*, v1.3 |
| Tekrar | LIVE — *Tekrar*, Manal Al Hadrami, v1.1.2 |
| Wasset | LIVE — *Wasset*, Hawazen, v1.0 |
| Mostaqbaly | LIVE — *mostaqbaly*, ibrahim el refaey, v1.0 |
| Mokaf, Snunu, AZ Exams | no iOS link on record — `11-OPEN-ISSUES.md` 1.3–1.5 |
| **Guardy** | LIVE — *Guardy*, Guardy GmbH, v3.0.1, first released 2024-07-17 |

Note that the seller on several listings is the client, not the owner. That is
normal for contract and agency work and is not evidence against the claim; it is
also why a store link alone is not provenance for authorship, and why each app's
role text still traces to the CV or to LinkedIn.

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

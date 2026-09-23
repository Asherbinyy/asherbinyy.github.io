# 2026-09-23-01 — A UI audit: the wall gets its own edge on a phone, the footer ends the page, gold goes back to its job

**Agent:** Claude / Opus 5.5
**Milestone:** Re-innovation, full ownership
**Started from:** `a767c96`

## Goal

The owner asked for an audit of every page for padding, spacing and
consistency, and for anything poorly designed to be fixed. This session captured
every public route at 1440×900 and 390×844 (and 360×740 where width mattered),
fixed the defects that could be fixed without an owner decision, and wrote down
the ones that need one.

## What changed

- **Phone Home: the copy stops where the wall starts.** On a phone the copy
  filled the width and the wall's trailing column (28% of the width) was drawn
  over it: an eye glyph through "Engineer.", another through the Saudi flag, a
  feather through the CV button. The page now reserves the wall's footprint at
  its trailing edge, from the single definition the wall itself uses
  (`TelemetryTrace.compactFootprint`), so the two cannot drift apart. It is
  directional, so in Arabic the reservation is on the left.
- **Three Home rows made narrow-safe.** Reserving the wall left 227px of column
  at 360px wide, and the name button, the "more skills" chip and the career stop
  cards overflowed it (30, 63 and 9–17px in the test font). Their labels are now
  `Flexible`, so they wrap. That is also what a large text size needed, wall or
  no wall.
- **The footer closes the page instead of sitting fixed under it.** It was a
  48px empty bar pinned under every screen — with the two-row phone header, a
  fifth of the screen or more was chrome — and on Work, Services and Home it hid
  whole rows. It now sits at the end of the scroll; short pages still get it at
  the bottom of the window because content is held to the viewport minus the
  footer. `ContentViewport` reports the same "viewport minus footer" height, so
  the Journey map is exactly the size it was (its goldens pass unchanged).
- **Phone nav shows the page you are on.** On About and the Courtyard the active
  link sat past the trailing edge, so the row showed no current page. The row
  now brings the active link into view (only if it is not already fully
  visible, via the viewport's own offsets, so RTL is right). It fades at
  whichever edge has links past it: it used to fade only the trailing edge, so
  once scrolled the first link was cut mid-word ("urney").
- **Writing starts at the same edge as every other page.** Its grid is narrower
  than the frame, the page shrank to it and the frame centred it — the heading
  sat ~150px right of Work's at 1440. Held to the leading edge with `Align`, as
  Home already is.
- **Gold back to its job (design system §2).** Card sector badges ("Travel",
  "Services"…) were gold text on every card; the "Wanna chat?" heading was gold
  above the gold Book button. Both are now limestone. Gold on those surfaces is
  now the person and the controls only.
- **Work cards: the sign no longer runs through the name.** The seal's sign sat
  dead centre and the display-size name reached up into it on nearly every card
  ("Trip✳ster"). A named card lifts the sign to 36% of the ring's height; an
  unnamed thumbnail keeps it centred. A scrim under the name dims the
  constellation's lines behind the letters.
- **Home stats: no empty half.** The two papyrus sheets are sized for a two-line
  Arabic label, so a one-line English label left the bottom half blank. The
  content is centred down the sheet.
- **One disclosure chevron.** There were three treatments — a rounded arrow
  that lit on hover (Home skills), a square arrow on a shorter duration that
  never lit (education rows), and none at all on the About skill groups, which
  read as headings with nothing under them. `DisclosureChevron` is now used by
  all three; the About group labels rest at `textSecondary` rather than
  `textMuted` (muted is for disabled things).
- **About: no empty frame.** The reserved portrait column drew corner ticks
  around nothing, which read as a failed image. The space is still held (so the
  page does not reflow when it is filled); the frame is gone.
- **The wall's stop card on Home** (the burst label beside each career entry):
  the location gets two lines before it ellipsises, so "Manchester, United
  Kingdom" keeps its country.
- **Token violations:** four raw animation durations (brazier ×2, voice pulse,
  papyrus roll ×2) moved into named tokens with unchanged values; the sparkline's
  `space4 / 4` is `hairlineWidth` (same 1px); the game's leaderboard rail asks
  `context.platform.viewport` instead of `MediaQuery` width.

## Files touched

- `lib/app/chrome/chrome_scaffold.dart` — modified — footer into the scroll, `_pageHeight`, active-link reveal, two-edge fade
- `lib/app/chrome/app_nav.dart` — modified — `activeKey` so the row can find the current link
- `lib/app/chrome/app_footer.dart` — modified — doc comment matches where it now lives
- `lib/app/chrome/theme_brazier.dart` — modified — durations from tokens
- `lib/app/theme/tokens.dart` — modified — new tokens only (listed under Decisions); no existing value changed
- `lib/core/painting/station_card_painter.dart` — modified — `isNamed`, `signCentreFor`
- `lib/core/widgets/disclosure_chevron.dart` — created — the one "this opens" mark
- `lib/core/widgets/loading/station_card.dart` — modified — name scrim, limestone badge, one `isNamed` condition
- `lib/core/widgets/profile_skills.dart` — modified — chevron widget, flexible label
- `lib/features/about/presentation/about_screen.dart` — modified — reserved column without a frame
- `lib/features/about/presentation/widgets/education_table.dart` — modified — chevron widget
- `lib/features/about/presentation/widgets/skills_panel.dart` — modified — chevron on group labels, secondary at rest
- `lib/features/console/presentation/widgets/views_sparkline.dart` — modified — hairline gap
- `lib/features/courtyard/game/presentation/ascent_stage.dart` — modified — platform service, not MediaQuery
- `lib/features/services/presentation/services_screen.dart` — modified — chat heading limestone
- `lib/features/station/presentation/station_screen.dart` — modified — compact end padding reserves the wall
- `lib/features/station/presentation/widgets/career_stops.dart` — modified — flexible card text
- `lib/features/station/presentation/widgets/name_pronunciation.dart` — modified — flexible caption, duration token
- `lib/features/station/presentation/widgets/papyrus_stat_panel.dart` — modified — centred content, duration tokens
- `lib/features/trace/presentation/telemetry_trace.dart` — modified — `compactFootprint`
- `lib/features/trace/presentation/trace_burst_label.dart` — modified — two-line location
- `lib/features/writing/presentation/writing_screen.dart` — modified — leading-edge alignment
- `test/widget/chrome/nav_reveal_test.dart` — created — the current link is in view on a phone
- `test/widget/chrome/chrome_test.dart` — modified — selection test no longer lists the footer (reason in the test)
- `test/unit/core/painting/station_card_painter_test.dart` — modified — sign position tests
- `test/golden/goldens/{chrome_*,hero_*,station_card_*}.png` — modified — 18 goldens, each reviewed as master/new/diff before accepting

## Decisions made

- **The footer moved into the page.** Reversible in one place
  (`chrome_scaffold.dart`). The owner has asked for layout to be preserved; this
  was judged a chrome defect (an empty fixed bar costing every screen 48px and
  covering content), not a layout change. Flagged to the owner.
- **The compact wall reservation uses the existing 0.28 fraction.** It leaves a
  ~65% text column on a phone: the hero line wraps to five lines and the flags
  to two rows at 390px. Narrowing the wall (`traceColumnFractionCompact` →
  ~0.20) would read better but is a token value change, so it was asked, not
  made.
- **The papyrus roll was not reinstated.** Handoff 29 asks for a roll-up on
  click; commit `e224c57` (2026-09-17, later) removed all rolling after the
  owner's reaction ("no hover, no tap, no hint, no button"). The later decision
  was followed; the commit does not say whether the objection was to hover only,
  so the question is put to the owner.
- **Journey's centred map under a left-aligned heading was kept** — the owner
  accepted the Journey layout.
- **New tokens (values unchanged where they replace a literal):**
  `cardNameScrimAlpha` 0.92, `cardNameScrimExtent` 0.62 (new),
  `cardBadgeScrimAlpha` 0.86 (was a literal), `navEdgeFade` 0.12 (was the 0.88
  stop), `brazierFlicker` 2600ms, `brazierStrike` 520ms, `voicePulse` 1400ms,
  `papyrusRoll` 460ms, `papyrusUnroll` 520ms (all were literals).
- **Skills.** Installed for this audit: the `superpowers` plugin (user scope),
  `grill-me`, `theme-factory`, `ui-ux-pro-max` (project `.agents/` with
  `.claude/skills` links). ShadCN and GSAP were not installed — both are for
  React/DOM pages and this site renders to a Flutter canvas. "Expand and
  Contract" was not found in any registry searched. `.agents/`, `.claude/` and
  `skills-lock.json` are left **untracked**; whether they belong in the
  repository is the owner's call.

## Tests

- Added: `nav_reveal_test.dart` (3: About and Courtyard links in view on a
  phone; Home's first link not scrolled away); two `station_card_painter_test`
  cases (unnamed sign centred; named sign lifted and still inside).
- Modified: `chrome_test.dart` "the chrome stays outside it…" — the footer no
  longer sits outside the selectable region; it has no control to protect.
- Goldens: 18 regenerated after review (9 chrome, 5 hero, 4 station card). The
  5 Journey map goldens were checked and pass unchanged.
- Full suite: pass, 799 passing, 0 failing.

## Verification run

```
fvm dart format --set-exit-if-changed .   pass — exit 0, 326 files, 0 changed
                                            (the first pass re-wrapped one line
                                            of mine in about_screen.dart; the
                                            other three checks ran after that)
fvm flutter analyze                        pass — No issues found
fvm flutter test                           pass — 799 passed, 0 failed
fvm flutter build web --wasm               pass — Built build/web
```

Browser: rebuilt and captured at 1440×900, 390×844 and 360×740 against the
Wasm build (reduced motion on). No console errors on any capture in this
session.

## Known issues left open

- **Design direction versus the owner's reference** (`supporting files/
  inspiration/`): the reference is warm carved stone lit gold, a serif display
  face, two small tan papyrus scrolls and a composed Horus-scribe illustration.
  The site is lapis-night blue with a tiled glyph grid. Closing that gap means
  changing palette and type token values — an owner decision.
- **Content the site cannot show because it does not have it:** 13 of 14 apps
  have no screenshots (only MiNextStep); 6 have no line saying what the work was
  (Malboos, Tekrar, Wasset, Snunu, Mostaqbaly, AZ Exams); 2 carry a metric; no
  app has a case-study body (problem, role, approach, outcome). The Courtyard's
  "Something else — a second game is coming" card announces nothing.
- The "Worked with clients and companies in" label leaves "in" alone on a
  second line at 360px. Cosmetic; left.
- An `exception: Exception` was logged once during a phone scroll capture
  earlier in the audit and did not reproduce in any later capture. Cause
  unknown; not guessed at.
- `.agents/`, `.claude/`, `skills-lock.json` untracked (see Decisions).

## Next

Get the owner's answer on the design direction. Every remaining "make it much
better" change — palette, display type, the hero composition, how the papyrus
reads — hangs on it, and none of it can be done without changing token values.

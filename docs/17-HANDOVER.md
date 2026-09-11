# 17. Handover

> Historical handover from Claude. The independent [audit](18-REINNOVATION-AUDIT.md) has now inspected code, source conversations, the four owner-annotated screenshots and live browser views. Use [Re-innovation milestones](19-REINNOVATION-ROADMAP.md) for next work. Do not repeat the logo permission question: the original owner request is explicit. Manual jump, navigation arrangement and HTML rendering were asked in the audit and remain pending unless a later owner answer is recorded.

**For the agent picking this up. Read this before touching anything.**

## The owner is not satisfied with the work so far

Take that as the starting position, not as something to argue with. His words,
across several rounds: *"90% of the changes arent done at all"*, *"still many
other stuff not fixed so review the old requests and some are done poorly
still"*, *"the game is so confusing"*, *"the design now in all pages i give it
6.5/10 in the best case"*.

He is right about the volume. He gave roughly sixty items on 2026-09-09 and a
further fifteen on 2026-09-11. Around twenty shipped. The rest did not.

Three specific charges, all fair:

**The game does not bounce.** He says the dynamics are wrong. Note the history
before you change it, because it matters: the climb originally auto-bounced on
every landing, he asked for that removed and replaced with a spacebar jump, and
that is what shipped. He is now unhappy with the result. The most likely
reading is that he wanted the *press* to be his and the *feel* to stay springy,
and what he got is a climber that lands dead and sits there. **Ask him before
you rebuild it.** Reverting to auto-bounce without asking will break the thing
he explicitly requested; leaving it as is ignores what he is telling you now.
A middle path exists and was never tried: keep space as the jump, add a short
coyote window, a held-jump variable height, and a small automatic hop on
landing so the climber is never inert.

**The logos are invented.** The App Store and Google Play marks in
`lib/features/work/presentation/widgets/store_links.dart` are hand-drawn
geometric approximations, not the real badges. That was a licensing call made
without asking him, and he has since said plainly that he wants real marks even
where they are trademarked, and that he considers drawn substitutes worse than
nothing. The same applies to the Manchester United crest, which is currently a
declared-but-absent asset path. **His site, his risk, his call.** Replace the
drawn marks with the real ones, or ask him which he wants; do not re-litigate
it.

**Things he asked for are missing.** The list is below. It is long.

---

## What is actually done

Verify rather than trust this. `docs/16-REDESIGN-BACKLOG.md` is **stale**: it
was written as a plan and not maintained as items shipped, so its strike-through
marks are wrong. Fixing it is part of the job.

| Area | State |
|---|---|
| Routes renamed | `station` → `home` at `/`, `signal` → `journey` at `/journey`, through the enum |
| Hero | Opens on a greeting carrying the name; rule removed; stats corrected; seven country flags |
| Name audio | His own recording, trimmed and normalised, in `assets/audio/name.m4a` |
| Em dashes | Gone from tab titles and date ranges, with a test that fails on any in content or ARB |
| Article cards | Title, radius and a read affordance. They had **no title at all** before |
| Journey | Stack chips removed; app names link to `/work/<id>`; arrows aligned; map fills width until a stop is picked |
| `/work/<id>` | Real page built from `apps.json` instead of "not written yet" |
| Work cards | Category badge on the artwork; store buttons; "No public store listing" removed |
| Phone sheets | Top corners only, `surface` fill |
| Theme toggle | A brazier that lights and is put out |
| Off duty scenes | Book, controller, television, boot-into-net, padel serve |
| Favourites | FIFA, Valorant, Better Call Saul, The Alchemist, Animal Farm, Man Utd |
| Game | Space to jump, wall kick worth 34 per cent more height, rising floor, levels, compact chrome |
| Brief | Two columns, repeated job titles collapsed |
| Cloudflare | Deployed and live, including the admin panel at `/admin` |
| Papyrus map | Applied, in `propagation_map.dart` |

---

## What is not done

### The admin panel, which is the largest gap

`worker/src/admin.js` is 662 lines and edits five content files as fixed forms.
Everything below is missing.

| # | Item | Where |
|---|---|---|
| A1 | It looks basic. He wants it to look like a professional tool. Desktop-first is explicitly fine | `worker/src/admin.js` |
| A4 | Change the admin password from inside the panel | `admin.js`, `index.js` |
| A5 | **Arbitrary fields.** Contacts become "links": add a row, name it, paste a URL. No fixed names or order. Same pattern everywhere else | `admin.js`, `lib/content/models/profile.dart` |
| A6 | Arabic and English as two stacked tabs, not a pair of boxes | `admin.js` |
| A7 | **Live preview pane** on the right showing the part of the site the current edit changes | `admin.js` |
| A8 | Themes beyond light and dark, which stay and cannot be removed. Christmas, tech, Batman. Plus per-page background pattern control | `admin.js`, `lib/app/theme/tokens.dart`, `theme_controller.dart` |
| A9 | Font choice per language or for both, default preserved | `admin.js`, `lib/app/theme/typography.dart` |
| A10 | **Analytics home**: views by week, month, custom range; unique visitors; clicks by target; audience. The Worker already counts all of this | `admin.js`, `worker/src/index.js` (`aggregateSnapshot`) |
| A11 | Social links for the fun section, with an icon set matched by domain and a changeable default | `admin.js`, new content file |
| A13 | Drop the "Nocturne" name from the panel. He wants "Sherbini's Portfolio" or similar | `admin.js` |
| A14 | Per-page save buttons, and a confirm dialog listing exactly what changed | `admin.js` |
| A15 | Cards are compact with dead space. Grid, or collapsed until opened | `admin.js` |

Subscribers and the daily digest were **cancelled** by him on 2026-09-09. Do not
build them.

### The site

| # | Item | Where |
|---|---|---|
| B9 | The wall ornament reads as random and artificial. He wants organic Egyptian imagery: animals, figures, pharaohs | `lib/core/painting/ornament_paths.dart`, `wall_painter.dart` |
| B10 | On desktop the wall runs a long line across the screen. Narrow it | `wall_painter.dart` |
| B11 | A 1997 stop for being born, with the photograph in `supporting files/profile/baby` | `assets/content/career.json`, `assets/media/` |
| B12 | Every journey stop editable from the panel | `admin.js` |
| B22 | One consistent interesting fact per app, not a mixture of shapes | `assets/content/apps.json` |
| B23 | Media per app from the panel, one marked as the feature image | `admin.js`, `app_detail.dart`, `work_card.dart` |
| B25 | **Writing moves in with Work as a separate tab.** Still its own nav destination | `app_nav.dart`, `work_screen.dart`, `writing_screen.dart` |
| B28 | About needs a redesign, education worst of all. More animated, more interactive | `lib/features/about/presentation/` |
| B29 | About's right-hand side is empty; contacts look unclickable; no route through to Medium | `about_screen.dart`, `contact_links.dart` |
| B32 | Consider merging the game and Off duty into About | architectural, ask him |
| B34 | Off duty cards clickable where they have content, with a hint when they do | `interests_grid.dart` |
| B37 | The intro is still not convincing. He wants real rendered figures, and the caption gone unless it earns its place | `web/intro/intro.js`, `web/index.html` |
| B38 | On a phone the intro scene is far too close | `web/intro/intro.js` (camera) |
| C1 | **Nothing has been tested on a real device.** No Android, no iOS, no real browser | — |

### Raised on 2026-09-11 and not yet done

- The game needs **progressive difficulty beyond the floor speed**: he wants the
  later levels to feel different, not just faster.
- He wants **a prize or reward shown** on a wall kick. There is a ring flourish;
  there is no reward.
- **Real store badges and the real club crest** (see above).

---

## How to work on this

**Render it and look at it.** Every significant defect in this codebase was
found by drawing the thing to a PNG and opening it, and none were found by
reading code or running tests. The article card had no title for weeks with a
full test suite passing. Write a throwaway test that paints to a file, look at
it, then delete it.

**Tests here assert spellings, not rules.** Repeatedly: section names, the shown
name, a stat value, interest ids, all written as literals, so renaming anything
failed tests that were not about the rename. Several are now bound to the
content. Assume the rest are not, and when one fails ask whether it is testing a
rule or a string.

**The owner's content is his.** `AGENTS.md` §3 forbids inventing facts about
him, and he has called it out when it happened. If you need a favourite, a date
or a number, ask.

**`supporting files/` is git-ignored and must never be committed.** It holds his
CV with a phone number, university coursework and personal photographs.
Individual assets may be copied into `assets/` with his permission.

**Branch and PR.** `AGENTS.md` §7. Main is protected by `verify` and `goldens`,
and `verify` runs `flutter analyze --fatal-infos` over the **whole project**,
not just `lib`, plus an 80 per cent coverage gate.

**The environment is slow.** A suite that ran in 40 seconds has taken 80 minutes
in the same session. Run things in the background and be patient rather than
assuming a hang.

---

## Files you will touch most

```
worker/src/admin.js                     the panel; the biggest single job
worker/src/index.js                     endpoints, auth, analytics aggregates
lib/core/painting/ornament_paths.dart   the wall ornament he dislikes
lib/core/painting/wall_painter.dart     its width and placement
lib/features/about/presentation/        the redesign he asked for twice
lib/features/courtyard/game/            the climb: domain/ascent_world.dart is the whole game
lib/core/painting/ascent_painter.dart   everything the game draws
web/intro/intro.js                      the threshold; still not convincing
assets/content/*.json                   his content; never invent
docs/16-REDESIGN-BACKLOG.md             stale; fix it as you go
```

## The first thing to do

Not code. Ask him, in one message, these four questions, because every one of
them changes what you build and getting them wrong wastes a day:

1. **The game.** Space to jump stays, or does auto-bounce come back? He asked
   for one and then complained about the result.
2. **Logos.** Real Apple, Google Play and Manchester United marks shipped in the
   repository, accepting they are trademarks?
3. **Merging.** Writing into Work, and the game and Off duty into About: both
   are his suggestions phrased as questions.
4. **The admin panel.** Which of the twelve missing pieces first? The live
   preview and arbitrary fields are the two he described in most detail.

Then do the admin panel. It is the largest gap, he has raised it in every
message, and several site items are blocked behind it.

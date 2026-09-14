# 2026-09-15-01 — A services page, real marks, and a page that magnifies

**Agent:** Claude / Opus 5
**Milestone:** Re-innovation, full ownership
**Started from:** `d5ef1b7`

## Goal

Fourteen numbered items from the owner, sent with a screenshot of the zoom
breaking. All of them, with no waiting for assets.

## What changed

### Services, and one tab for everything made

`/services` is new and `/writing` has folded into `/work`. The site could say
what had shipped and where it happened, and had no answer at all to "can you
build me one?" — the one question a freelance visitor arrives with. Work and
Writing were also two tabs asking a stranger to choose between them before
knowing what either held; they are both things he has made, so they are one
page now. `/writing` still resolves, because links already exist in the world.

The offer itself — mobile apps, web apps, admin dashboards, UI/UX, AI
automations, WhatsApp and Telegram chatbots, Power BI dashboards — lives in
`profile.json` beside the skills and the tools, so it is the owner's to change
without a code change. Each card is matched to a mark by its own words, and
anything unrecognised still gets a card.

Home carries one line through to it, at the end of the career: everything above
that point is what has already happened.

### The platforms' own marks

App Store, Google Play and pub.dev were **drawn by hand** — an apple with a
bite out of it, a play triangle, a box. They come from Simple Icons now, which
is assembled from the vendors' brand pages, and the contact cards carry their
platforms' marks for the same reason. Two exceptions, stated rather than
fudged: LinkedIn and the Adobe tools have no mark in the set because those
companies had them withdrawn, so LinkedIn shows a neutral link glyph and the
Adobe skills are words. Redrawing a trademark by hand is what caused the
problem the first time.

### Contact, in two halves

Ways to message him first — email, WhatsApp, and the booking link when there is
one — then **Social links** under their own label. Eight identical cards in one
row buried the important one third from the left. The heading is "Contact me".

### The credit

Off the site entirely, into the README, where the licence is honoured in the
document that actually describes the work. CC BY-SA asks that attribution be
given, not that it be given on the page.

### The intro

The name is gone from the door and a button is there instead. The site says who
he is on its own front page; saying it twice before the page had loaded was a
title card for nobody. It still opens by itself for somebody who does nothing.

### The page magnifies again

The previous fix let the browser zoom and the layout came apart, which is what
the owner photographed. A pinch changes the *visual* viewport, not the layout
one — on an ordinary page that is a magnifier. Flutter subscribes to
`visualViewport` and resized its canvas to match, so a pinch was relaying the
site out underneath the magnifying glass and leaving black margins. It no
longer gets those events, so the canvas stays at the layout viewport's size and
the browser scales the pixels, which is what every other site does.

### The rest

- **About**: the portrait is lit rather than boxed, and the column that ran out
  of content half way down ends in two buttons — the work, and the offer.
- **Home**: the three "Skills: a, b, c" lines are chips and a way through to
  About rather than the same inventory printed twice; the stops are cards
  across the page instead of a thin column; the flags are discs that name their
  country on hover; a way back to the top appears once there is a way back up
  to want.
- **The moving card** names the country: "Doha, Qatar", not "Doha, QA". So do
  the career entries.
- **The header**: Brief is a sheet of paper rather than a word, every control
  says what it does on hover, and the mark leaves the brief as well as going
  home — a viewer who has switched it on and wants the site reaches for the
  logo.
- **The climb**: space starts the next run when one is over, and the button has
  room to breathe.
- **The papyrus**: the sound is deleted — it never sounded like paper — and the
  sheet rolls under the pointer and unrolls when it leaves. There is nothing to
  click and nothing to click back.

## Files touched

Thirty-odd. The new ones: `lib/features/services/presentation/services_screen.dart`,
`lib/content/country_names.dart`,
`lib/features/station/presentation/widgets/back_to_top.dart`.

## Decisions made

**Nothing was drawn that belongs to somebody else.** Where a brand's mark is
not available under terms, its name is written out instead.

**Services are content, not code.** The same rule the skills follow.

**The country names are the countries' own.** No claim about the owner is being
made by either column, which is why adding them is not the invented translation
the brief rules out.

## Tests

- Full suite: **704 tests, all passing**, after regenerating the goldens.
- The route test, the sitemap and the burst-label test were extended rather
  than relaxed: a new route that nothing renders, or a card that goes back to
  printing "QA", now fails.

## Verification run

```
fvm dart format --set-exit-if-changed .   pass, 297 files, 0 changed
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 704 tests
fvm flutter build web --wasm               pass
```

Browser checks at 1440x900: Home, the stops, the foot of Home, Services, About
and Work.

## Known issues left open

- **No Calendly and no TikTok in content.** Both are wired and both are hidden
  until the owner supplies them: the booking button appears the moment
  `contact.calendly` is set, and TikTok the moment `contact.tiktok` is. Neither
  was guessed.
- **The pinch fix is reasoned, not measured.** A headless browser cannot
  perform a trackpad pinch, so this one needs the owner's hands on his own
  machine.
- **The services page shows no samples of each kind of work.** The owner asked
  whether it needed them and I have not added them; the work is one page away.
- Project default images, the leaderboard, the preview adapter, HTML
  publication parity and A5 remain untouched.

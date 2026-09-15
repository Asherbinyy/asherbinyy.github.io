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

### The page magnifies again — third attempt, and this one is measured

Two wrong fixes preceded this. Letting the browser zoom was not enough, and
muting Flutter's `visualViewport` resize *event* was not either, because the
read is not event-driven:
`FullPageDimensionsProvider.computePhysicalSize()` reads
`visualViewport.width/height` **every time it is called**, on any frame. A
pinch therefore shrank the canvas to the magnified region on the next frame
and relaid the site out underneath the magnifying glass.

The same method falls back to `window.innerWidth/innerHeight` when there is no
visual viewport, and those are the *layout* viewport: unchanged by a pinch, and
correctly updated by a real browser zoom, which should relayout. So the
property is shadowed to `undefined` before the bootstrap runs and Flutter takes
the fallback.

Measured this time. `Emulation.setPageScaleFactor` is exactly the state a
trackpad pinch produces, and the driver now exposes the raw protocol so a test
can set it:

| | view size at 1x | at 2x |
|---|---|---|
| live site, before | 1440x900 | **720x450** |
| after | 1440x900 | 1440x900 |

720x450 is the black margin in the owner's screenshot, reproduced exactly.
What this gives up is the on-screen-keyboard inset on mobile, computed from the
same object; this site has no text input for a keyboard to cover.

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

### The links, from his own page

The owner said the socials were in his Linktree, so they were read from it
rather than asked for again: Calendly, TikTok, Instagram, Facebook, Fiverr and
the WhatsApp link he actually publishes. The Facebook URL was normalised — his
Linktree carries a `viewas` parameter that only works for him — and nothing was
guessed from a username.

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

- **The WhatsApp number is not the phone number.** The content's phone is his
  UK one; the WhatsApp link he publishes is Egyptian. The derived link would
  have sent people to a number he does not answer there, so `contact.whatsapp`
  is given explicitly and the derivation is only a fallback now. Worth his
  confirming which he wants.
- **The services page shows no samples of each kind of work.** The owner asked
  whether it needed them and I have not added them; the work is one page away.
- Project default images, the leaderboard, the preview adapter, HTML
  publication parity and A5 remain untouched.

# 16. Redesign backlog

> **This file was written as a plan and went stale while work shipped.** It has
> been reconciled once, on 2026-09-11. If you are picking this up, read
> `17-HANDOVER.md` first: it states what is actually true and what the owner
> thinks of it. Keep this table current as you go, because the last agent did
> not and it cost a reconstruction.

Everything the owner asked for on 2026-09-09, itemised so none of it is lost
between sessions. Roughly sixty items. Ordered by area, not by priority; the
`Ship` column is the batch each one goes out in.

Nothing here is a decision I made. Where I have had to interpret, the
interpretation is written down so he can correct it.

## Answers to the questions he asked directly

**Is the admin panel free?** Yes, and it will stay free at his volume.
Cloudflare Workers' free plan allows 100,000 requests a day and KV allows
100,000 reads, 1,000 writes, 1,000 deletes and 1GB of storage a day. A
portfolio serves a handful of publishes a week. Nothing here needs a card on
file, which is the same reason R2 was rejected in `15-ADMIN-AND-MEDIA.md` §2.

**Can he change the password?** Yes, and he should be able to do it without
me. Two ways, and §A4 below adds the second:

1. `npx wrangler secret put ADMIN_TOKEN`, then paste a new value. Takes effect
   on the next request; no deploy, no code change.
2. From the panel itself, once §A4 ships.

Rotating it also revokes the old one, because there is only ever one.

**Are the Medium articles a listener or manual?** A listener. The Worker
fetches `https://sherbini.medium.com/feed` and relays it, so articles appear
on their own and there is nothing to add by hand. Per his instruction, the
admin panel gets no article editor. **But the cards were not drawing the
title** at all, which is why they looked empty. Fixed.

---

## A. The admin panel

| # | Item | Ship |
|---|---|---|
| A1 | Professional visual design. Desktop-first is explicitly fine. | 2 |
| ~~A2~~ | **Done.** Answered above. <br>_Was:_ Free hosting: answered above, and recorded in the README. | shipped |
| ~~A3~~ | **Done.** `README.md`, covering the panel's address, the free tier, and how to rotate the password. <br>_Was:_ README section covering what the panel is and how to reach it. | shipped |
| A4 | Change the password from inside the panel. | 3 |
| A5 | **Arbitrary fields.** Contacts become "links": add a row, name it, paste a URL. No fixed order, no fixed names. Same everywhere else. | 2 |
| A6 | Arabic and English as two stacked tabs, better looking than the current pair of boxes. | 2 |
| A7 | **Live preview** on the right, showing the part of the site the current edit changes. | 3 |
| A8 | Themes beyond light and dark. Those two are fixed and cannot be removed; others can be added (Christmas, tech, Batman). Plus per-page background pattern control. | 4 |
| A9 | Font choice per language or for both, default preserved. | 4 |
| A10 | **Analytics home**: views by week, month and custom range; unique visitors; clicks by target; audience. | 5 |
| A11 | Social links for the fun section, with an icon set matched by domain and a changeable default. | 2 |
| A12 | Every admin page reflects the app changes below. | ongoing |
| A13 | Drop the "Nocturne" name from the panel. | 1 |
| A14 | Per-page save buttons, and a confirm dialog listing what changed. | 2 |
| A15 | Cards are compact with dead space: grid, or collapsed until opened. | 2 |

## B. The site

### Home, currently "Station"

| # | Item | Ship |
|---|---|---|
| ~~B1~~ | **Done.** Renamed through the enum: `/` and `/journey`. <br>_Was:_ Rename. "Station" means nothing to a visitor. | shipped |
| ~~B2~~ | **Done.** Reads "Hear how it is said". <br>_Was:_ "Hear my name" does not read as a call to action. | shipped |
| ~~B3~~ | **Done.** Gone, with a test so it is not restored by accident. <br>_Was:_ Remove the rule under the name. | shipped |
| ~~B4~~ | **Done.** Opens on a greeting that carries the name; the separate name line is gone. <br>_Was:_ Keep the full name for consistency, give it a carved treatment, and do not open on it. Open on something with a voice: "Hiya, this is Ahmed", without being cringe. | shipped |
| ~~B5~~ | **Done.** Replaced. <br>_Was:_ Replace "I build mobile products end to end" with something that is not a job description. | shipped |
| ~~B6~~ | **Done.** Corrected, and seven flags added. <br>_Was:_ Stat cards: "5+ years commercial experience", "MSc in IT". Add the countries worked with, including the UK, with flags. | shipped |
| B7 | Stat cards and the countries line editable from the panel, including adding new ones. | 2 |
| ~~B8~~ | **Done.** The panel carries the applications now, not a repeat of the copy. <br>_Was:_ The floating stop label overlaps the wall, and repeats the copy already on the left. Make it carry something else: the apps, or a vertical timeline with flag, place and dates on the right against company and role on the left. | shipped |
| B9 | The wall ornament reads as random and artificial. He wants organic Egyptian imagery: animals, figures. | 3 |
| B10 | On desktop the wall runs a long line across the screen. Narrow it. | 1 |

### The journey, currently "Signal"

| # | Item | Ship |
|---|---|---|
| B11 | Rename. Add a 1997 stop for being born, with the photograph in `supporting files/profile/baby`. | 1 |
| B12 | Every stop editable from the panel. | 2 |
| ~~B13~~ | **Done.** Applied in `propagation_map.dart`. <br>_Was:_ Keep the map. Apply the papyrus treatment it was promised. | shipped |
| ~~B14~~ | **Done.** Removed. <br>_Was:_ Remove the stack chips. | shipped |
| ~~B15~~ | **Done.** App names link to `/work/<id>`, which is now a real page. <br>_Was:_ "4 applications" becomes the app names, each linking to `/work/<id>`, a real page with media, samples and store links. | shipped |
| ~~B16~~ | **Done.** The rail is the line; years are their own row. <br>_Was:_ The timeline arrows sit below the line. | shipped |
| ~~B17~~ | **Done.** Lightened. <br>_Was:_ The map's brown marker is too heavy. | shipped |
| ~~B18~~ | **Done.** The map fills the width until a stop is chosen. <br>_Was:_ The map fills the width until a stop is chosen, then shrinks. | shipped |
| ~~B19~~ | **Done.** Top corners only, `surface` fill. <br>_Was:_ On a phone the stop sheet is inconsistent and the wrong colour. Make it a proper iOS sheet. | shipped |

### Work

| # | Item | Ship |
|---|---|---|
| ~~B20~~ | **Done.** Replaced. <br>_Was:_ The heading copy is overdramatic. | shipped |
| ~~B21~~ | **Done.** Store buttons in, "No public store listing" out. **The marks are drawn, which he has since rejected.** <br>_Was:_ Store icons instead of words. Drop "No public store listing" entirely. | shipped |
| B22 | One consistent interesting fact per app, not a mixture of shapes. | 2 |
| B23 | Media per app from the panel, one marked as the feature image. | 3 |
| ~~B24~~ | **Done.** Badge on the artwork. <br>_Was:_ Category overlay on the feature image. | shipped |
| B25 | Writing lives with Work as a separate tab rather than its own section. | 2 |
| ~~B26~~ | **Done.** Title, radius and a read affordance. <br>_Was:_ **Done.** Article cards had no title at all: the headline existed only in the screen-reader label. Title, radius and a "Read on Medium" affordance added. | shipped |

### About

| # | Item | Ship |
|---|---|---|
| ~~B27~~ | **Done.** About has its own paragraph. <br>_Was:_ The blurb repeats the home page word for word. Make it personal: what he enjoys, free time, learning, AI automation. | shipped |
| B28 | Redesign, education worst of all. More animated, more interactive. | 3 |
| B29 | Right-hand side is empty; contacts are unclickable-looking; no way through to Medium. | 2 |

### Courtyard

| # | Item | Ship |
|---|---|---|
| ~~B30~~ | **Done.** Replaced. <br>_Was:_ Replace the tomb-walls line. | shipped |
| B31 | **Reworked.** Landing settles and space jumps, on both keyboard and a wide touch bar; up, down and dive are gone. A wall kick is worth a third more height than a standing jump and leaves a mark. The floor rises, faster every sixty metres, and standing still past the opening level ends the run. The chrome is three glyphs instead of three labelled buttons across the playfield. **Still open:** the shaft's own look at higher levels. |
| B32 | Consider merging the game and Off duty into About. | 4 |
| ~~B33~~ | **Done.** Reading is a book, Gaming is a controller with a d-pad, four face buttons and two thumbsticks, Television is a screen. Football is a boot into a net that shakes, with the shout. Padel is two players and a serve. Favourites are in the content: FIFA and Valorant, Better Call Saul, The Alchemist and Animal Farm, Manchester United. |
| B34 | Off duty cards clickable, but only where they have content, with a hint when they do. | 3 |
| ~~B35~~ | **Done.** The theme control is a brazier. **The Brief control is untouched.** <br>_Was:_ The theme toggle and the Brief control should be a moment, not a switch. A goblet lighting and being put out. | shipped |
| ~~B36~~ | **Done.** Two columns, repeated titles collapsed, name fixed. <br>_Was:_ Brief: plain, repetitive headings, wrong name, empty right side. | shipped |

### The threshold

| # | Item | Ship |
|---|---|---|
| B37 | Still not convincing. Real rendered figures. The caption goes unless it earns its place. | 4 |
| B38 | On a phone the scene is far too close. | 1 |

## C. Verification

| # | Item | Ship |
|---|---|---|
| C1 | Run on real devices: Android, iOS, desktop browsers. | last |

---

## What I would add

**The stat numbers need a source.** `14-PROVENANCE.md` exists because he
objected to invented figures. "5+ years commercial experience" is checkable
against the career file and should be computed from it rather than typed, so
it cannot go stale.

**Subscribers are cancelled.** The bell, the mailing list and the daily digest
were dropped by the owner on 2026-09-09, once it was clear sending mail is the
only part of this that costs anything: every free tier wants a verified domain
or caps hard. The analytics dashboard survives, because counting visits needs
no mail at all.

Worth knowing if it ever comes back: the Worker already has a noon digest that
posts to `DIGEST_WEBHOOK_URL`. Pointing that at anything that forwards to email
would give him the daily summary with no new dependency and no new cost.

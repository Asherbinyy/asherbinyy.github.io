# 16. Redesign backlog

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
| A2 | Free hosting: answered above, and recorded in the README. | 1 |
| A3 | README section covering what the panel is and how to reach it. | 1 |
| A4 | Change the password from inside the panel. | 3 |
| A5 | **Arbitrary fields.** Contacts become "links": add a row, name it, paste a URL. No fixed order, no fixed names. Same everywhere else. | 2 |
| A6 | Arabic and English as two stacked tabs, better looking than the current pair of boxes. | 2 |
| A7 | **Live preview** on the right, showing the part of the site the current edit changes. | 3 |
| A8 | Themes beyond light and dark. Those two are fixed and cannot be removed; others can be added (Christmas, tech, Batman). Plus per-page background pattern control. | 4 |
| A9 | Font choice per language or for both, default preserved. | 4 |
| A10 | **Analytics home**: views by week, month and custom range; unique visitors; clicks by target; audience. Subscriber capture with optional name. A daily 12:00 digest by email with a link back. | 5 |
| A11 | Social links for the fun section, with an icon set matched by domain and a changeable default. | 2 |
| A12 | Every admin page reflects the app changes below. | ongoing |
| A13 | Drop the "Nocturne" name from the panel. | 1 |
| A14 | Per-page save buttons, and a confirm dialog listing what changed. | 2 |
| A15 | Cards are compact with dead space: grid, or collapsed until opened. | 2 |

## B. The site

### Home, currently "Station"

| # | Item | Ship |
|---|---|---|
| B1 | Rename. "Station" means nothing to a visitor. | 1 |
| B2 | "Hear my name" does not read as a call to action. | 1 |
| B3 | Remove the rule under the name. | 1 |
| B4 | Keep the full name for consistency, give it a carved treatment, and do not open on it. Open on something with a voice: "Hiya, this is Ahmed", without being cringe. | 1 |
| B5 | Replace "I build mobile products end to end" with something that is not a job description. | 1 |
| B6 | Stat cards: "5+ years commercial experience", "MSc in IT". Add the countries worked with, including the UK, with flags. | 1 |
| B7 | Stat cards and the countries line editable from the panel, including adding new ones. | 2 |
| B8 | The floating stop label overlaps the wall, and repeats the copy already on the left. Make it carry something else: the apps, or a vertical timeline with flag, place and dates on the right against company and role on the left. | 1 |
| B9 | The wall ornament reads as random and artificial. He wants organic Egyptian imagery: animals, figures. | 3 |
| B10 | On desktop the wall runs a long line across the screen. Narrow it. | 1 |

### The journey, currently "Signal"

| # | Item | Ship |
|---|---|---|
| B11 | Rename. Add a 1997 stop for being born, with the photograph in `supporting files/profile/baby`. | 1 |
| B12 | Every stop editable from the panel. | 2 |
| B13 | Keep the map. Apply the papyrus treatment it was promised. | 3 |
| B14 | Remove the stack chips. | 1 |
| B15 | "4 applications" becomes the app names, each linking to `/work/<id>`, a real page with media, samples and store links. | 3 |
| B16 | The timeline arrows sit below the line. | 1 |
| B17 | The map's brown marker is too heavy. | 1 |
| B18 | The map fills the width until a stop is chosen, then shrinks. | 1 |
| B19 | On a phone the stop sheet is inconsistent and the wrong colour. Make it a proper iOS sheet. | 1 |

### Work

| # | Item | Ship |
|---|---|---|
| B20 | The heading copy is overdramatic. | 1 |
| B21 | Store icons instead of words. Drop "No public store listing" entirely. | 1 |
| B22 | One consistent interesting fact per app, not a mixture of shapes. | 2 |
| B23 | Media per app from the panel, one marked as the feature image. | 3 |
| B24 | Category overlay on the feature image. | 2 |
| B25 | Writing lives with Work as a separate tab rather than its own section. | 2 |
| B26 | **Done.** Article cards had no title at all: the headline existed only in the screen-reader label. Title, radius and a "Read on Medium" affordance added. | 0 |

### About

| # | Item | Ship |
|---|---|---|
| B27 | The blurb repeats the home page word for word. Make it personal: what he enjoys, free time, learning, AI automation. | 1 |
| B28 | Redesign, education worst of all. More animated, more interactive. | 3 |
| B29 | Right-hand side is empty; contacts are unclickable-looking; no way through to Medium. | 2 |

### Courtyard

| # | Item | Ship |
|---|---|---|
| B30 | Replace the tomb-walls line. | 1 |
| B31 | The game still is not good enough. | 3 |
| B32 | Consider merging the game and Off duty into About. | 4 |
| B33 | Reading does not look like a book. Swap padel and e-sports. E-sports becomes Gaming with a moving joystick and favourite games. Television is still wrong. | 2 |
| B34 | Off duty cards clickable, but only where they have content, with a hint when they do. | 3 |
| B35 | The theme toggle and the Brief control should be a moment, not a switch. A goblet lighting and being put out. | 2 |
| B36 | Brief: plain, repetitive headings, wrong name, empty right side. | 1 |

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

**Subscriber email is the one item with a real cost.** Everything else here is
free. Sending mail needs a provider, and the free tiers all want a verified
domain or cap hard. That decision is his and it is listed in A10 rather than
assumed.

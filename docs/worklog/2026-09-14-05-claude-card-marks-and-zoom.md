# 2026-09-14-05 — The card in the middle, a sign per stop, and a page that zooms

**Agent:** Claude / Opus 5
**Milestone:** Re-innovation, full ownership
**Started from:** `fa31798`

## Goal

Three things the owner asked for on top of the wall work, and as much of the
standing backlog as could be finished without inventing anything.

## What changed

### The moving card

It had been pushed just clear of the stone, which left the middle of a wide
page empty with a card pressed against the wall. Its box is now exactly the
clear ground between the copy and the first block, so the card sits in the
middle of that ground.

It carries **one line: where the stop was**. The company, the dates and the
title are all printed by the career entry it is anchored to a few hundred
pixels away, and repeating them made the card a second copy of the entry rather
than a marker on it. Freelance says "Remote", which is what its entry says.

### A sign per kind of stop

Each career entry now carries a carved sign down its leading edge, and the
three kinds do not share one:

- **The seated scribe** for study. The determinative for a person, and the sign
  that goes with writing.
- **The djed pillar** for employment. Stability; a thing you stand inside.
- **The falcon** for freelance. It stands on its own.

Carved with the same shadow-below, lip-above pass the wall uses, so it belongs
to the same surface rather than looking like an icon dropped on the page. Not a
logo and not a stock glyph: an employer's actual mark is not ours to draw, and
a generic briefcase is the kind of filler the owner has asked to keep out.

### The page zooms again

A trackpad pinch on macOS, and ctrl with the wheel anywhere, arrive as a wheel
event carrying `ctrlKey`. Flutter's own listener calls `preventDefault` on
wheel events so it can own scrolling, and that cancels the browser's page zoom
— which is why this was the one site on the owner's machine that would not
pinch. The event is now caught on the way down and stopped before it reaches
the view, so the browser does what it does everywhere else. Ordinary scrolling
carries no `ctrlKey` and is untouched. The viewport meta also states
`user-scalable=yes` with a maximum of 5, so a phone can enlarge it too.

### Skills, tools, and groups that open

The three skills the owner named are in: project management, cybersecurity and
Power BI. So are the tools: Claude, Codex, Gemini, DeepSeek, Antigravity,
Android Studio, VS Code and Charles. Nothing was read off the CV — the PDF's
text is font-subset garbage and guessing at somebody's résumé is not something
to do quietly — so the list is exactly what he dictated.

Each group opens and closes on a click, height and opacity together, with its
count beside the heading and the site's own gold rule growing to mark the open
one rather than a borrowed chevron. Skills is open on arrival: a page whose
every group is shut shows a visitor nothing.

### Contact

Every destination is a card now, and a hovered card lights: the border goes
gold and the site's own gold is thrown softly behind it. **WhatsApp** is there,
derived from the phone number the content already publishes — the same number,
reached a different way, which is not the same as inventing a handle.

The whole block also sits at the foot of Home. Somebody who has read to the
bottom of the front page should not have to find About to send an email.

### The game

A mark every hundred metres: a cartouche thrown up over the shaft with the
distance in it, fading as it rises, and a struck-bar chord under it. Beating
the stored best now sounds different from falling short of it, and passing a
band has its own low strike instead of borrowing the collect sound.

Four new samples, all synthesised by `tool/audio/make_sounds.py`, which is in
the repository — so the set can be regenerated or extended without going
looking for a pack, and there is no licence to carry for any of them.

### The stickman, and the papyrus

The kicking figure's limbs were drawn at 1.7× the scene's ink, which gave it
the build of a snowman. They are just above the line weight now, and the head
is smaller. The papyrus sheets rustle when they roll: filtered noise with a
soft knock as the roll seats itself, from the same generator.

### The artwork credit

Gone from About, which is what the owner asked. It is not gone from the site,
because it cannot be: the guardian in the intro is a CC BY-SA work and
attribution is a condition of using it, not a decoration. It is one quiet line
in the footer now, which is where a colophon belongs.

## Files touched

- `lib/features/trace/presentation/trace_burst_label.dart` — modified — centred in the gap; one line.
- `lib/features/trace/presentation/station_trace.dart` — modified — the label is the location.
- `lib/features/trace/presentation/telemetry_trace.dart` — modified — computes the gap.
- `lib/features/station/presentation/widgets/stop_mark.dart` — added — the sign per kind.
- `lib/features/station/presentation/widgets/career_sequence.dart` — modified — the sign beside the entry.
- `lib/features/station/presentation/station_screen.dart` — modified — contact at the foot of Home.
- `lib/features/station/presentation/widgets/papyrus_stat_panel.dart` — modified — the rustle.
- `lib/features/about/presentation/widgets/skills_panel.dart` — modified — groups that open.
- `lib/features/about/presentation/widgets/contact_links.dart` — modified — glowing cards, WhatsApp.
- `lib/features/about/presentation/about_screen.dart` — modified — the credit leaves.
- `lib/app/chrome/app_footer.dart` — modified — the colophon arrives.
- `lib/features/courtyard/game/**` — modified — the hundred-metre mark and the new sounds.
- `lib/core/painting/football_scene.dart` — modified — a thinner figure.
- `web/index.html` — modified — the page zooms.
- `tool/audio/make_sounds.py` — added — four synthesised samples.
- `assets/content/profile.json` — modified — the dictated skills and tools.
- `test/widget/trace/trace_test.dart`, `test/unit/features/stop_mark_test.dart` — the card's position, and that the three kinds differ.

## Decisions made

**The card says one thing.** Anything else is already printed beside it.

**Nothing was guessed from the CV.** The PDF does not extract cleanly, and a
résumé is not a document to improvise from. Only what the owner dictated.

**WhatsApp is derived, TikTok is not.** A chat link built from a published
phone number is the same fact reached another way. A TikTok URL would be a
guess, so there is none.

**The colophon stays.** A licence condition is not a style preference.

## Tests

- The card is asserted to sit inside the gap and centred on it, measured
  against the wall's own edge.
- The three kinds of stop are asserted to produce three different signs — two
  sharing one is exactly the failure that would make the mark pointless.
- Full suite: **704 tests, all passing**, after regenerating the goldens.

## Verification run

```
fvm dart format --set-exit-if-changed .   pass, 294 files, 0 changed
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 704 tests
fvm flutter build web --wasm               pass
```

## Known issues left open

- **Work and Writing are still two tabs.** Merging them is a page-level change
  and the owner wants real store marks on it — App Store, Google Play, pub.dev.
  Those are trademarked artwork that has to be taken from the vendors' own
  brand pages under their terms; drawing lookalikes is exactly what the handoff
  forbids. Needs the marks, or a decision to use text.
- **No TikTok link.** No handle anywhere in the content.
- **Project default images** are not done.
- **The leaderboard**, the preview adapter, HTML publication parity and A5 are
  untouched in this pass.
- **Pinch on a touch screen** is still Flutter's `touch-action: none`. The
  wheel fix covers a trackpad and ctrl-wheel; relaxing touch-action would hand
  the browser gestures the game needs, so it was not done blind.

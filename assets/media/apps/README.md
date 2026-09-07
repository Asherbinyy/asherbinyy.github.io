# Application screenshots

Drop a screenshot in here and point one line of `apps.json` at it. Nothing
else is needed — no code change, no rebuild of anything but the site itself.

## How

1. Save the image here as `<app id>.jpg`, using the `id` from `apps.json`.
   For example `mokaf.jpg`, `az-courses.jpg`, `guardy.jpg`.
2. Add the path to that application's entry:

```json
{
  "id": "mokaf",
  "name": "Mokaf",
  "screenshot": "assets/media/apps/mokaf.jpg"
}
```

That is the whole procedure. The file name is a convention for tidiness; the
path in `apps.json` is what the site actually reads, so a differently-named
file works too as long as the two agree.

## What happens without one

The row draws its procedural station card — the deterministic constellation
seeded from the application's id. That is a designed treatment, not a
placeholder, so the ledger looks finished either way and there is no pressure
to supply screenshots you do not have.

A path pointing at a missing file falls back to the same card rather than
showing a broken image, so a typo degrades quietly instead of breaking a row.

## What to supply

- **Landscape**, roughly 16:10. The slot is wider than it is tall; a portrait phone screenshot will be cropped to its centre.
- **About 1200px wide.** Larger is wasted: the slot is a few hundred pixels on the widest breakpoint.
- **JPEG**, quality around 80. Keep each file under ~200KB — the whole ledger loads on one page, and `03-ARCHITECTURE.md` §5 sets the budget.
- **No device frames or marketing furniture.** The row supplies its own framing, and a screenshot wearing someone else's mockup fights it.

## What not to put here

Anything you do not have the right to publish. These ship in the repository and
on the live site. Client work under an agreement that covers screenshots is the
owner's call to make, and `14-PROVENANCE.md` §3.11 tracks it.

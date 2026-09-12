# HTML foundation browser evidence

Local Astro production build, 2026-09-12. Chrome with JavaScript disabled and reduced motion enabled; desktop 1440×900 and emulated phone 390×844. These are desktop Chrome captures, not physical iPhone/Android tests.

- `home-desktop.png`, `home-phone.png`, `home-ar-phone.png`: English/Arabic semantic Home, dark palette.
- `home-light-desktop.png`: the existing light palette.
- `work-desktop.png`: all projects link to their generated documents.
- `project-desktop.png`, `project-ar-light-phone.png`: actual project role, store destination and related career record, with dates isolated from RTL text.

The checked pages returned HTTP 200 with visible content and no reported horizontal overflow or runtime exceptions. A separate repeatable HTTP check passes 63 slashed/unslashed URL forms, three missing-page 404s and the release revision. The build verifies all 32 EN/AR documents, metadata, language alternates and internal links.

Screenshot review caught a black inherited SVG mark, its mobile selector hiding the mark, and an ambiguous RTL date range. Corrected and recaptured. Initial direct-response checks also caught unslashed URLs returning 404; the route configuration now accepts both forms.

This demonstrates readable public HTML and baseline responsive styling. Egyptian entrance art, final typography/composition, richer case-study media, cinematic motion and the real admin preview remain subsequent work. The production site has not changed.

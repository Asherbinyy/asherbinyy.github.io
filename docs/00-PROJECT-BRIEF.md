# Project brief — Ahmed Elsherbini's portfolio

Updated 2026-09-11 after the original conversation and browser audit.

## Purpose

Help people find Ahmed Elsherbini by name, understand his work and get to know him through an engaging Egyptian-inspired experience. Search visibility is the leading priority in the latest request. The visual ambition is an architectural world with convincing material, lighting, relief and movement.

The audiences remain recruiters, engineering leads, clients and collaborators. They must be able to read the work and contact the owner quickly, while visitors who explore encounter more personality and interaction.

## Current implementation

- Flutter 3.47.2 / Dart 3.13.2, web only, pinned by `.fvmrc`.
- GitHub Pages at `https://asherbinyy.github.io`.
- Public routes: `/`, `/journey`, `/work`, `/work/:slug`, `/writing`, `/about`, `/courtyard`.
- Static generated HTML at `/cv/` and `/brief/`; `/console` is reserved for the existing dashboard.
- Cloudflare Worker for published content overrides, media, Medium RSS/covers and `/admin`.
- Bundled JSON is the content fallback. The admin edits five documents; it is not yet the requested full editing workspace.
- Kemet and Deshret are the existing base themes; English and Arabic are implemented.
- The public release has no analytics endpoint. Do not enable collection as a side effect of rebuilding the admin.

The current product is not visually accepted. The [audit](18-REINNOVATION-AUDIT.md) documents the implementation and observed failures. Do not infer completion from old milestone titles.

## Direction

The owner wants realistic Egyptian architecture, figures, materials, sourced reliefs and cinematic transitions, with distinct compositions for each page. Old instructions restricting the site to flat instrumentation and five minimal ornaments do not define this new direction.

The content itself should be straightforward. Home introduces the person; Journey explains the path; Work demonstrates contributions; Writing presents published ideas; About reveals interests and selected research. Avoid repeating the same statistics, degree and job description on each page.

The game is for fun. It must not teach the CV or reward the player with career facts. The current request specifies an Egyptian humanoid with a gold headpiece, springy movement, rewards and better levels. Manual versus automatic jumping is being clarified; the latest explicit original control request was Space/tap.

The entrance should have convincing framing on phones and desktops and no bottom CC caption. It must leave readable content available if motion is reduced or the scene fails. Existing assets and their source records remain intact until replacements are selected.

## Search and content architecture

The current Flutter canvas and 404 fallback are insufficient as the public content/SEO strategy. Static CV/Brief pages do not cover the whole site, and admin updates can drift from generated HTML.

Recommended next step: semantic HTML public pages with optional interactive scenes, while reusing the existing content and Worker. This is a proposal awaiting the owner's rendering decision, not a migration already underway. R1 in the [new roadmap](19-REINNOVATION-ROADMAP.md) defines the alternative if Flutter is retained and the shared publication contract needed in either case.

SEO delivery includes valid page responses, readable HTML, route-specific metadata, accurate structured data, crawlable links, a current sitemap and Search Console verification. No ranking or universal appearance on every name search is promised.

## Admin

The target is a professional desktop editing workspace: flexible content and links, stacked language tabs, live preview, retained drafts, per-page review/publish, media galleries, name recording, password management, extra themes, font/background controls and an analytics home grounded in available data.

Two base themes remain available. Subscribers were cancelled. The separate daily digest is dormant and its requested status remains unclear from the handover versus the original cancellation; do not reactivate it without resolving that discrepancy.

## Delivery

Use [Re-innovation milestones R0–R9](19-REINNOVATION-ROADMAP.md), one at a time. Each has concrete behavior, files/areas, review artifacts and acceptance conditions. The old roadmap is history.

Preserve content provenance, accessible controls, reduced-motion support, EN/AR behavior and the pinned toolchain while it is retained. Changes to design tokens, route ownership, dependencies and collection must be documented and tied to the relevant agreed milestone. Do not publish to `main` during the audit.

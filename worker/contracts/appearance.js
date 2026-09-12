/**
 * A **proposal** for the appearance settings, not an implemented feature.
 *
 * Phase A5 asks for extra themes, font selection and per-page background
 * patterns. None of that can be delivered from this side alone: a setting the
 * public renderer does not read changes nothing, and a selector bound to a
 * setting nothing reads is a control that appears to work. The handoff is
 * explicit that unsupported options must not appear to work, so the panel has
 * no Appearance section and will not get one until there is something behind
 * it.
 *
 * What this file is for, per `20-APP-ADMIN-CONTRACT.md` under "Schema work
 * sequence": the proposed shape, written against identifiers that actually
 * exist, so Codex can say yes, no or "not that one" to something concrete.
 *
 * **This document is deliberately absent from `content-schema.js`.** Adding it
 * there would put it in the editor. `worker/test/appearance.test.js` asserts
 * that it stays out until a consumer exists.
 *
 * ---
 *
 * ## The identifiers here are the real ones, and one of them is a trap
 *
 * The design system calls the two palettes **Kemet** and **Deshret**. The code
 * calls them **`nocturne`** and **`daybreak`** -- those are the values in
 * `AppTheme.storageKey` in `lib/app/theme/app_theme.dart`, and they are what
 * is written to a viewer's storage today.
 *
 * A settings document that said `kemet` would be describing something no
 * `AppTheme.fromStorage` call can resolve; it would silently fall back to the
 * dark theme and look like it half worked. So the ids below are the storage
 * keys and the design names are carried alongside as labels. Renaming the enum
 * is a separate decision, and it would invalidate every viewer's stored
 * preference, so it should not be made casually.
 */

/// The two palettes that exist, keyed as the app keys them.
///
/// Both are permanent. R8 says the base themes cannot be deleted, so there is
/// no "remove" for either of these and no way for a setting to leave the site
/// without a theme.
export const themes = [
  {id: 'nocturne', label: 'Kemet', permanent: true, consumer: 'live'},
  {id: 'daybreak', label: 'Deshret', permanent: true, consumer: 'live'},
];

/// Families already bundled and subset, from `pubspec.yaml`.
///
/// Anything not on this list is a download, and a download is a decision about
/// weight, licensing and Arabic shaping rather than a dropdown entry.
export const fonts = [
  {id: 'space-grotesk', family: 'Space Grotesk', scripts: ['latin']},
  {id: 'ibm-plex-sans', family: 'IBM Plex Sans', scripts: ['latin']},
  {id: 'ibm-plex-mono', family: 'IBM Plex Mono', scripts: ['latin']},
  {id: 'ibm-plex-sans-arabic', family: 'IBM Plex Sans Arabic', scripts: ['arabic']},
];

/// The public routes a per-page setting could address.
///
/// From `AppRoute` in `lib/app/app_route.dart`, minus the ones that are not
/// pages a visitor browses: the case-study and campaign patterns take a
/// parameter, and the console is not public.
export const routes = [
  {id: 'home', path: '/'},
  {id: 'journey', path: '/journey'},
  {id: 'work', path: '/work'},
  {id: 'writing', path: '/writing'},
  {id: 'about', path: '/about'},
  {id: 'courtyard', path: '/courtyard'},
];

/// Background patterns, and the reason this list is empty.
///
/// `12-MOTIF-LIBRARY.md` documents sixteen motifs, but they are painters
/// chosen in Dart at their call sites, not a registry addressable by id.
/// Until Codex exposes ids the renderer will honour, there is nothing here
/// that could be selected, and inventing sixteen slugs from the document
/// headings would produce a list where selecting anything did nothing.
export const patterns = [];

/// The proposed document, in the same descriptor language as the content
/// schema, so it can be dropped in unchanged if the answer is yes.
export const appearanceProposal = {
  file: 'appearance.json',
  section: 'Appearance',
  blurb: 'Themes, fonts and page backgrounds.',
  warning: null,
  status: 'proposed',
  fields: [
    {
      key: 'theme',
      kind: 'object',
      label: 'Theme',
      fields: [
        {
          key: 'default',
          kind: 'choice',
          label: 'The theme a first-time visitor sees',
          required: true,
          options: themes.map((theme) => ({value: theme.id, label: theme.label})),
        },
        {
          key: 'allowViewerChoice',
          kind: 'boolean',
          label: 'Let visitors switch themes',
          help: 'The site has a toggle today. Turning this off would remove it.',
        },
      ],
    },
    {
      key: 'fonts',
      kind: 'object',
      label: 'Fonts',
      help: 'Only families already bundled with the app. Adding one is a decision about weight, licence and Arabic shaping, not a dropdown entry.',
      fields: [
        {
          key: 'latin',
          kind: 'choice',
          label: 'Latin text',
          options: fonts
            .filter((font) => font.scripts.includes('latin'))
            .map((font) => ({value: font.id, label: font.family})),
        },
        {
          key: 'arabic',
          kind: 'choice',
          label: 'Arabic text',
          options: fonts
            .filter((font) => font.scripts.includes('arabic'))
            .map((font) => ({value: font.id, label: font.family})),
        },
      ],
    },
    {
      key: 'pages',
      kind: 'list',
      label: 'Page backgrounds',
      addLabel: 'Set a page background',
      consumer: 'pending',
      help: 'Needs an allowlist of pattern identifiers the renderer honours. There is none yet, so this list can hold nothing.',
      of: {
        kind: 'object',
        titleFrom: 'route',
        subtitleFrom: 'pattern',
        fields: [
          {
            key: 'route',
            kind: 'choice',
            label: 'Page',
            required: true,
            unique: true,
            options: routes.map((route) => ({value: route.id, label: route.path})),
          },
          {
            key: 'pattern',
            kind: 'choice',
            label: 'Pattern',
            required: true,
            options: patterns,
          },
          {
            key: 'intensity',
            kind: 'number',
            label: 'How strongly it shows',
            min: 0,
            max: 1,
          },
        ],
      },
    },
  ],
};

/// What has to be true before any of this becomes a control the owner can use.
///
/// Written here rather than only in prose so a test can assert that none of it
/// has quietly been marked done.
export const blockedOn = [
  {
    id: 'theme-consumer',
    need: 'The app reads a published default theme instead of only a per-viewer preference.',
    owner: 'public app',
    satisfied: false,
  },
  {
    id: 'font-consumer',
    need: 'Typography resolves a published family per script, with Arabic shaping and fallback checked.',
    owner: 'public app',
    satisfied: false,
  },
  {
    id: 'pattern-registry',
    need: 'An exported allowlist of background pattern identifiers the renderer honours.',
    owner: 'public app',
    satisfied: false,
  },
  {
    id: 'extra-presets',
    need: 'Whether presets beyond the two palettes are wanted at all, and what a preset is allowed to change. Christmas, tech and Batman were the owner\'s examples, not approved asset packs.',
    owner: 'owner and public app',
    satisfied: false,
  },
];

/// Whether every blocker is cleared. False until Codex says otherwise.
export const appearanceReady = blockedOn.every((entry) => entry.satisfied);

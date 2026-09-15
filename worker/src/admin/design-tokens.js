/** CSS mirror of lib/app/theme/tokens.dart. Palette roles and type/space scales stay unchanged. */
export const designTokens = `
:root, [data-palette="dark"] {
  --void: #121826;
  --surface: #1A2233;
  --raised: #232D40;
  --line-soft: #2E3A50;
  --line: #3F4D66;
  --gold: #E3A93F;
  --feedback: #45B8B2;
  --alert: #E3716C;
  --text: #EDF1F8;
  --muted: #A8B4C6;
  --chart: #CBD6E6;
  --chart-secondary: #93A2B8;
}
[data-palette="light"] {
  --void: #F2E9D8;
  --surface: #E9DEC8;
  --raised: #FCF7EC;
  --line-soft: #D6C8AC;
  --line: #AD9C7C;
  --gold: #885912;
  --feedback: #1C6B68;
  --alert: #9C2E26;
  --text: #13181F;
  --muted: #48545F;
  --chart: #37424F;
  --chart-secondary: #586472;
}
:root {
  --s1: 4px; --s2: 8px; --s3: 12px; --s4: 16px; --s6: 24px; --s8: 32px; --s12: 48px; --s16: 64px;
  --control: 6px; --modal: 10px; --hairline: 1px; --focus: 2px;
  --body: 16px; --small: 14px; --meta: 13px; --heading: 22px; --display: 40px; --compact-display: 32px;
  --display-font: "Space Grotesk", sans-serif;
  --body-font: "IBM Plex Sans", "IBM Plex Sans Arabic", sans-serif;
  --mono-font: "IBM Plex Mono", monospace;
  --target: 48px; --sidebar: 240px; --preview: 360px;
  --ok: var(--text); color-scheme: dark;
}
[data-palette="light"] { color-scheme: light; }
`;

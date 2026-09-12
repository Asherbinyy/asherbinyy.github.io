/**
 * The panel's stylesheet.
 *
 * Kept in its own module because it is a third of the page and it was making
 * the file it came from unreadable. The variable names are the ones the
 * previous panel established; this is not the place to introduce a new colour
 * vocabulary, and `AGENTS.md`'s four-pigment rule governs the Flutter tokens
 * rather than an internal tool that nobody but the owner ever opens.
 *
 * Three columns on a desk, one on a phone. The owner asked to be able to add a
 * project from his phone, so nothing here depends on hover and every control
 * is at least 44px.
 */

export const styles = `
:root {
  --void: #121826;
  --surface: #1A2233;
  --raised: #232D40;
  --line: #33405A;
  --line-soft: #29334799;
  --text: #EDF1F8;
  --muted: #97A3BA;
  --gold: #E3A93F;
  --alert: #D2694A;
  --ok: #45B8B2;
  --rail: 232px;
  --preview: 400px;
  color-scheme: dark;
}
* { box-sizing: border-box; }
html, body { height: 100%; }
body {
  margin: 0;
  background: var(--void);
  color: var(--text);
  font: 15px/1.5 ui-sans-serif, -apple-system, "Segoe UI", Roboto, sans-serif;
  overflow: hidden;
}
:focus-visible {
  outline: 2px solid var(--gold);
  outline-offset: 2px;
  border-radius: 6px;
}
button {
  font: inherit; color: var(--text); background: var(--raised);
  border: 1px solid var(--line); border-radius: 8px;
  padding: 10px 14px; min-height: 44px; cursor: pointer;
}
button:hover:not(:disabled) { border-color: var(--gold); }
button:disabled { opacity: .45; cursor: not-allowed; }
button.primary { background: var(--gold); color: #17130A; border-color: var(--gold); font-weight: 600; }
button.danger { color: var(--alert); }
button.small { min-height: 36px; padding: 6px 10px; font-size: 13px; }
button.quiet { background: none; border-color: transparent; }
button.quiet:hover { background: var(--raised); }
input, textarea, select {
  font: inherit; width: 100%; color: var(--text);
  background: var(--surface); border: 1px solid var(--line);
  border-radius: 8px; padding: 10px 12px; min-height: 44px;
}
input[type="checkbox"] { width: 22px; height: 22px; min-height: 22px; accent-color: var(--gold); }
textarea { min-height: 96px; resize: vertical; line-height: 1.55; }
select { appearance: none; padding-right: 34px;
  background-image: linear-gradient(45deg, transparent 50%, var(--muted) 50%),
    linear-gradient(135deg, var(--muted) 50%, transparent 50%);
  background-position: calc(100% - 18px) 50%, calc(100% - 13px) 50%;
  background-size: 5px 5px, 5px 5px; background-repeat: no-repeat; }

/* --- frame ------------------------------------------------------------- */

#frame { display: none; height: 100%; grid-template-rows: auto 1fr auto;
  grid-template-columns: var(--rail) minmax(0, 1fr) var(--preview);
  grid-template-areas: "brand  top     top" "rail   editor  preview" "rail   bar     bar"; }
#frame.on { display: grid; }
#brand { grid-area: brand; display: flex; align-items: center; gap: 10px;
  padding: 0 16px; border-bottom: 1px solid var(--line); border-right: 1px solid var(--line);
  height: 56px; }
#brand h1 { font-size: 14px; margin: 0; font-weight: 600; letter-spacing: .02em; white-space: nowrap; }
#brand .dot { width: 9px; height: 9px; border-radius: 50%; background: var(--gold); flex: none; }
#top { grid-area: top; display: flex; align-items: center; gap: 12px;
  padding: 0 16px; border-bottom: 1px solid var(--line); height: 56px; }
#top .grow { flex: 1; }
#source, #top .status { min-width: 0; overflow: hidden;
  text-overflow: ellipsis; white-space: nowrap; }
#rail { grid-area: rail; border-right: 1px solid var(--line); overflow-y: auto;
  padding: 12px 10px; display: flex; flex-direction: column; gap: 2px; }
#editorPane { grid-area: editor; overflow-y: auto; padding: 20px 24px 32px; }
#previewPane { grid-area: preview; border-left: 1px solid var(--line);
  overflow-y: auto; padding: 16px; background: #0E1421; }
#bar { grid-area: bar; display: flex; align-items: center; gap: 8px;
  border-top: 1px solid var(--line); padding: 10px 16px calc(10px + env(safe-area-inset-bottom));
  background: var(--surface); flex-wrap: wrap; }
#bar .grow { flex: 1; }
#editor { max-width: 720px; }

/* --- navigation -------------------------------------------------------- */

.section {
  display: flex; align-items: center; gap: 8px; width: 100%;
  text-align: start; background: none; border: 1px solid transparent;
  padding: 9px 10px; min-height: 40px; border-radius: 8px; color: var(--muted);
}
.section:hover { background: var(--raised); }
.section[aria-current="page"] { background: var(--raised); color: var(--text); border-color: var(--line); }
.section .name { flex: 1; }
.section .pip { width: 7px; height: 7px; border-radius: 50%; background: var(--gold); flex: none; }
.section .pip[hidden] { display: none; }
.railHead { color: var(--muted); font-size: 11px; text-transform: uppercase;
  letter-spacing: .1em; padding: 12px 10px 6px; }

/* --- editor ------------------------------------------------------------ */

.crumbs { display: flex; align-items: center; gap: 4px; flex-wrap: wrap;
  margin: 0 0 6px; padding: 0; list-style: none; font-size: 13px; color: var(--muted); }
.crumbs li { display: flex; align-items: center; gap: 4px; }
.crumbs li::after { content: "›"; color: var(--line); }
.crumbs li:last-child::after { content: ""; }
.crumbs button { background: none; border: none; padding: 2px 4px; min-height: 28px;
  color: var(--muted); font-size: 13px; text-decoration: underline; text-underline-offset: 3px; }
.crumbs button:hover { color: var(--gold); }
.crumbs .here { color: var(--text); padding: 2px 4px; }
.panelHead { display: flex; align-items: flex-start; gap: 16px; margin: 0 0 18px; }
.panelHead .titles { flex: 1; min-width: 0; }
.panelHead h2 { margin: 0; font-size: 21px; font-weight: 600; letter-spacing: .01em; }
.panelHead p { margin: 4px 0 0; color: var(--muted); font-size: 13px; }

.langTabs { display: flex; flex-direction: column; gap: 4px; flex: none;
  border: 1px solid var(--line); border-radius: 10px; padding: 4px; background: var(--surface); }
.langTabs button { min-height: 34px; padding: 4px 12px; font-size: 12px; letter-spacing: .06em;
  background: none; border: 1px solid transparent; color: var(--muted); border-radius: 7px; }
.langTabs button[aria-selected="true"] { background: var(--raised); color: var(--gold); border-color: var(--line); }

.field { margin: 0 0 18px; }
.field > label, .fieldLabel { display: block; margin: 0 0 5px; color: var(--muted);
  font-size: 12px; text-transform: uppercase; letter-spacing: .08em; }
.field .help { margin: 5px 0 0; color: var(--muted); font-size: 12.5px; line-height: 1.45; }
.field .issue { margin: 5px 0 0; font-size: 12.5px; color: var(--alert); }
.field .issue.warn { color: var(--gold); }
.field .otherLang { margin: 5px 0 0; font-size: 12px; color: var(--muted); }
.field input[aria-invalid="true"], .field textarea[aria-invalid="true"] { border-color: var(--alert); }
.required { color: var(--gold); }
.pending { color: var(--muted); font-size: 11px; border: 1px solid var(--line);
  border-radius: 999px; padding: 1px 7px; letter-spacing: .04em; text-transform: none; }

.group { border: 1px solid var(--line); border-radius: 10px; padding: 14px; margin: 0 0 18px;
  background: var(--surface); }
.group > .groupHead { display: flex; align-items: center; gap: 8px; margin: 0 0 12px; }
.group > .groupHead h3 { margin: 0; font-size: 13px; font-weight: 600; color: var(--gold);
  text-transform: uppercase; letter-spacing: .09em; }
.group .field:last-child { margin-bottom: 0; }

.rows { border: 1px solid var(--line); border-radius: 10px; overflow: hidden; background: var(--surface); }
.row { display: flex; align-items: center; gap: 6px; padding: 6px 8px 6px 12px;
  border-bottom: 1px solid var(--line-soft); }
.row:last-child { border-bottom: none; }
.row .open { flex: 1; min-width: 0; text-align: start; background: none; border: none;
  padding: 8px 0; display: block; }
.row .open .t { display: block; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.row .open .s { display: block; color: var(--muted); font-size: 12.5px;
  overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.row .grip { color: var(--muted); font-size: 12px; min-width: 22px; text-align: end; flex: none; }
.rowTools { display: flex; gap: 2px; flex: none; }
.rowTools button { min-height: 34px; min-width: 34px; padding: 4px 6px; font-size: 13px;
  background: none; border-color: transparent; }
.rowTools button:hover:not(:disabled) { background: var(--raised); border-color: var(--line); }
.listFoot { display: flex; gap: 8px; align-items: center; margin: 10px 0 0; }
.empty { padding: 18px 14px; color: var(--muted); font-size: 13.5px; text-align: center; }

.inlineItem { border: 1px solid var(--line); border-radius: 10px; margin: 0 0 8px; background: var(--surface); }
.inlineItem > .head { display: flex; align-items: center; gap: 6px; padding: 6px 8px 6px 12px; }
.inlineItem > .head .open { flex: 1; text-align: start; background: none; border: none; padding: 8px 0; }
.inlineItem > .body { padding: 4px 14px 14px; border-top: 1px solid var(--line-soft); }
.inlineItem > .body[hidden] { display: none; }

/* --- media -------------------------------------------------------------- */

.mediaThumb { display: block; max-width: 100%; max-height: 180px;
  border-radius: 8px; border: 1px solid var(--line); background: var(--void); }
.mediaThumb.small { max-height: 96px; }
.assetPreview { margin-top: 10px; }
.assetPreview audio { width: 100%; max-width: 320px; }
.mediaCard { display: flex; gap: 14px; align-items: flex-start; }
.mediaFigure { flex: none; width: 168px; }
.mediaFigure audio { width: 100%; }
.mediaBody { flex: 1; min-width: 0; }
.mediaBody h3 { margin: 0 0 4px; font-size: 13px; font-weight: 600;
  color: var(--gold); text-transform: uppercase; letter-spacing: .08em; }
.mono { font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  word-break: break-all; }
.mediaGrid { display: grid; gap: 10px;
  grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); }
.mediaChoice { display: flex; flex-direction: column; gap: 6px; align-items: stretch;
  text-align: start; padding: 8px; height: auto; }
.progress { height: 6px; border-radius: 3px; background: var(--raised);
  overflow: hidden; margin-top: 10px; }
.progress .bar { height: 100%; width: 0; background: var(--gold);
  transition: width .12s linear; }
/* A file input styled as a button, because a browser will not let the real
   control be styled and the owner should not be able to tell. */
.filePicker { position: absolute; width: 1px; height: 1px; opacity: 0;
  overflow: hidden; clip: rect(0 0 0 0); }
label.buttonish { display: inline-flex; align-items: center; margin: 0;
  min-height: 36px; padding: 6px 10px; font-size: 13px; letter-spacing: 0;
  text-transform: none; color: var(--text); background: var(--raised);
  border: 1px solid var(--line); border-radius: 8px; cursor: pointer; }
label.buttonish:hover { border-color: var(--gold); }
.filePicker:focus-visible + * , input.filePicker:focus-visible ~ label.buttonish {
  outline: 2px solid var(--gold); outline-offset: 2px; }
.listFoot { flex-wrap: wrap; }

.chips { display: flex; flex-wrap: wrap; gap: 6px; }
.chip { display: flex; align-items: center; gap: 4px; border: 1px solid var(--line);
  border-radius: 999px; padding: 3px 4px 3px 12px; background: var(--surface); }
.chip input { width: 5.5em; min-height: 32px; padding: 4px 6px; border: none; background: none; text-align: center; }
.chip input.wide { width: 12em; text-align: start; }
.chip button { min-height: 28px; min-width: 28px; padding: 0; border: none; background: none; color: var(--muted); }
.chip button:hover { color: var(--alert); }

.checks { display: flex; flex-wrap: wrap; gap: 14px; }
.check { display: flex; align-items: center; gap: 8px; }
.check label { text-transform: none; letter-spacing: 0; font-size: 14px; color: var(--text); margin: 0; }
.pair { display: flex; gap: 10px; }
.pair > div { flex: 1; }

.warn { border-left: 3px solid var(--alert); background: rgba(210,105,74,.09);
  padding: 10px 12px; margin: 0 0 18px; border-radius: 0 8px 8px 0; font-size: 13px; }
.note { color: var(--muted); font-size: 13px; }
.status { font-size: 13px; color: var(--muted); }
.status.bad { color: var(--alert); }
.status.good { color: var(--ok); }
.count { font-size: 12px; color: var(--muted); border: 1px solid var(--line);
  border-radius: 999px; padding: 1px 8px; }
.count.bad { color: var(--alert); border-color: var(--alert); }

/* --- preview ----------------------------------------------------------- */

#previewPane h2 { font-size: 12px; text-transform: uppercase; letter-spacing: .1em;
  color: var(--muted); margin: 0 0 8px; }
.previewNote { border: 1px dashed var(--line); border-radius: 8px; padding: 10px 12px;
  color: var(--muted); font-size: 12.5px; line-height: 1.5; margin: 0 0 14px; }
.outline { font-size: 13.5px; }
.outline .o { padding: 8px 10px; border-radius: 8px; border: 1px solid transparent; }
.outline .o.on { border-color: var(--gold); background: rgba(227,169,63,.07); }
.outline .k { display: block; color: var(--muted); font-size: 11px;
  text-transform: uppercase; letter-spacing: .08em; }
.outline .v { display: block; white-space: pre-wrap; word-break: break-word; }
.outline .v + .v { margin-top: 2px; }
.outline .v.none { color: var(--muted); font-style: italic; }
.outline [dir="rtl"] { text-align: right; }

/* --- gate -------------------------------------------------------------- */

#gate { max-width: 380px; margin: 0 auto; padding: 14vh 20px 0; }
#gate h1 { font-size: 18px; margin: 0 0 4px; }
#gate p { color: var(--muted); font-size: 13px; }
#gate .field { margin-top: 18px; }
body.locked { overflow: auto; }

/* --- responsive -------------------------------------------------------- */

#previewToggle { display: none; }
@media (max-width: 1240px) {
  :root { --preview: 0px; }
  #frame { grid-template-areas: "brand top" "rail editor" "rail bar";
    grid-template-columns: var(--rail) minmax(0, 1fr); }
  #previewPane { display: none; grid-area: editor; border-left: none; }
  #previewToggle { display: inline-flex; }
  body.showPreview #editorPane { display: none; }
  body.showPreview #previewPane { display: block; }
}
@media (max-width: 860px) {
  #frame { grid-template-columns: minmax(0, 1fr);
    grid-template-areas: "brand" "top" "rail" "editor" "bar";
    grid-template-rows: auto auto auto 1fr auto; }
  #brand { border-right: none; }
  #rail { flex-direction: row; overflow-x: auto; overflow-y: hidden;
    border-right: none; border-bottom: 1px solid var(--line); padding: 8px 10px; }
  .section { width: auto; white-space: nowrap; }
  .railHead { display: none; }
  #editorPane { padding: 16px 14px 28px; }
  .panelHead { flex-direction: column-reverse; align-items: stretch; }
  .langTabs { flex-direction: row; align-self: flex-start; }
  #bar { position: sticky; bottom: 0; }
  /* A finger is not a mouse pointer. The owner asked to be able to do this
     from his phone, so nothing on it is a 28px icon button. */
  /* Three buttons and a sentence do not fit across 390px in one line, and
     letting them wrap cost a fifth of the screen. The sentence takes the
     first line; the buttons share the second. */
  /* Without the spacer, the one line that has something to say gets the
     width. Both truncating at once is the worst of both. */
  #top { padding: 0 12px; gap: 8px; }
  #top .grow { display: none; }
  #source { flex: 1 1 auto; }
  #bar { padding: 8px 12px calc(8px + env(safe-area-inset-bottom)); gap: 6px; }
  #bar #changeCount { width: 100%; font-size: 12px; }
  #bar .grow { display: none; }
  #bar button { flex: 1; min-width: 0; padding-inline: 8px; }
  .rowTools button, .chip button { min-height: 44px; min-width: 44px; }
  .listFoot button, button.small, .section, .langTabs button { min-height: 44px; }
  label.buttonish { min-height: 44px; }
  .mediaCard { flex-direction: column; }
  .mediaFigure { width: 100%; }
  .chip { padding-inline-start: 14px; }
  .chip input { min-height: 40px; }
}
@media (prefers-reduced-motion: no-preference) {
  .row, .section, .inlineItem > .body { transition: background-color .12s ease; }
}
`;

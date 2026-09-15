import {designTokens} from './design-tokens.js';

export const styles = designTokens + `
* { box-sizing: border-box; }
[hidden] { display: none !important; }
html, body { height: 100%; }
body { margin: 0; background: var(--void); color: var(--text); font: var(--body)/1.6 var(--body-font); overflow: hidden; }
h1, h2, h3, .figure strong { font-family: var(--display-font); font-weight: 500; }
h3 { font-size: var(--heading); margin: 0 0 var(--s3); }
p { margin: 0 0 var(--s4); }
a { color: var(--gold); text-underline-offset: var(--s1); }
a:hover { color: var(--feedback); }
:focus-visible { outline: var(--focus) solid var(--feedback); outline-offset: var(--s1); }
button, label.buttonish { font: inherit; color: var(--gold); background: transparent; border: var(--hairline) solid var(--line); border-radius: var(--control); padding: var(--s2) var(--s4); min-height: var(--target); cursor: pointer; }
button:hover:not(:disabled), label.buttonish:hover { color: var(--feedback); border-color: var(--feedback); }
button:disabled { color: var(--muted); cursor: not-allowed; opacity: .6; }
button.primary { background: var(--gold); color: var(--void); border-color: var(--gold); font-weight: 600; }
button.primary:hover:not(:disabled) { background: var(--feedback); color: var(--void); }
button.small { font-size: var(--meta); padding: var(--s2) var(--s3); }
button.quiet { border-color: transparent; }
button.danger { color: var(--gold); }
input, textarea, select { width: 100%; min-width: 0; min-height: var(--target); padding: var(--s3); border: var(--hairline) solid var(--line); border-radius: var(--control); background: var(--void); color: var(--text); font: inherit; }
input:hover, textarea:hover, select:hover { border-color: var(--feedback); }
input[type="checkbox"] { width: var(--s6); height: var(--s6); min-height: 0; accent-color: var(--gold); }
textarea { min-height: calc(var(--s16) * 2); resize: vertical; }
input[dir="rtl"], textarea[dir="rtl"] { font-family: "IBM Plex Sans Arabic", var(--body-font); }
#frame { display: none; height: 100%; grid-template-columns: var(--sidebar-width, var(--sidebar)) minmax(0, 1fr) var(--preview-width, 50vw); grid-template-rows: var(--s16) minmax(0, 1fr) auto; grid-template-areas: "brand top top" "rail editor preview" "rail bar bar"; }
#frame.on { display: grid; }
#brand { grid-area: brand; gap: var(--s2); display: flex; align-items: center; padding: 0 var(--s3); background: var(--surface); border-bottom: var(--hairline) solid var(--line); }
#brand h1 { font-size: var(--body); line-height: 1.25; margin: 0; }
#brand h1 span { display: block; font: var(--meta)/1.6 var(--body-font); color: var(--muted); }
#top { grid-area: top; display: flex; align-items: center; gap: var(--s4); padding: 0 var(--s8); border-bottom: var(--hairline) solid var(--line); min-width: 0; }
.grow { flex: 1; }
#status, #source { min-width: 0; }
#rail { grid-area: rail; background: var(--surface); padding: var(--s6) var(--s4); overflow-y: auto; border-inline-end: var(--hairline) solid var(--line-soft); }
.section { display: flex; align-items: center; gap: var(--s2); width: 100%; text-align: start; border-color: transparent; margin-bottom: var(--s1); }
.section .name { flex: 1; }
.section[aria-current="page"] { border-color: var(--line); background: var(--void); font-weight: 600; }
.section .pip { width: var(--s2); height: var(--s2); background: var(--text); border-radius: 50%; }
.railHead, .eyebrow { font: var(--meta)/1.4 var(--mono-font); color: var(--muted); padding: var(--s6) var(--s4) var(--s2); }
#editorPane { grid-area: editor; padding: var(--s8); overflow-y: auto; min-width: 0; }
#editor { max-width: 1180px; margin: 0 auto; }
#previewPane { display: flex; flex-direction: column; grid-area: preview; border-inline-start: var(--hairline) solid var(--line); overflow: hidden; padding: var(--s3); background: var(--surface); min-width: 0; }
#bar { grid-area: bar; display: flex; align-items: center; flex-wrap: wrap; gap: var(--s2); padding: var(--s4) var(--s6) calc(var(--s4) + env(safe-area-inset-bottom)); border-top: var(--hairline) solid var(--line); background: var(--surface); }
body[data-view]:not([data-view="document"]) #frame { grid-template-columns: var(--sidebar-width, var(--sidebar)) minmax(0, 1fr); grid-template-areas: "brand top" "rail editor" "rail bar"; }
body[data-view]:not([data-view="document"]) #previewPane, body[data-view]:not([data-view="document"]) #bar, body[data-view]:not([data-view="document"]) #previewToggle { display: none; }
.panelHead { display: flex; align-items: start; gap: var(--s6); margin: var(--s2) 0 var(--s8); }
.titles { flex: 1; min-width: 0; }
.panelHead h2 { font-size: var(--display); line-height: 1.1; letter-spacing: -.01em; margin: 0 0 var(--s3); }
.panelHead p { color: var(--muted); max-width: 68ch; margin: 0; }
.crumbs { display: flex; align-items: center; gap: var(--s1); flex-wrap: wrap; margin: 0 0 var(--s4); padding: 0; list-style: none; font-size: var(--meta); color: var(--muted); }
.crumbs li { display: flex; align-items: center; }
.crumbs li:not(:last-child)::after { content: '/'; padding: 0 var(--s2); }
.crumbs button { border: none; padding: 0 var(--s1); font-size: inherit; }
.langTabs { display: flex; flex-direction: column; gap: var(--s1); flex: none; }
.langTabs button { font-size: var(--meta); }
.langTabs button[aria-selected="true"], .paneTabs button[aria-selected="true"] { border-color: var(--gold); background: var(--surface); }
.field { margin-bottom: var(--s6); }
.field > label, .fieldLabel { display: block; font-size: var(--small); margin-bottom: var(--s2); }
.help, .note, .otherLang, .status { color: var(--muted); font-size: var(--meta); }
.help, .otherLang, .issue { margin-top: var(--s2); }
.issue, .status.bad, .count.bad { color: var(--alert); }
.status.good, .warn, .issue.warn { color: var(--muted); }
input[aria-invalid="true"], textarea[aria-invalid="true"] { border-color: var(--alert); }
.required { color: var(--muted); }
.pending, .count { font: var(--meta)/1.4 var(--body-font); color: var(--muted); padding: var(--s1) var(--s2); border: var(--hairline) solid var(--line); border-radius: var(--control); }
.group, .figure, .chartCard { padding: var(--s6); border: var(--hairline) solid var(--line); background: var(--surface); margin-bottom: var(--s6); }
.groupHead { display: flex; align-items: center; gap: var(--s3); margin-bottom: var(--s4); }
.groupHead h3 { margin: 0; }
.group .field:last-child { margin-bottom: 0; }
.rows { border-block: var(--hairline) solid var(--line); }
.row { display: flex; align-items: center; gap: var(--s2); padding: var(--s3) 0; border-bottom: var(--hairline) solid var(--line-soft); }
.row:last-child { border-bottom: none; }
.row .open { flex: 1; min-width: 0; text-align: start; border: none; padding: var(--s2); }
.row .open .t, .row .open .s { display: block; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.row .open .s { color: var(--muted); font-size: var(--meta); }
.grip { color: var(--muted); font: var(--meta)/1.4 var(--mono-font); }
.rowTools { display: flex; flex: none; }
.rowTools button { padding: var(--s2); min-width: var(--target); border-color: transparent; }
.listFoot { display: flex; align-items: center; gap: var(--s2); flex-wrap: wrap; margin-top: var(--s4); }
.empty { color: var(--muted); padding: var(--s6); }
.inlineItem { margin-bottom: var(--s3); border: var(--hairline) solid var(--line); background: var(--surface); }
.inlineItem > .head { display: flex; align-items: center; padding: var(--s2); }
.inlineItem .head .open { flex: 1; text-align: start; border: none; }
.inlineItem > .body { padding: var(--s6); border-top: var(--hairline) solid var(--line); }
.rangeNote, .warn {  padding: var(--s4); background: var(--surface); margin-bottom: var(--s6); font-size: var(--small); }
.rangeNote p:last-child, .warn p:last-child { margin-bottom: 0; }
.figures { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: var(--s4); margin: var(--s6) 0; }
.figure { margin: 0; }
.figure strong { display: block; font-size: var(--display); line-height: 1.1; font-variant-numeric: tabular-nums; }
.figure .k { display: block; margin-top: var(--s4); font-size: var(--small); }
.figure .note { display: block; margin-top: var(--s2); }
.chartGrid, .pageGrid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: var(--s6); }
.chartGrid .group, .chartGrid .chartCard { margin: 0; }
.chartCard svg { width: 100%; display: block; overflow: visible; }
.chartGrid { margin-bottom: var(--s6); }
.chartGrid .wide { grid-column: 1 / -1; }
.chartAxis { stroke: var(--line); stroke-width: 1; }
.chartLabel { fill: var(--muted); font: var(--meta) var(--mono-font); }
.chartPoint { fill: var(--chart); }
.chartLine { fill: none; stroke: var(--chart); stroke-width: 2; }
.chartEmpty { min-height: calc(var(--s16) * 2); display: flex; flex-direction: column; justify-content: center; align-items: center; border-block: var(--hairline) dashed var(--line); text-align: center; }
.chartEmpty strong { font-family: var(--display-font); font-size: var(--heading); }
.chartEmpty p { color: var(--muted); font-size: var(--small); margin: var(--s2) 0; max-width: 42ch; }
.dataTable { width: 100%; border-collapse: collapse; font-size: var(--small); }
.dataTable th { text-align: start; color: var(--muted); font-weight: 400; }
.dataTable td, .dataTable th { padding: var(--s2); border-bottom: var(--hairline) solid var(--line-soft); }
.dataTable td:last-child { font-variant-numeric: tabular-nums; }
details summary { cursor: pointer; color: var(--gold); padding: var(--s3) 0; }
.bar { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr) auto; align-items: center; gap: var(--s3); margin-bottom: var(--s3); }
.barName { overflow-wrap: anywhere; font-size: var(--small); }
.barTrack { height: var(--s2); background: var(--raised); }
.barFill { display: block; height: 100%; background: var(--chart); }
.barCount { font: var(--meta)/1.4 var(--mono-font); }
.pageGrid { margin-bottom: var(--s6); }
.pageCard { display: flex; flex-direction: column; align-items: start; text-align: start; padding: var(--s6); border-radius: 0; background: var(--surface); }
.pageCard strong { font: var(--heading)/1.25 var(--display-font); }
.pageCard .note { margin: var(--s3) 0; }
.pageCard .meta { color: var(--muted); font: var(--meta)/1.4 var(--mono-font); }
.pageLinks { display: flex; flex-wrap: wrap; gap: var(--s2); margin-bottom: var(--s6); }
.paletteSample { padding: var(--s6); background: var(--void); color: var(--text); border: var(--hairline) solid var(--line); }
.paletteSample strong { display: block; font: var(--display)/1.1 var(--display-font); margin-bottom: var(--s4); }
.swatches { display: flex; height: var(--s3); margin-top: var(--s6); }
.swatches span { flex: 1; }
.mediaThumb { display: block; max-width: 100%; max-height: 180px; border: var(--hairline) solid var(--line); }
.mediaThumb.small { max-height: 96px; }
.assetPreview { margin-top: var(--s3); }
audio { max-width: 100%; }
.mediaCard { display: flex; gap: var(--s6); align-items: start; }
.mediaFigure { flex: none; width: 168px; }
.mediaBody { flex: 1; min-width: 0; }
.mono { font-family: var(--mono-font); overflow-wrap: anywhere; }
.mediaGrid { display: grid; gap: var(--s3); grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); }
.mediaChoice { display: flex; flex-direction: column; text-align: start; padding: var(--s3); gap: var(--s2); }
.progress { height: var(--s2); background: var(--raised); overflow: hidden; margin-top: var(--s3); }
.progress .bar { height: 100%; background: var(--chart); }
.filePicker { position: absolute; width: 1px; height: 1px; opacity: 0; overflow: hidden; clip: rect(0 0 0 0); }
.filePicker:focus-visible ~ label.buttonish { outline: var(--focus) solid var(--feedback); outline-offset: var(--s1); }
label.buttonish { display: inline-flex; align-items: center; font-size: var(--meta); margin: 0; }
.chips, .checks { display: flex; flex-wrap: wrap; gap: var(--s2); }
.chip { display: flex; align-items: center; border: var(--hairline) solid var(--line); padding-inline-start: var(--s2); border-radius: var(--control); }
.chip input { width: 5.5em; border: none; background: none; }
.chip input.wide { width: 12em; }
.chip button { border: none; min-width: var(--target); }
.check { display: flex; align-items: center; gap: var(--s2); }
.check label { margin: 0; }
.pair { display: flex; gap: var(--s4); }
.pair > div { flex: 1; min-width: 0; }
.previewNote { padding: var(--s4); border: var(--hairline) solid var(--line); color: var(--muted); font-size: var(--meta); }
.paneTabs { display: flex; gap: var(--s2); margin-bottom: var(--s4); }
.paneTabs button { flex: 1; font-size: var(--meta); }
#previewWrap { display: flex; flex-direction: column; flex: 1; min-height: 0; }
#outlineWrap { overflow: auto; min-height: 0; flex: 1; }
#previewFrame { flex: 1; min-height: 0; }
#previewFrame iframe { display: block; width: 100%; height: 100%; border: 0; background: var(--void); }
.previewNote { border: 0; padding: var(--s2) 0; margin: 0; }
.paneTools { display: flex; flex-wrap: wrap; align-items: center; gap: var(--s2); margin-bottom: var(--s2); }
.paneTools select { width: auto; font-size: var(--meta); padding: var(--s2); }
.outline { font-size: var(--small); }
.outline .o { padding: var(--s3); border-bottom: var(--hairline) solid var(--line-soft); }
.outline .o.on {  }
.outline .k, .outline .v { display: block; overflow-wrap: anywhere; white-space: pre-wrap; }
.outline .k { color: var(--muted); font-size: var(--meta); margin-bottom: var(--s2); }
#gate { max-width: 520px; margin: 12vh auto; padding: var(--s12); border: var(--hairline) solid var(--line); background: var(--surface); }
#gate .eyebrow { padding: 0; margin-bottom: var(--s8); }
#gate h1 { font-size: var(--display); line-height: 1.1; margin: 0 0 var(--s4); }
#gate p { color: var(--muted); }
#gate .field { margin-top: var(--s8); }
#gateStatus.bad { color: var(--alert); }
body.locked { overflow: auto; }
dialog { background: var(--surface); color: var(--text); border: var(--hairline) solid var(--line); border-radius: var(--modal); padding: 0; max-width: min(680px, 92vw); width: 100%; }
dialog::backdrop { background: var(--void); opacity: .8; }
.sheetHead { display: flex; align-items: center; gap: var(--s3); padding: var(--s4); border-bottom: var(--hairline) solid var(--line); }
.sheetHead h2 { margin: 0; font-size: var(--heading); flex: 1; }
.sheetBody { padding: var(--s6); max-height: 66vh; overflow-y: auto; }
.diff { font: var(--meta)/1.55 var(--mono-font); white-space: pre-wrap; overflow-wrap: anywhere; }
.diff.added, .diff.removed { color: var(--text); }
#menuToggle, #previewToggle { display: inline-flex; }
#menuToggle { flex: none; }
body.navClosed { --sidebar-width: 0px; }
body.navClosed #rail, body.navClosed #brand h1 { display: none; }
body.navClosed #brand { border: 0; padding: 0; overflow: visible; z-index: 1; }
body.navClosed #menuToggle { margin-inline-start: var(--s2); }
body.navClosed #top { padding-inline-start: calc(var(--target) + var(--s8)); }
body.previewClosed #frame { --preview-width: 0px; }
body.previewClosed #previewPane { display: none; }
body.previewThird { --preview-width: 34vw; }

@media (min-width: 1001px) and (max-width: 1200px) {
  #editorPane { padding: var(--s4); }
  .panelHead { gap: var(--s3); }
  .panelHead h2 { font-size: var(--compact-display); overflow-wrap: anywhere; }
}
@media (max-width: 1000px) {
  #frame { grid-template-columns: var(--sidebar-width, var(--sidebar)) minmax(0, 1fr); grid-template-areas: "brand top" "rail editor" "rail bar"; }
  #previewPane { display: none; grid-area: editor; }
  #previewToggle { display: inline-flex; }
  body.showPreview[data-view="document"] #editorPane { display: none; }
  body.showPreview[data-view="document"] #previewPane { display: flex; }
  #previewSize { display: none; }
}
@media (max-width: 760px) {
  #frame, body[data-view]:not([data-view="document"]) #frame { grid-template-columns: minmax(0, 1fr); grid-template-areas: "brand" "top" "rail" "editor" "bar"; grid-template-rows: auto auto auto minmax(0, 1fr) auto; }
  #brand { padding: var(--s4); justify-content: space-between; }
  body.navClosed #brand h1 { display: block; }
  body.navClosed #brand { padding: var(--s4); }
  body.navClosed #top { padding-inline-start: var(--s4); }
  #top { padding: var(--s2) var(--s4); min-height: var(--target); gap: var(--s2); flex-wrap: wrap; }
  #top .grow { display: none; }
  #source { flex: 1; }
  #menuToggle { display: block; }
  #rail { display: none; max-height: 40vh; padding: var(--s3); }
  body.menuOpen #rail { display: block; }
  #editorPane { padding: var(--s6) var(--s4); }
  .panelHead h2 { font-size: var(--compact-display); }
  .panelHead { gap: var(--s3); }
  .langTabs { flex-direction: column; }
  .figures { grid-template-columns: 1fr; gap: var(--s3); }
  .figure { display: grid; grid-template-columns: 1fr auto; padding: var(--s4); }
  .figure strong { grid-column: 2; grid-row: 1 / 3; align-self: center; font-size: var(--compact-display); }
  .figure .k, .figure .note { margin: 0; grid-column: 1; }
  .chartGrid, .pageGrid { grid-template-columns: 1fr; }
  .chartCard, .group { padding: var(--s4); }
  #bar { padding: var(--s3); }
  #changeCount { width: 100%; }
  #bar .grow { display: none; }
  #bar button { flex: 1; padding: var(--s2); font-size: var(--meta); }
  #bar #publish { flex-basis: 100%; }
  .row { flex-wrap: wrap; }
  .row .open { flex-basis: 60%; }
  .mediaCard { flex-direction: column; }
  .mediaFigure { width: 100%; }
  #gate { margin: var(--s6) var(--s4); padding: var(--s6); }
  #gate h1 { font-size: var(--compact-display); }
}
`;

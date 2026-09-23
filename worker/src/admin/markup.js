/**
 * The static part of the panel: the frame the script fills in.
 *
 * "Sherbini's Portfolio", not Nocturne. Nocturne is the name of the codebase
 * and it meant nothing to the person logging in to change his own website.
 */

export const brandName = "Sherbini's Portfolio";

/// The two-letter codes the site can draw a flag for, offered as suggestions.
export function countryList(codes) {
  return codes
    .map((code) => '<option value="' + code + '"></option>')
    .join('');
}

export const markup = `
<section id="gate">
  <p class="eyebrow">Portfolio administration</p>
  <h1>${brandName}</h1>
  <p>Manage pages, media and site insights.</p>
  <div class="field">
    <label for="token">Password</label>
    <input id="token" type="password" autocomplete="current-password"
           placeholder="Enter your password">
  </div>
  <button class="primary" id="unlock" style="width:100%">Sign in</button>
  <p class="note" id="gateStatus" role="status" aria-live="polite">Use your admin password or recovery token.</p>
</section>

<div id="frame">
  <div id="brand">
    <h1>${brandName}<span>Administration</span></h1>
    <button id="menuToggle" type="button" aria-controls="rail" aria-expanded="true" aria-label="Minimize navigation">☰</button>
  </div>

  <div id="top">
    <span id="source" class="note"></span>
    <span class="grow"></span>
    <button id="paletteToggle" type="button" class="small" aria-label="Switch admin to light appearance">Light</button>
    <span id="status" class="status" role="status" aria-live="polite"></span>
    <button id="previewToggle" type="button" class="small" aria-controls="previewPane" aria-expanded="true">
      Hide preview
    </button>
  </div>

  <nav id="rail" aria-label="Sections"></nav>

  <div id="editorPane">
    <div id="editor"></div>
  </div>

  <aside id="previewPane" aria-label="Preview">
    <div class="paneTools">
      <label for="previewSize" class="note">Preview width</label>
      <select id="previewSize" aria-label="Preview width"><option value="half">Half screen</option><option value="third">Third of screen</option></select>
      <span class="grow"></span><button id="minimizePreview" type="button" class="small" aria-label="Minimize preview and outline">Minimize</button>
    </div>
    <div class="paneTabs" role="tablist" aria-label="Right-hand panel">
      <button id="showPreview" type="button" role="tab" aria-selected="true">
        Preview
      </button>
      <button id="showOutline" type="button" role="tab" aria-selected="false">
        Outline
      </button>
    </div>

    <div id="previewWrap" hidden>

      <p class="previewNote" id="previewState">Waiting for the preview...</p>
      <button id="previewRetry" type="button" class="small" hidden>Try again</button>
      <div id="previewFrame"></div>
    </div>

    <div id="outlineWrap">
      <p class="previewNote">
        Text outline of the current draft. Switch to Preview to see the website.
      </p>
      <div id="outline" class="outline"></div>
    </div>
  </aside>

  <div id="bar">
    <span id="changeCount" class="note"></span>
    <span id="problemCount" class="count bad" hidden></span>
    <span id="divergence" class="count bad" hidden></span>
    <span class="grow"></span>
    <button id="discard" type="button">Discard</button>
    <button id="history" type="button">History</button>
    <button id="withdraw" type="button" class="danger">Withdraw</button>
    <button id="publish" type="button" class="primary">Review and publish</button>
  </div>
</div>

<dialog id="reauth" aria-labelledby="reauthTitle">
  <div class="sheetHead">
    <h2 id="reauthTitle">Session expired</h2>
  </div>
  <div class="sheetBody">
    <p class="note">
      Your drafts are preserved in this tab. Sign in to continue.
    </p>
    <div class="field">
      <label for="reauthPassword">Password</label>
      <input id="reauthPassword" type="password" autocomplete="current-password">
    </div>
    <p class="issue" id="reauthError"></p>
    <div class="listFoot">
      <button id="reauthGo" type="button" class="primary">Sign in</button>
    </div>
  </div>
</dialog>

<dialog id="sheet" aria-labelledby="sheetTitle">
  <div class="sheetHead">
    <h2 id="sheetTitle"></h2>
    <button id="sheetClose" type="button" class="small quiet" aria-label="Close">
      Close
    </button>
  </div>
  <div id="sheetBody" class="sheetBody"></div>
</dialog>
`;

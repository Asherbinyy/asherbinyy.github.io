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
  <h1>${brandName}</h1>
  <p>Sign in to change what the site says.</p>
  <div class="field">
    <label for="token">Admin token</label>
    <input id="token" type="password" autocomplete="current-password"
           placeholder="The value of ADMIN_TOKEN">
  </div>
  <button class="primary" id="unlock" style="width:100%">Unlock</button>
  <p class="note" id="gateStatus">Held for this tab only, never written to disk.</p>
</section>

<div id="frame">
  <div id="brand">
    <span class="dot" aria-hidden="true"></span>
    <h1>${brandName}</h1>
  </div>

  <div id="top">
    <span id="source" class="note"></span>
    <span class="grow"></span>
    <span id="status" class="status" role="status" aria-live="polite"></span>
    <button id="previewToggle" type="button" class="small" aria-pressed="false">
      Outline
    </button>
  </div>

  <nav id="rail" aria-label="Sections"></nav>

  <div id="editorPane">
    <div id="editor"></div>
  </div>

  <aside id="previewPane" aria-label="Draft outline">
    <h2>Draft outline</h2>
    <p class="previewNote">
      This is your draft read back to you. It is <strong>not</strong> the
      website: it does not use the site's own components, and it cannot show
      you how a page will look. A real preview of the live page arrives with
      the public preview adapter.
    </p>
    <div id="outline" class="outline"></div>
  </aside>

  <div id="bar">
    <span id="changeCount" class="note"></span>
    <span id="problemCount" class="count bad" hidden></span>
    <span class="grow"></span>
    <button id="review" type="button">Review</button>
    <button id="withdraw" type="button" class="danger">Withdraw</button>
    <button id="publish" type="button" class="primary">Publish page</button>
  </div>
</div>

<dialog id="sheet" aria-labelledby="sheetTitle">
  <div class="sheetHead">
    <h2 id="sheetTitle"></h2>
    <button id="sheetClose" type="button" class="small quiet" aria-label="Close">
      Close
    </button>
  </div>
  <div id="sheetBody"></div>
</dialog>
`;

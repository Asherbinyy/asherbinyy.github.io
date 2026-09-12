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
    <label for="token">Password</label>
    <input id="token" type="password" autocomplete="current-password"
           placeholder="Your password, or the deployment secret">
  </div>
  <button class="primary" id="unlock" style="width:100%">Sign in</button>
  <p class="note" id="gateStatus">
    This exchanges what you type for a session that expires and can be ended.
    The deployment secret works here too, and is the way in if the password is
    forgotten.
  </p>
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

  <aside id="previewPane" aria-label="Preview">
    <div class="paneTabs" role="tablist" aria-label="Right-hand panel">
      <button id="showPreview" type="button" role="tab" aria-selected="true">
        Preview
      </button>
      <button id="showOutline" type="button" role="tab" aria-selected="false">
        Outline
      </button>
    </div>

    <div id="previewWrap">
      <p class="previewNote" id="previewState">Waiting for the preview...</p>
      <button id="previewRetry" type="button" class="small" hidden>Try again</button>
      <div id="previewFrame"></div>
    </div>

    <div id="outlineWrap" hidden>
      <p class="previewNote">
        Your draft read back to you. It is <strong>not</strong> the website: it
        does not use the site's own components, and it cannot show you how a
        page will look.
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
    <h2 id="reauthTitle">Your session ended</h2>
  </div>
  <div id="sheetBody">
    <p class="note">
      Nothing has been lost. Your unpublished drafts are still here; sign in
      again to carry on.
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
  <div id="sheetBody"></div>
</dialog>
`;

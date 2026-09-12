/**
 * The editor's half of preview protocol v1.
 *
 * Codex confirmed the protocol in `docs/23-ADMIN-INTEGRATION-REPLY.md` and
 * pinned the parts that had been left open: component identifiers are
 * `"<document filename>:<path>"`, the public components will carry
 * `data-content-file` and `data-content-path`, the production origin stays
 * `https://asherbinyy.github.io`, and the isolated Astro development origin is
 * `http://127.0.0.1:4321`.
 *
 * **The adapter on the other side is not built yet.** That is fine and it is
 * handled: this speaks first, waits for a `ready` that may never come, and
 * says plainly that the preview did not answer rather than showing an empty
 * frame and letting the owner conclude his site is blank. The outline stays
 * available the whole time.
 *
 * What never crosses this channel: the session token, the password, anything
 * from `sessionStorage`. The messages carry a document draft, a locale and a
 * component id, and nothing else. `targetOrigin` is always the exact
 * configured origin -- never `*` -- and every arriving message is checked for
 * its origin, its source window, the channel, the version and the session
 * before a single field of it is read.
 */

export const clientPreview = `
const previewChannel = 'portfolio-preview';
const previewVersion = 1;

/// Regenerated for every frame load. A message stamped with a session that is
/// not the current one is from a page that has been navigated away from.
function newSessionId() {
  return Array.from(crypto.getRandomValues(new Uint8Array(16)), (byte) =>
    byte.toString(16).padStart(2, '0')).join('');
}

const preview = {
  session: null,
  frame: null,
  ready: false,
  waiting: false,
  lastRequest: 0,
  acknowledged: 0,
  error: '',
  pending: false,
  components: [],
  remoteErrors: [],
};

/// Whether a preview origin has been configured at all.
function previewConfigured() {
  return typeof PREVIEW_ORIGIN === 'string' && PREVIEW_ORIGIN !== '';
}

/// The identifier both sides use for one value in one document.
function componentIdFor(file, path) {
  return file + ':' + path.join('.');
}

function postToPreview(type, payload) {
  if (!preview.frame || !preview.frame.contentWindow || !preview.session) return;
  preview.frame.contentWindow.postMessage(
    {
      channel: previewChannel,
      version: previewVersion,
      sessionId: preview.session,
      type: type,
      payload: payload,
    },
    // Never '*'. The exact configured origin, so a page that has navigated
    // somewhere else receives nothing.
    PREVIEW_ORIGIN,
  );
}

/// Sends the current draft, if it is one the site could actually render.
///
/// The contract says a validated draft. A document with errors in it is not
/// something the public components have agreed to be handed, and rendering
/// half of it would show the owner a page the site would never produce.
function sendDraft() {
  if (!preview.ready) return;
  const file = state.file;
  const entry = state.docs.get(file);
  if (!entry) return;

  // The gate is not "the last answer for this file was clean". It is "this
  // exact draft was checked, and nothing has been typed since" (AR-6).
  // Emptying a required field and switching language inside the debounce used
  // to send the broken draft and call it rendered.
  const issues = state.issues.get(file);
  if (!issues || issues.generation !== entry.generation) {
    preview.waiting = false;
    preview.error = '';
    preview.pending = true;
    drawPreviewState();
    return;
  }
  preview.pending = false;
  if (issues.errors.length > 0) {
    preview.waiting = false;
    preview.error = 'Fix the problems on this page and the preview will follow.';
    drawPreviewState();
    return;
  }
  preview.error = '';
  preview.lastRequest += 1;
  preview.waiting = true;
  postToPreview('draft', {
    requestId: preview.lastRequest,
    file: file,
    schemaVersion: previewVersion,
    locale: state.lang,
    // The snapshot that was validated, not whatever the draft holds now.
    document: issues.document,
  });
  drawPreviewState();
  // A preview that never answers must not leave the panel saying "rendering"
  // for the rest of the afternoon.
  const asked = preview.lastRequest;
  setTimeout(() => {
    if (preview.waiting && preview.lastRequest === asked) {
      preview.waiting = false;
      preview.error = 'The preview did not answer that draft.';
      drawPreviewState();
    }
  }, 6000);
}

/// Asks the preview to scroll to whatever is being edited.
function selectInPreview() {
  if (!preview.ready || state.view !== 'document') return;
  postToPreview('select', {
    componentId: componentIdFor(state.file, state.path),
  });
}

function onPreviewMessage(event) {
  if (!previewConfigured()) return;
  // Origin, then source window, then shape. In that order: none of the rest is
  // worth reading from a page that is not the one in the frame.
  if (event.origin !== PREVIEW_ORIGIN) return;
  if (!preview.frame || event.source !== preview.frame.contentWindow) return;
  const message = event.data;
  if (!message || typeof message !== 'object') return;
  if (message.channel !== previewChannel) return;
  if (message.version !== previewVersion) return;
  if (message.sessionId !== preview.session) return;

  if (message.type === 'ready') {
    preview.ready = true;
    preview.error = '';
    preview.components = Array.isArray(message.payload?.components)
      ? message.payload.components
      : [];
    drawPreviewState();
    sendDraft();
    selectInPreview();
    return;
  }

  if (message.type === 'rendered') {
    const answered = message.payload?.requestId;
    // Stale acknowledgements are ignored rather than believed: the draft has
    // moved on and this is describing something the owner is no longer
    // looking at.
    if (answered !== preview.lastRequest) return;
    preview.waiting = false;
    preview.acknowledged = answered;
    preview.remoteErrors = Array.isArray(message.payload?.errors)
      ? message.payload.errors
      : [];
    drawPreviewState();
  }
}

window.addEventListener('message', onPreviewMessage);

/// Builds the frame, with a fresh session.
function mountPreview() {
  const holder = el('previewFrame');
  holder.replaceChildren();
  preview.ready = false;
  preview.waiting = false;
  preview.remoteErrors = [];
  preview.error = '';
  preview.session = newSessionId();

  if (!previewConfigured()) {
    preview.error = 'No preview origin is configured for this deployment.';
    drawPreviewState();
    return;
  }

  const frame = document.createElement('iframe');
  frame.title = 'Preview of the site';
  frame.referrerPolicy = 'no-referrer';
  // The preview renders the owner's own draft and needs no more than this.
  frame.sandbox = 'allow-scripts allow-same-origin';
  frame.src = PREVIEW_ORIGIN + '/?preview=1&session=' + preview.session;
  frame.onload = () => {
    // The other side speaks first, by contract. If it never does, it is not a
    // preview adapter, and after a moment the panel says so.
    setTimeout(() => {
      if (!preview.ready) {
        preview.error =
          'The page at ' + PREVIEW_ORIGIN + ' did not answer the preview ' +
          'handshake. The public preview adapter has not been built yet.';
        drawPreviewState();
      }
    }, 3000);
  };
  frame.onerror = () => {
    preview.error = 'The preview could not be loaded.';
    drawPreviewState();
  };
  preview.frame = frame;
  holder.append(frame);
  drawPreviewState();
}

/// The line above the frame that says what is actually going on.
function drawPreviewState() {
  const line = el('previewState');
  if (!line) return;
  line.className = 'previewNote';
  if (preview.error) {
    line.textContent = preview.error;
    line.classList.add('bad');
  } else if (preview.pending) {
    line.textContent = 'Checking this draft before showing it...';
  } else if (!preview.ready) {
    line.textContent = 'Waiting for the preview to answer...';
  } else if (preview.waiting) {
    line.textContent = 'Sending the draft...';
  } else if (preview.remoteErrors.length > 0) {
    line.textContent = 'The preview could not render: ' +
      preview.remoteErrors.map((issue) => issue.message || issue).join('; ');
    line.classList.add('bad');
  } else if (preview.acknowledged > 0) {
    line.textContent = 'Showing your draft, as the site would render it.';
    line.classList.add('good');
  } else {
    line.textContent = 'Connected.';
  }

  const retry = el('previewRetry');
  if (retry) retry.hidden = preview.error === '';
}

/// Which of the two right-hand panels is showing.
function setRightPane(which) {
  state.rightPane = which;
  el('previewWrap').hidden = which !== 'preview';
  el('outlineWrap').hidden = which !== 'outline';
  for (const [id, name] of [['showPreview', 'preview'], ['showOutline', 'outline']]) {
    const button = el(id);
    if (button) button.setAttribute('aria-selected', String(which === name));
  }
  if (which === 'preview' && !preview.frame) mountPreview();
}
`;

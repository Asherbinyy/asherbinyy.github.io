/**
 * Protocol-v1 client for the real Flutter preview in lib/core/preview/.
 * Sends validated documents, locale and destination; credentials stay here.
 * Both directions check the exact origin, source window and fresh session.
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
  batch: 0,
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
async function sendDraft() {
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
    preview.error = 'Correct validation errors to update the preview.';
    drawPreviewState();
    return;
  }
  const batch = ++preview.batch;
  const session = preview.session;
  const generation = entry.generation;
  const documents = {};
  try {
    for (const [name, held] of state.docs) {
      let checked = state.issues.get(name);
      if (!checked || checked.generation !== held.generation) {
        // An edited dependency waits for its own normal validation. Untouched
        // published/bundled documents are checked here so preview starts with
        // every current document, not a mix of published and old bundle data.
        if (held.generation !== 0) continue;
        const snapshot = JSON.parse(JSON.stringify(held.draft));
        const response = await api('/v1/admin/validate', {method:'POST', headers:{'content-type':'application/json'}, body:JSON.stringify({file:name, document:snapshot, references:knownReferences(name)})});
        if (!response.ok) throw new Error('Could not check the preview content.');
        const verdict = await response.json();
        checked = {errors:verdict.errors, warnings:verdict.warnings, generation:0, document:snapshot};
        if (held.generation === 0) state.issues.set(name, checked);
      }
      if (checked.errors.length === 0 && checked.generation === held.generation) documents[name] = checked.document;
    }
  } catch (error) {
    if (batch === preview.batch) { preview.error = error.message; drawPreviewState(); }
    return;
  }
  if (batch !== preview.batch || session !== preview.session || file !== state.file || generation !== entry.generation) return;
  preview.error = '';
  preview.lastRequest += 1;
  preview.waiting = true;
  postToPreview('draft', {
    requestId: preview.lastRequest,
    file: file,
    schemaVersion: previewVersion,
    locale: state.lang,
    route: previewRoute(),
    document: issues.document,
    documents: documents,
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
function previewRoute() {
  const page = pageFor(state.page);
  if (page && page.id !== 'resume') return page.route;
  return {'profile.json': '/', 'career.json': '/journey', 'apps.json': '/work', 'education.json': '/about', 'interests.json': '/courtyard'}[state.file] || '/';
}
function selectInPreview() {
  if (!preview.ready || state.view !== 'document') return;
  postToPreview('select', {
    componentId: componentIdFor(state.file, state.path),
    route: previewRoute(),
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
          'handshake. Check that the preview build allows this admin origin, then retry.';
        drawPreviewState();
      }
    }, 30000);
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
    line.textContent = 'Validating draft…';
  } else if (!preview.ready) {
    line.textContent = 'Connecting preview…';
  } else if (preview.waiting) {
    line.textContent = 'Updating preview…';
  } else if (preview.remoteErrors.length > 0) {
    line.textContent = 'The preview could not render: ' +
      preview.remoteErrors.map((issue) => issue.message || issue).join('; ');
    line.classList.add('bad');
  } else if (preview.acknowledged > 0) {
    line.textContent = 'Preview up to date';
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

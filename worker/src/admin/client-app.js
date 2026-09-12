/**
 * Navigation, the editor panel, the outline and the buttons at the bottom.
 *
 * The layout is the one the owner asked for: sections down the left, the
 * thing being edited in the middle, and a panel on the right. The right-hand
 * panel is **not** the site. It says so, in the panel, because the contract
 * in `20-APP-ADMIN-CONTRACT.md` is explicit that a differently-styled admin
 * mock-up must not be presented as a live preview. It renders the draft as an
 * outline so there is something honest to look at and something for the real
 * preview adapter to replace when Codex lands it.
 */

export const clientApp = `
// --- navigation ------------------------------------------------------------

function go(file, path) {
  // Whatever the last thing to happen was, it was about the page being left.
  say('');
  state.view = 'document';
  state.file = file;
  state.path = path || [];
  const hash = '#' + file + (state.path.length ? '/' + state.path.join('/') : '');
  if (location.hash !== hash) history.replaceState(null, '', hash);
  render();
  el('editorPane').scrollTop = 0;
  check();
}

/// The sections that are not one of the owner's documents.
function goTo(view) {
  say('');
  // Coming back to the dashboard reads the counters again. A figure that is
  // as old as the tab is a figure nobody can trust.
  if (view === 'home') {
    state.insights = null;
    state.insightsError = '';
    state.release = null;
    state.releaseError = '';
  }
  state.view = view;
  if (location.hash !== '#' + view) history.replaceState(null, '', '#' + view);
  render();
  el('editorPane').scrollTop = 0;
}

const otherViews = [
  {id: 'media', label: 'Media', head: 'Library'},
  {id: 'account', label: 'Account', head: 'You'},
];

/// The section the panel opens on.
const homeView = {id: 'home', label: 'Home'};

function readHash() {
  const raw = decodeURIComponent(location.hash.slice(1));
  if (!raw) return null;
  if (raw === homeView.id) return {view: 'home'};
  if (otherViews.some((view) => view.id === raw)) return {view: raw};
  const parts = raw.split('/');
  const file = parts[0];
  if (!schemaFor(file)) return null;
  const path = parts.slice(1).map((step) => (/^\\d+$/.test(step) ? Number(step) : step));
  return {view: 'document', file: file, path: path};
}

// --- rendering -------------------------------------------------------------

/// Redraws the panel, putting the caret back where the owner left it.
///
/// Everything is rebuilt on each change because the alternative is a
/// diffing layer, and this is one form for one person. The caret is restored
/// by hand because a validation result arriving mid-sentence must not throw
/// the owner out of the box he is typing in.
function render() {
  const active = document.activeElement;
  const id = active && active.id ? active.id : null;
  let start = null;
  let end = null;
  try {
    start = active ? active.selectionStart : null;
    end = active ? active.selectionEnd : null;
  } catch (error) {
    start = null;
  }

  renderRail();
  // The preview follows whatever is being edited, but only once it has
  // answered. Sent before the redraw so a slow frame does not hold it up.
  if (state.rightPane === 'preview') selectInPreview();
  if (state.view === 'home') renderHome();
  else if (state.view === 'media') renderLibrary();
  else if (state.view === 'account') renderAccount();
  else renderEditor();
  renderOutline();
  renderBar();

  if (id) {
    const back = document.getElementById(id);
    if (back && back !== document.activeElement) {
      back.focus();
      if (start !== null && back.setSelectionRange) {
        try {
          back.setSelectionRange(start, end);
        } catch (error) {
          // A number or email input refuses a selection range. Focus is enough.
        }
      }
    }
  }
}

function renderRail() {
  const rail = el('rail');
  rail.replaceChildren();
  const home = document.createElement('button');
  home.type = 'button';
  home.className = 'section';
  home.setAttribute('aria-current', state.view === 'home' ? 'page' : 'false');
  home.append(node('span', 'name', homeView.label));
  home.onclick = () => goTo('home');
  rail.append(home);

  rail.append(node('div', 'railHead', 'Content'));
  for (const document_ of SCHEMA.documents) {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'section';
    const open = state.view === 'document' && state.file === document_.file;
    button.setAttribute('aria-current', open ? 'page' : 'false');
    button.append(node('span', 'name', document_.section));
    const pip = node('span', 'pip');
    pip.hidden = !dirty(document_.file);
    pip.title = 'Unsaved changes';
    if (!pip.hidden) button.setAttribute('aria-describedby', 'unsavedHint');
    button.append(pip);
    button.onclick = () => go(document_.file, []);
    rail.append(button);
  }
  let heading = null;
  for (const view of otherViews) {
    if (view.head !== heading) {
      rail.append(node('div', 'railHead', view.head));
      heading = view.head;
    }
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'section';
    button.setAttribute('aria-current', state.view === view.id ? 'page' : 'false');
    button.append(node('span', 'name', view.label));
    button.onclick = () => goTo(view.id);
    rail.append(button);
  }
  const hint = node('span', null, 'has unsaved changes');
  hint.id = 'unsavedHint';
  hint.hidden = true;
  rail.append(hint);
}

/// The path from the document down to whatever is open, as links back.
function crumbLinks() {
  const links = chainFor(state.file, state.path);
  const document_ = schemaFor(state.file);
  return links.filter((link, index) => {
    if (index === 0) return true;
    // A document whose whole content is one list does not need a crumb saying
    // so: "Work > Applications > Tripster" reads as one step too many.
    if (link.node.kind === 'list' && document_.fields.length === 1) return false;
    return true;
  });
}

function renderEditor() {
  const pane = el('editor');
  pane.replaceChildren();
  const entry = current();
  if (!entry) return;
  const document_ = schemaFor(state.file);
  const links = crumbLinks();
  const here = links[links.length - 1];

  const crumbs = node('ol', 'crumbs');
  links.forEach((link, index) => {
    const item = document.createElement('li');
    if (index === links.length - 1) {
      const last = node('span', 'here', link.label);
      last.setAttribute('aria-current', 'true');
      item.append(last);
    } else {
      const button = document.createElement('button');
      button.type = 'button';
      button.textContent = link.label;
      button.onclick = () => go(state.file, link.path);
      item.append(button);
    }
    crumbs.append(item);
  });
  const wrapper = node('nav');
  wrapper.setAttribute('aria-label', 'Breadcrumb');
  wrapper.append(crumbs);
  pane.append(wrapper);

  const head = node('div', 'panelHead');
  const titles = node('div', 'titles');
  titles.append(node('h2', null, here.label));
  if (here.root === true && document_.blurb) {
    titles.append(node('p', null, document_.blurb));
  }
  head.append(titles, languageTabs());
  pane.append(head);

  if (here.root === true && document_.warning) {
    pane.append(node('div', 'warn', document_.warning));
  }

  const chain = chainFor(state.file, state.path);
  const node_ = chain[chain.length - 1].node;
  const value = state.path.length === 0
    ? entry.draft
    : getIn(entry.draft, state.path);

  if (node_.kind === 'object') {
    for (const field of node_.fields) {
      pane.append(control(field, (value || {})[field.key], state.path.concat([field.key])));
    }
  } else {
    pane.append(control(node_, value, state.path));
  }
}

/// English or Arabic, stacked, switching every field at once.
function languageTabs() {
  const tabs = node('div', 'langTabs');
  tabs.setAttribute('role', 'tablist');
  tabs.setAttribute('aria-orientation', 'vertical');
  tabs.setAttribute('aria-label', 'Editing language');
  const languages = [
    {code: 'en', label: 'English'},
    {code: 'ar', label: 'Arabic'},
  ];
  for (const language of languages) {
    const button = document.createElement('button');
    button.type = 'button';
    button.setAttribute('role', 'tab');
    button.id = 'lang-' + language.code;
    button.setAttribute('aria-selected', String(state.lang === language.code));
    button.tabIndex = state.lang === language.code ? 0 : -1;
    button.textContent = language.label;
    // The preview renders one language at a time, and switching here is not an
    // edit, so nothing else would tell it. Without this the panel shows Arabic
    // and the preview keeps showing English.
    const switchTo = (code) => {
      state.lang = code;
      render();
      if (state.rightPane === 'preview') sendDraft();
    };
    button.onclick = () => switchTo(language.code);
    button.onkeydown = (event) => {
      if (event.key !== 'ArrowDown' && event.key !== 'ArrowUp') return;
      event.preventDefault();
      switchTo(state.lang === 'en' ? 'ar' : 'en');
      const moved = el('lang-' + state.lang);
      if (moved) moved.focus();
    };
    tabs.append(button);
  }
  return tabs;
}

/// The draft, read back as an outline.
///
/// Labelled as a draft outline and nothing else. It is not the site, it does
/// not use the site's components, and calling it a preview would be the exact
/// substitution the integration contract forbids.
function renderOutline() {
  const pane = el('outline');
  pane.replaceChildren();
  if (state.view !== 'document') {
    pane.append(node(
      'p',
      'note',
      'The outline follows whichever page you are editing.',
    ));
    return;
  }
  const entry = current();
  if (!entry) return;
  const document_ = schemaFor(state.file);
  const open = state.path.length > 0 ? state.path[0] : null;

  for (const field of document_.fields) {
    const value = entry.draft[field.key];
    const block = node('div', 'o' + (field.key === open ? ' on' : ''));
    block.append(node('span', 'k', field.label));
    const lines = outlineLines(field, value);
    if (lines.length === 0) {
      const line = node('span', 'v none', 'Not set');
      block.append(line);
    } else {
      for (const text of lines) {
        const line = node('span', 'v', text);
        // Each line decides its own direction from its own first letter. The
        // editing language does not: a biography with no Arabic is English
        // text, and laying it out right to left puts the full stop in front
        // of the sentence.
        line.dir = 'auto';
        block.append(line);
      }
    }
    pane.append(block);
  }
}

function outlineLines(field, value) {
  if (value === undefined || value === null) return [];
  if (field.kind === 'list') {
    if (!Array.isArray(value) || value.length === 0) return [];
    if (field.of.kind === 'object') {
      return value.map((item, index) => '- ' + titleOf(field.of, item, index));
    }
    return [value.map((item) => plainText(item)).join(', ')];
  }
  if (field.kind === 'object') {
    return field.fields
      .filter((child) => value[child.key] !== undefined && value[child.key] !== null)
      .map((child) => child.label + ': ' + plainText(value[child.key]));
  }
  if (field.kind === 'boolean') return [value === true ? 'Yes' : 'No'];
  const text = plainText(value);
  return text === '' ? [] : [text];
}

function renderBar() {
  // Publishing is per page, so on a section that is not a page there is
  // nothing here to press. Shown disabled rather than hidden, so the bar does
  // not move about as the owner walks around the panel.
  if (state.view !== 'document') {
    el('changeCount').textContent = state.view === 'media'
      ? 'Media is stored as soon as it is uploaded'
      : state.view === 'home'
        ? 'Counters only. Nothing here is published or collected.'
        : 'Nothing on this page is published';
    el('problemCount').hidden = true;
    for (const id of ['publish', 'discard', 'history', 'withdraw']) {
      el(id).disabled = true;
    }
    el('source').textContent = '';
    return;
  }
  const entry = current();
  const issues = state.issues.get(state.file);
  const changes = entry ? countChanges(entry) : 0;
  el('changeCount').textContent = changes === 0
    ? 'No changes on this page'
    : changes + (changes === 1 ? ' change' : ' changes') + ' not published';

  const problems = issues ? issues.errors.length : 0;
  const badge = el('problemCount');
  badge.hidden = problems === 0;
  badge.className = 'count bad';
  badge.textContent = problems + (problems === 1 ? ' problem' : ' problems');

  el('publish').disabled = changes === 0 || problems > 0;
  el('discard').disabled = changes === 0;
  el('history').disabled = false;
  el('withdraw').disabled = entry ? entry.source !== 'published' : true;
  el('source').textContent = entry
    ? (entry.source === 'published'
        ? 'Published copy' +
          (typeof entry.revision === 'number' ? ', revision ' + entry.revision : '')
        : 'Showing the copy shipped with the app')
    : '';
}

/// How many separate values differ from what the site shows.
function countChanges(entry) {
  if (JSON.stringify(entry.live) === JSON.stringify(entry.draft)) return 0;
  return countLeaves(entry.live, entry.draft);
}

function countLeaves(before, after) {
  if (JSON.stringify(before) === JSON.stringify(after)) return 0;
  const objects = before && after && typeof before === 'object' &&
    typeof after === 'object';
  if (!objects) return 1;
  const keys = new Set(Object.keys(before).concat(Object.keys(after)));
  let total = 0;
  for (const key of keys) total += countLeaves(before[key], after[key]);
  return total;
}

// --- the buttons at the bottom ---------------------------------------------

function openSheet(title, build) {
  const sheet = el('sheet');
  el('sheetTitle').textContent = title;
  const body = el('sheetBody');
  body.replaceChildren();
  build(body);
  sheet.showModal();
}

async function withdraw() {
  const section = schemaFor(state.file).section;
  if (!confirm('Withdraw ' + section + '? The site goes back to the copy shipped with the app.')) {
    return;
  }
  say('Withdrawing...');
  try {
    const response = await api('/v1/admin/content/' + state.file, {method: 'DELETE'});
    if (!response.ok) throw new Error('The withdrawal was refused');
    state.docs.delete(state.file);
    await ensure(state.file);
    await loadHeads();
    render();
    say('Withdrawn. The site uses the copy in its bundle.', 'good');
  } catch (error) {
    say(error.message, 'bad');
  }
}

// --- starting up -----------------------------------------------------------

async function unlock() {
  const secret = el('token').value.trim();
  if (!secret) return;
  say('Checking...');
  try {
    // What the browser keeps from here on is a session, not the credential
    // that can rewrite the site.
    await signInWith(secret);
    el('token').value = '';
    document.body.classList.remove('locked');
    el('gate').hidden = true;
    el('frame').classList.add('on');
    say('Loading your content...');
    // Every document, not just the one being opened: the drafts have to exist
    // for the rail to show which pages have unsaved work, and a stop pointing
    // at an application cannot be checked against a document nobody loaded.
    await Promise.all(SCHEMA.documents.map((entry) => ensure(entry.file)));
    // Which revision each page is at, so a publish can say what it was built
    // on and be told when that is no longer true.
    await loadHeads();
    const wanted = readHash();
    if (wanted && wanted.view === 'document') {
      state.file = wanted.file;
      state.path = wanted.path;
    } else if (wanted) {
      state.view = wanted.view;
    } else {
      state.view = 'home';
    }
    render();
    setRightPane(state.rightPane);
    say('');
    await check();
  } catch (error) {
    say(error.message, 'bad');
    el('token').focus();
  }
}

el('unlock').onclick = unlock;
el('token').onkeydown = (event) => {
  if (event.key === 'Enter') unlock();
};
el('publish').onclick = openReview;
el('discard').onclick = discardDraft;
el('history').onclick = openHistory;
el('withdraw').onclick = withdraw;
el('sheetClose').onclick = () => el('sheet').close();
el('previewToggle').onclick = () => {
  const showing = document.body.classList.toggle('showPreview');
  el('previewToggle').setAttribute('aria-pressed', String(showing));
};
el('showPreview').onclick = () => setRightPane('preview');
el('showOutline').onclick = () => setRightPane('outline');
el('previewRetry').onclick = () => mountPreview();

window.addEventListener('beforeunload', (event) => {
  if (!anyDirty()) return;
  event.preventDefault();
  event.returnValue = '';
});

el('reauthGo').onclick = finishReauth;
el('reauthPassword').onkeydown = (event) => {
  if (event.key === 'Enter') finishReauth();
};

/// Comes back to a reload with the session, if the browser kept one.
async function resume() {
  let remembered = null;
  try {
    remembered = sessionStorage.getItem('portfolio.admin.session');
  } catch (error) {
    remembered = null;
  }
  if (!remembered) return el('token').focus();
  state.token = remembered;
  try {
    const response = await fetch('/v1/admin/content', {
      headers: {authorization: 'Bearer ' + remembered},
    });
    if (!response.ok) throw new Error('gone');
    document.body.classList.remove('locked');
    el('gate').hidden = true;
    el('frame').classList.add('on');
    say('Loading your content...');
    await Promise.all(SCHEMA.documents.map((entry) => ensure(entry.file)));
    await loadHeads();
    const wanted = readHash();
    if (wanted && wanted.view === 'document') {
      state.file = wanted.file;
      state.path = wanted.path;
    } else if (wanted) {
      state.view = wanted.view;
    } else {
      state.view = 'home';
    }
    render();
    setRightPane(state.rightPane);
    say('');
    await check();
  } catch (error) {
    // The session did not survive. Back to the gate, with nothing to lose:
    // drafts only exist once the panel is open.
    state.token = '';
    try {
      sessionStorage.removeItem('portfolio.admin.session');
    } catch (removeError) {
      // Nothing to clear.
    }
    el('token').focus();
  }
}

resume();
`;

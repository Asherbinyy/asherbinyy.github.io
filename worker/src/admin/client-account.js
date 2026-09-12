/**
 * Signing in, signing out, changing the password, and coming back after the
 * session has ended.
 *
 * What this replaces: the panel asked for `ADMIN_TOKEN` -- the deployment
 * secret that can rewrite everything the site says -- and kept it in the tab
 * for as long as the tab was open. There was no way to sign out, no way to
 * change it without `wrangler`, and nothing that could be revoked (A-F8).
 *
 * Now the secret is exchanged once for a session that expires and can be
 * ended, the password can be changed from in here, and a session ending
 * mid-edit asks for the password again instead of throwing the drafts away.
 *
 * No Cloudflare account credential ever reaches this page. The deployment
 * secret still works as the way back in if the password is forgotten, which is
 * also why an unreachable password store cannot lock the owner out.
 */

export const clientAccount = `
/// Exchanges a password or the deployment secret for a session.
async function signInWith(secret) {
  const response = await fetch('/v1/admin/session', {
    method: 'POST',
    headers: {'content-type': 'application/json'},
    body: JSON.stringify({password: secret}),
  });
  const body = await response.json().catch(() => ({}));
  if (response.status === 429) {
    throw new Error('Too many wrong attempts; wait an hour and try again');
  }
  if (!response.ok) throw new Error(body.error || 'That was not right');
  state.token = body.token;
  state.expires = body.expires;
  try {
    sessionStorage.setItem('portfolio.admin.session', body.token);
  } catch (error) {
    // A browser refusing storage is not a reason to refuse to work; it only
    // means a reload will ask for the password again.
  }
  return body;
}

/// Asks for the password again, without losing anything.
///
/// The drafts are in memory and stay there. Sending the owner back to the
/// sign-in page and clearing them would turn a twelve-hour timeout into lost
/// work, which is the thing an editor must never do.
function askAgain() {
  if (el('reauth').open) return;
  el('reauthError').textContent = '';
  el('reauthPassword').value = '';
  el('reauth').showModal();
  el('reauthPassword').focus();
}

async function finishReauth() {
  const secret = el('reauthPassword').value;
  if (!secret) return;
  el('reauthError').textContent = '';
  try {
    await signInWith(secret);
    el('reauth').close();
    say('Signed back in; your drafts are as you left them', 'good');
    await loadHeads();
    render();
  } catch (error) {
    el('reauthError').textContent = error.message;
  }
}

async function signOut() {
  if (anyDirty() &&
      !confirm('You have unpublished changes. Signing out loses them. Sign out?')) {
    return;
  }
  try {
    await api('/v1/admin/session', {method: 'DELETE'});
  } catch (error) {
    // Ending a session that the server has already forgotten is a success as
    // far as the person pressing the button is concerned.
  }
  try {
    sessionStorage.removeItem('portfolio.admin.session');
  } catch (error) {
    // Nothing to clear.
  }
  location.reload();
}

// --- the account section ---------------------------------------------------

async function renderAccount() {
  const pane = el('editor');
  pane.replaceChildren();

  const crumbs = node('ol', 'crumbs');
  const here = document.createElement('li');
  const label = node('span', 'here', 'Account');
  label.setAttribute('aria-current', 'true');
  here.append(label);
  crumbs.append(here);
  const wrapper = node('nav');
  wrapper.setAttribute('aria-label', 'Breadcrumb');
  wrapper.append(crumbs);
  pane.append(wrapper);

  const head = node('div', 'panelHead');
  const titles = node('div', 'titles');
  titles.append(node('h2', null, 'Account'));
  titles.append(node('p', null, 'How you get into this panel, and how you stop.'));
  head.append(titles);
  pane.append(head);

  if (state.account === null) {
    pane.append(node('p', 'note', 'Reading...'));
    await loadAccount();
    if (state.view === 'account') render();
    return;
  }

  const standing = node('div', 'group');
  standing.append(node('h3', null, 'This session'));
  standing.append(node(
    'p',
    'note',
    state.account.kind === 'recovery'
      ? 'You are signed in with the deployment secret, which is the way back in when the password is forgotten. It does not expire and cannot be ended from here.'
      : 'Signed in with a session. It ends by itself after twelve hours unused, and after seven days however often it is used.',
  ));
  if (state.expires) {
    standing.append(node('p', 'help', 'This one ends ' + state.expires));
  }
  standing.append(node(
    'p',
    'note',
    state.account.passwordSet
      ? 'A password is set.'
      : 'No password is set yet. Until one is, the deployment secret is the only way in.',
  ));
  const out = document.createElement('button');
  out.type = 'button';
  out.className = 'small danger';
  out.textContent = 'Sign out';
  out.onclick = signOut;
  standing.append(out);
  pane.append(standing);

  pane.append(passwordForm());

  const safety = node('div', 'group');
  safety.append(node('h3', null, 'What is not kept here'));
  safety.append(node(
    'p',
    'note',
    'This page never receives a Cloudflare account credential, and it never ' +
      'will. Changing the password changes a value stored beside your content; ' +
      'it does not touch the hosting account, and nothing here can.',
  ));
  safety.append(node(
    'p',
    'note',
    'Changing the password signs every other session out, including one left ' +
      'open on a machine you no longer have.',
  ));
  pane.append(safety);
}

function passwordForm() {
  const group = node('div', 'group');
  group.append(node(
    'h3',
    null,
    state.account.passwordSet ? 'Change the password' : 'Set a password',
  ));

  const currentField = node('div', 'field');
  const currentLabel = node(
    'label',
    null,
    state.account.passwordSet
      ? 'Current password, or the deployment secret'
      : 'The deployment secret',
  );
  currentLabel.htmlFor = 'currentPassword';
  const current = document.createElement('input');
  current.type = 'password';
  current.id = 'currentPassword';
  current.autocomplete = 'current-password';
  currentField.append(currentLabel, current);
  group.append(currentField);

  const nextField = node('div', 'field');
  const nextLabel = node('label', null, 'New password');
  nextLabel.htmlFor = 'newPassword';
  const next = document.createElement('input');
  next.type = 'password';
  next.id = 'newPassword';
  next.autocomplete = 'new-password';
  nextField.append(nextLabel, next);
  nextField.append(node(
    'p',
    'help',
    'At least twelve characters. Length is what protects this one: how hard ' +
      'the password can be stretched before storing is limited by how much ' +
      'processor time the Worker may spend on a single request.',
  ));
  group.append(nextField);

  const problem = node('p', 'issue');
  problem.hidden = true;
  group.append(problem);

  const save = document.createElement('button');
  save.type = 'button';
  save.className = 'small primary';
  save.textContent = state.account.passwordSet ? 'Change it' : 'Set it';
  save.onclick = async () => {
    problem.hidden = true;
    if (next.value.length < 12) {
      problem.hidden = false;
      problem.textContent = 'A password needs at least twelve characters';
      return;
    }
    say('Changing the password...');
    try {
      const response = await api('/v1/admin/password', {
        method: 'POST',
        headers: {'content-type': 'application/json'},
        body: JSON.stringify({current: current.value, next: next.value}),
      });
      const body = await response.json();
      if (!response.ok) throw new Error(body.error || 'That was refused');
      // The change ended every session, this one included, and handed back a
      // replacement. Taking it is what keeps the owner signed in.
      state.token = body.token;
      state.expires = body.expires;
      try {
        sessionStorage.setItem('portfolio.admin.session', body.token);
      } catch (error) {
        // See signInWith.
      }
      state.account = null;
      render();
      say('Password changed. Every other session has been signed out.', 'good');
    } catch (error) {
      problem.hidden = false;
      problem.textContent = error.message;
      say(error.message, 'bad');
    }
  };
  group.append(save);
  return group;
}

async function loadAccount() {
  try {
    const response = await api('/v1/admin/session');
    const body = await response.json();
    if (!response.ok) throw new Error(body.error || 'Could not read the session');
    state.account = body;
  } catch (error) {
    state.account = {kind: 'unknown', passwordSet: false, recovery: false};
  }
}
`;

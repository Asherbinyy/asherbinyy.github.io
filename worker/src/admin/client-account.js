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
  if (!response.ok) throw new Error(body.error || 'Password or recovery token was not accepted');
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
    say('Signed in. Your drafts are preserved.', 'good');
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
  titles.append(node('p', null, 'Manage your password and active sessions.'));
  head.append(titles);
  pane.append(head);

  if (state.accountError) {
    pane.append(node('p', 'issue', state.accountError));
    const retry = node('button', 'small', 'Retry account details');
    retry.onclick = () => { state.accountError = ''; state.account = null; render(); };
    pane.append(retry); return;
  }
  if (state.account === null) {
    pane.append(node('p', 'note', 'Loading account details…'));
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
      ? 'Signed in with a recovery token. Set an admin password below.'
      : 'Signed in. Sign out to end this session on this device.',
  ));
  if (state.account.expires) {
    const expires = new Date(state.account.expires).toLocaleString('en-GB', {dateStyle: 'medium', timeStyle: 'short', timeZone: 'UTC'});
    standing.append(node('p', 'help', 'Session expiry: ' + expires + ' UTC. Activity may extend this.'));
  }
  standing.append(node(
    'p',
    'note',
    state.account.passwordSet
      ? 'A password is set.'
      : 'No admin password is set. Use your recovery token to set one.',
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
  safety.append(node('h3', null, 'Password changes'));
  safety.append(node(
    'p',
    'note',
    'This changes your portfolio admin password.',
  ));
  safety.append(node(
    'p',
    'note',
    'Changing the password signs out all other sessions.',
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
      ? 'Current password or recovery token'
      : 'Recovery token',
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
    'Use at least 12 characters.',
  ));
  group.append(nextField);

  const problem = node('p', 'issue');
  problem.hidden = true;
  group.append(problem);

  const save = document.createElement('button');
  save.type = 'button';
  save.className = 'small primary';
  save.textContent = state.account.passwordSet ? 'Change password' : 'Set password';
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
    state.accountError = '';
  } catch (error) {
    state.account = null;
    state.accountError = error.message;
  }
}
`;

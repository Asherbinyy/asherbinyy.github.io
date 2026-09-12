/**
 * Reviewing, publishing, going back, and what happens when two tabs disagree.
 *
 * The panel this replaces had a Review button that put a JSON diff in an
 * `alert()`, asked for a source in a `prompt()`, and published whatever was in
 * the single draft with no idea what revision it had started from. Two tabs
 * open on the same page meant the second one to press Publish won, silently.
 *
 * What is here now: a review sheet showing every value that would change, the
 * claims that need a source with somewhere to type it, a publish that declares
 * which revision it was built on, a conflict that offers a way out rather than
 * an error, and a history that can be gone back to.
 *
 * What is deliberately *not* here: any claim that publishing updates the whole
 * site. It updates the content endpoint the app reads. The CV, the Brief and
 * the page metadata are generated separately and still come from the bundle,
 * and the sheet says so, because "Published" over a half-updated site is the
 * defect in `20-APP-ADMIN-CONTRACT.md` under Publication and revisions.
 */

export const clientPublish = `
/// What one changed value looks like in the review.
function changeRow(change) {
  const block = node('div', 'group');
  block.append(node('h3', null, change.path));
  block.append(node('p', 'diff removed', '- ' + JSON.stringify(change.before)));
  block.append(node('p', 'diff added', '+ ' + JSON.stringify(change.after)));
  return block;
}

/// Asks the Worker what would change, then shows it with a way to go ahead.
async function openReview() {
  const file = state.file;
  const entry = state.docs.get(file);
  if (!entry) return;
  if (countChanges(entry) === 0) return say('Nothing has changed on this page');
  say('Checking the draft...');
  let review;
  try {
    const response = await api('/v1/admin/review', {
      method: 'POST',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify({
        file: file,
        document: entry.draft,
        baseline: entry.live,
        references: knownReferences(file),
      }),
    });
    review = await response.json();
    if (!response.ok) throw new Error(review.error || 'Could not check the draft');
  } catch (error) {
    return say(error.message, 'bad');
  }
  render();
  say('');

  openSheet('Review ' + schemaFor(file).section, (into) => {
    into.append(node(
      'p',
      'note',
      'Against what the site is showing now. Nothing has been published yet.',
    ));

    if (review.errors.length > 0) {
      const stop = node('div', 'warn');
      stop.append(node('p', null, 'This cannot be published until these are fixed:'));
      for (const issue of review.errors) {
        stop.append(node('p', 'issue', issue.path + ': ' + issue.message));
      }
      into.append(stop);
    }
    for (const issue of review.warnings) {
      into.append(node('p', 'issue warn', issue.path + ': ' + issue.message));
    }

    into.append(node(
      'span',
      'fieldLabel',
      'Changes \\u2014 ' + review.changes.length,
    ));
    for (const change of review.changes) into.append(changeRow(change));

    let source = null;
    if (review.sourceRequired) {
      const asked = node('div', 'group');
      asked.append(node('h3', null, 'These are claims about you'));
      if (review.sourceReason === 'first-publish') {
        asked.append(node(
          'p',
          'note',
          'Nothing has been published for this page yet, so every figure on ' +
            'it is one the site has never been given a source for.',
        ));
      }
      // What changed, where the Worker can see a previous version; otherwise
      // every figure in the document, which is what it is actually asking
      // about.
      const listed = review.claims.length > 0
        ? review.claims.map((claim) =>
            claim.label + ': ' + JSON.stringify(claim.was) +
              ' becomes ' + JSON.stringify(claim.value))
        : review.sourceClaims.map((claim) =>
            claim.label + ': ' + JSON.stringify(claim.value));
      for (const line of listed) asked.append(node('p', 'note', line));
      const field = node('div', 'field');
      const label = node('label', null, 'Where does the new figure come from?');
      label.htmlFor = 'sourceNote';
      source = document.createElement('textarea');
      source.id = 'sourceNote';
      source.placeholder = 'A transcript, a payslip, a store listing.';
      field.append(label, source);
      field.append(node(
        'p',
        'help',
        'Kept beside the change, not inside the content. The Worker refuses the publish without it.',
      ));
      asked.append(field);
      into.append(asked);
    }

    into.append(node(
      'p',
      'help',
      'Publishing changes what the app reads. The CV, the Brief and the page ' +
        'metadata are generated separately and are not updated by this.',
    ));

    const actions = node('div', 'listFoot');
    const cancel = document.createElement('button');
    cancel.type = 'button';
    cancel.textContent = 'Cancel';
    cancel.onclick = () => {
      el('sheet').close();
      say('Nothing was published; your draft is untouched');
    };
    const go = document.createElement('button');
    go.type = 'button';
    go.className = 'primary';
    go.textContent = 'Publish ' + schemaFor(file).section;
    go.disabled = review.errors.length > 0;
    go.onclick = () => {
      const note = source ? source.value.trim() : '';
      if (source && note === '') {
        say('A claim cannot be published without a source', 'bad');
        source.focus();
        return;
      }
      el('sheet').close();
      publishNow(note, file);
    };
    actions.append(cancel, go);
    into.append(actions);
  });
}

/// Sends the draft, saying which revision it was built on.
async function publishNow(note, forFile) {
  // The document this publish is for, and the exact bytes going out. Both
  // captured before the request, because by the time it answers the owner may
  // have opened something else or typed something new -- and acknowledging
  // "published" against a draft that has moved on marks unsaved work as saved
  // (AR-3).
  const file = forFile || state.file;
  const entry = state.docs.get(file);
  if (!entry) return;
  const submitted = JSON.parse(JSON.stringify(entry.draft));
  const base = entry.revision;
  say('Publishing ' + schemaFor(file).section + '...');
  const headers = {
    'content-type': 'application/json',
    'x-change-note': encodeURIComponent(note || ''),
  };
  if (typeof base === 'number') headers['x-base-revision'] = String(base);
  try {
    const response = await api('/v1/admin/content/' + file, {
      method: 'PUT',
      headers: headers,
      body: JSON.stringify(submitted),
    });
    const body = await response.json();
    if (response.status === 409) return showConflict(body, file);
    if (!response.ok) {
      if (body.claims) {
        say('The Worker refused it: a claim needs a source', 'bad');
        return;
      }
      throw new Error(body.error || 'The publish was refused');
    }
    // What is live is what was sent, not what the draft says now. If the owner
    // kept typing while this was in flight, the page is still dirty and the
    // bar keeps saying so.
    entry.live = submitted;
    entry.source = 'published';
    entry.revision = body.revision;
    entry.diverged = null;
    render();
    const still = countChanges(entry);
    say(
      'Published as revision ' + body.revision +
        (still > 0 ? '. You have since made ' + still + ' more change' +
          (still === 1 ? '' : 's') + '.' : ''),
      'good',
    );
  } catch (error) {
    say(error.message, 'bad');
  }
}

/// Someone else got there first.
///
/// Both ways out are offered by name, because the one thing that must not
/// happen is the panel choosing for him and losing an afternoon either way.
function showConflict(body, forFile) {
  const file = forFile || state.file;
  const entry = state.docs.get(file);
  const theirs = body.document;
  say('This page changed while you were editing it', 'bad');
  openSheet('Someone else changed this page', (into) => {
    into.append(node(
      'p',
      'note',
      'You started from revision ' + body.expected + '. The site is now on ' +
        body.current + (body.changedAt ? ', changed ' + body.changedAt : '') +
        '. Nothing you did has been lost, and nothing has been published.',
    ));

    const between = differencesFor(theirs, entry.draft);
    into.append(node(
      'span',
      'fieldLabel',
      'Where yours and theirs differ \\u2014 ' + between.length,
    ));
    for (const change of between) {
      const block = node('div', 'group');
      block.append(node('h3', null, change.path));
      block.append(node('p', 'diff removed', 'theirs: ' + JSON.stringify(change.before)));
      block.append(node('p', 'diff added', 'yours:  ' + JSON.stringify(change.after)));
      into.append(block);
    }

    const actions = node('div', 'listFoot');
    const takeTheirs = document.createElement('button');
    takeTheirs.type = 'button';
    takeTheirs.className = 'danger';
    takeTheirs.textContent = 'Throw mine away';
    takeTheirs.onclick = () => {
      el('sheet').close();
      entry.live = theirs;
      entry.draft = JSON.parse(JSON.stringify(theirs));
      entry.revision = body.current;
      render();
      check();
      say('Your draft was discarded; this is what the site shows');
    };
    const keepMine = document.createElement('button');
    keepMine.type = 'button';
    keepMine.className = 'primary';
    keepMine.textContent = 'Keep mine and review again';
    keepMine.onclick = () => {
      el('sheet').close();
      // Rebased, not published: the draft is now measured against what is
      // actually there, and the owner reviews the real difference before it
      // goes anywhere.
      entry.live = theirs;
      entry.revision = body.current;
      render();
      check();
      say('Now comparing against their version. Review before publishing.');
    };
    actions.append(takeTheirs, keepMine);
    into.append(actions);
  });
}

/// A local diff, for showing two drafts against each other.
///
/// The Worker owns the diff that decides anything. This one only ever draws a
/// conflict sheet, where both sides are already in the browser.
function differencesFor(before, after, path) {
  const at = path || [];
  if (JSON.stringify(before) === JSON.stringify(after)) return [];
  const objects = before !== null && after !== null &&
    typeof before === 'object' && typeof after === 'object';
  if (!objects) {
    return [{
      path: at.join('.'),
      before: before === undefined ? null : before,
      after: after === undefined ? null : after,
    }];
  }
  const keys = new Set(Object.keys(before).concat(Object.keys(after)));
  const out = [];
  for (const key of keys) {
    out.push(...differencesFor(before[key], after[key], at.concat([key])));
  }
  return out;
}

/// Throws away the draft and starts again from what the site shows.
function discardDraft() {
  const file = state.file;
  const entry = state.docs.get(file);
  if (!entry) return;
  if (countChanges(entry) === 0) return say('Nothing to discard');
  const section = schemaFor(file).section;
  if (!confirm('Throw away your unpublished changes to ' + section +
      '? This cannot be undone.')) {
    return;
  }
  entry.draft = JSON.parse(JSON.stringify(entry.live));
  render();
  check();
  say('Back to what the site is showing');
}

/// Every revision of this page, and a way back to one.
async function openHistory() {
  const file = state.file;
  say('Reading the history...');
  let body;
  try {
    const response = await api('/v1/admin/content/' + file + '/revisions');
    body = await response.json();
    if (!response.ok) throw new Error(body.error || 'Could not read the history');
  } catch (error) {
    return say(error.message, 'bad');
  }
  say('');
  openSheet('History of ' + schemaFor(file).section, (into) => {
    if (body.revisions.length === 0) {
      into.append(node('p', 'note', 'This page has never been published.'));
      return;
    }
    into.append(node(
      'p',
      'note',
      'Going back publishes that version again as a new revision, so nothing ' +
        'in here is ever overwritten.',
    ));
    for (const entry of body.revisions) {
      const block = node('div', 'group');
      const title = 'Revision ' + entry.revision +
        (entry.revision === body.current ? ' (current)' : '') +
        (entry.withdrawal ? ' \\u2014 withdrawn' : '');
      block.append(node('h3', null, title));
      block.append(node('p', 'note', entry.at));
      if (entry.note) block.append(node('p', null, entry.note));
      if (entry.claims.length > 0) {
        block.append(node('p', 'help', 'Figures: ' + entry.claims.join(', ')));
      }
      if (!entry.withdrawal && entry.revision !== body.current) {
        const back = document.createElement('button');
        back.type = 'button';
        back.className = 'small';
        back.textContent = 'Go back to this';
        back.onclick = () => rollTo(entry.revision);
        block.append(back);
      }
      into.append(block);
    }
  });
}

async function rollTo(revision) {
  const file = state.file;
  const entry = state.docs.get(file);
  if (!entry) return;
  const unsaved = countChanges(entry) > 0;
  if (!confirm('Put revision ' + revision + ' back on the site?' +
      (unsaved ? ' Your unpublished changes to this page will be lost.' : ''))) {
    return;
  }
  el('sheet').close();
  say('Going back to revision ' + revision + '...');
  try {
    const response = await api(
      '/v1/admin/content/' + file + '/rollback',
      {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          // The same precondition a publish carries. Putting an old revision
          // back on top of something this panel has not seen is still an
          // overwrite (AR-5).
          'x-base-revision': String(entry.revision),
        },
        body: JSON.stringify({revision: revision}),
      },
    );
    if (response.status === 409) {
      const clash = await response.json();
      return showConflict(clash, file);
    }
    const body = await response.json();
    if (!response.ok) throw new Error(body.error || 'That could not be put back');
    await reload(file);
    render();
    check();
    say('Revision ' + revision + ' is back, as revision ' + body.revision, 'good');
  } catch (error) {
    say(error.message, 'bad');
  }
}

/// Checks whether anything has moved, without moving anything here.
///
/// This used to write the remote revision straight onto every loaded entry
/// (AR-4). A draft built on revision 1, refreshed after somebody published
/// revision 2, came away believing it was based on 2 -- while its baseline and
/// its draft were untouched. Its next publish carried the wrong base, matched,
/// and overwrote a revision nobody here had ever seen.
///
/// A document and the revision it is are one fact. A clean page is reloaded so
/// both move together; a page with unpublished work keeps its base and is told
/// that someone else has published.
async function loadHeads() {
  let body;
  try {
    const response = await api('/v1/admin/content');
    body = await response.json();
    if (!response.ok) return;
  } catch (error) {
    // The panel works without it; publishing simply will not declare a base.
    return;
  }
  state.atomicStore = body.atomic === true;

  for (const document_ of SCHEMA.documents) {
    const file = document_.file;
    const entry = state.docs.get(file);
    if (!entry) continue;
    const remote = (body.heads || {})[file] ?? 0;
    if (remote === entry.revision) {
      entry.diverged = null;
      continue;
    }
    if (countChanges(entry) > 0) {
      // Reported, not applied. Publishing will be refused with a conflict the
      // owner can look at, and the draft survives.
      entry.diverged = remote;
      continue;
    }
    await reload(file);
  }
}

/// Replaces a clean page with what the site is showing, and its revision.
async function reload(file) {
  const held = state.docs.get(file);
  if (!held) return;
  state.docs.delete(file);
  await ensure(file);
  state.issues.delete(file);
}
`;

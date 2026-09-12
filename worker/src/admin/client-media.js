/**
 * The media library, and the control that puts a file into a field.
 *
 * Before this there was one file picker, attached to any field whose key
 * happened to match a regular expression, with no progress, no way to see what
 * had already been uploaded, no way to reuse it, and no way to find out what
 * an image was being used by before deleting it (A-F4).
 *
 * Two things live here: a section listing everything stored, with what refers
 * to it; and the per-field control, which can upload, pick from the library,
 * or clear the field.
 */

export const clientMedia = `
/// Bytes, as a person reads them.
function readableSize(bytes) {
  if (typeof bytes !== 'number') return '';
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1024 * 1024) return Math.round(bytes / 1024) + ' KB';
  return (Math.round((bytes / (1024 * 1024)) * 10) / 10) + ' MB';
}

function describeMedia(entry) {
  const parts = [];
  if (entry.kind === 'audio') {
    parts.push(typeof entry.seconds === 'number'
      ? entry.seconds + 's'
      : 'length unknown');
  } else if (entry.width) {
    parts.push(entry.width + ' by ' + entry.height);
  }
  parts.push(readableSize(entry.bytes));
  parts.push((entry.type || '').replace(/^(image|audio)\\//, ''));
  return parts.filter(Boolean).join(' \\u00B7 ');
}

/// A thumbnail for a picture, a player for a recording.
function mediaFigure(entry, small) {
  if (entry.kind === 'audio') {
    const player = document.createElement('audio');
    player.controls = true;
    player.preload = 'none';
    player.src = entry.url;
    player.style.width = small ? '160px' : '100%';
    player.setAttribute('aria-label', 'Recording ' + entry.id.slice(0, 8));
    return player;
  }
  const image = document.createElement('img');
  image.src = entry.url;
  image.alt = '';
  image.loading = 'lazy';
  image.className = 'mediaThumb' + (small ? ' small' : '');
  return image;
}

// --- the library section ---------------------------------------------------

async function renderLibrary() {
  const pane = el('editor');
  pane.replaceChildren();

  const crumbs = node('ol', 'crumbs');
  const here = document.createElement('li');
  const label = node('span', 'here', 'Media');
  label.setAttribute('aria-current', 'true');
  here.append(label);
  crumbs.append(here);
  const wrapper = node('nav');
  wrapper.setAttribute('aria-label', 'Breadcrumb');
  wrapper.append(crumbs);
  pane.append(wrapper);

  const head = node('div', 'panelHead');
  const titles = node('div', 'titles');
  titles.append(node('h2', null, 'Media'));
  titles.append(node(
    'p',
    null,
    'Everything you have uploaded. A file is stored under a fingerprint of its own contents, so uploading the same picture twice keeps one copy.',
  ));
  head.append(titles);
  pane.append(head);

  if (state.media === null) {
    pane.append(node('p', 'note', 'Reading the library...'));
    await loadMedia();
    if (state.view === 'media') render();
    return;
  }
  if (state.mediaError) {
    pane.append(node('div', 'warn', state.mediaError));
  }

  pane.append(uploadRow('image', 'Upload a picture'));
  pane.append(uploadRow('audio', 'Upload a recording'));

  const items = state.media.slice();
  if (items.length === 0) {
    const rows = node('div', 'rows');
    rows.append(node('div', 'empty', 'Nothing uploaded yet.'));
    pane.append(rows);
    return;
  }

  pane.append(node('span', 'fieldLabel', 'Stored files \\u2014 ' + items.length));
  for (const entry of items) {
    pane.append(mediaCard(entry));
  }
}

/// One stored file: what it is, what is using it, and how to be rid of it.
function mediaCard(entry) {
  const card = node('div', 'group mediaCard');
  const figure = node('div', 'mediaFigure');
  figure.append(mediaFigure(entry, false));
  const body = node('div', 'mediaBody');

  body.append(node('h3', null, describeMedia(entry)));

  const reference = node('p', 'help mono');
  reference.textContent = entry.url;
  body.append(reference);

  const uses = usesOf(entry.url);
  if (uses.length === 0) {
    body.append(node('p', 'note', 'Nothing is using this.'));
  } else {
    const list = node('p', 'note');
    list.textContent = 'Used by ' +
      uses.map((use) => use.section + ' \\u2192 ' + use.path).join(', ');
    body.append(list);
  }

  const tools = node('div', 'listFoot');
  const copy = document.createElement('button');
  copy.type = 'button';
  copy.className = 'small';
  copy.textContent = 'Copy reference';
  copy.onclick = async () => {
    try {
      await navigator.clipboard.writeText(entry.url);
      say('Copied ' + entry.url, 'good');
    } catch (error) {
      say('Could not copy; the reference is ' + entry.url, 'bad');
    }
  };
  const remove = document.createElement('button');
  remove.type = 'button';
  remove.className = 'small danger';
  remove.textContent = 'Delete';
  remove.onclick = () => deleteMedia(entry, uses);
  tools.append(copy, remove);
  body.append(tools);

  card.append(figure, body);
  return card;
}

async function deleteMedia(entry, uses) {
  const warning = uses.length === 0
    ? 'Delete this file? It cannot be recovered.'
    : 'This is still used by ' +
      uses.map((use) => use.section + ' \\u2192 ' + use.path).join(', ') +
      '.\\n\\nDeleting it leaves those pointing at nothing. Delete anyway?';
  if (!confirm(warning)) return;
  say('Deleting...');
  try {
    const response = await api('/v1/admin/media/' + entry.id, {method: 'DELETE'});
    if (!response.ok) throw new Error('The file could not be deleted');
    state.media = null;
    say('Deleted', 'good');
    render();
  } catch (error) {
    say(error.message, 'bad');
  }
}

/// An upload control with a real progress bar and a way to try again.
function uploadRow(kind, label) {
  const wrap = node('div', 'field');
  const id = 'upload-' + kind;
  const picker = document.createElement('input');
  picker.type = 'file';
  picker.id = id;
  picker.className = 'filePicker';
  picker.accept = kind === 'audio'
    ? 'audio/mpeg,audio/mp4,audio/wav,audio/ogg'
    : 'image/png,image/jpeg,image/webp';
  // The same styled control the fields use. A browser's default file input
  // beside a styled one reads as two different tools.
  const trigger = node('label', 'buttonish', label);
  trigger.htmlFor = id;
  wrap.append(trigger, picker);

  const progress = node('div', 'progress');
  progress.hidden = true;
  const bar = node('div', 'bar');
  progress.append(bar);
  const line = node('p', 'help');
  line.hidden = true;
  wrap.append(progress, line);

  let lastFile = null;
  const retry = document.createElement('button');
  retry.type = 'button';
  retry.className = 'small';
  retry.textContent = 'Try again';
  retry.hidden = true;
  wrap.append(retry);

  const run = async (file) => {
    lastFile = file;
    retry.hidden = true;
    progress.hidden = false;
    line.hidden = false;
    bar.style.width = '0%';
    line.textContent = 'Sending ' + file.name + '...';
    try {
      const body = await sendFile(file, kind, (fraction) => {
        bar.style.width = Math.round(fraction * 100) + '%';
      });
      bar.style.width = '100%';
      line.textContent = 'Uploaded ' + file.name;
      say('Uploaded ' + file.name, 'good');
      await loadMedia();
      render();
      return body;
    } catch (error) {
      progress.hidden = true;
      line.textContent = error.message;
      retry.hidden = false;
      say(error.message, 'bad');
      return null;
    }
  };

  picker.onchange = () => {
    const chosen = picker.files && picker.files[0];
    if (chosen) run(chosen);
  };
  retry.onclick = () => {
    if (lastFile) run(lastFile);
  };
  return wrap;
}

// --- putting a file into a field -------------------------------------------

/// Offers the library, filtered to what this field can hold.
function openMediaPicker(kind, onChosen) {
  const show = () => {
    openSheet('Choose from the library', (into) => {
      const available = (state.media || []).filter((entry) => entry.kind === kind);
      if (available.length === 0) {
        into.append(node(
          'p',
          'note',
          'Nothing of that kind has been uploaded yet. Upload one from the Media section, or from this field.',
        ));
        return;
      }
      const grid = node('div', 'mediaGrid');
      for (const entry of available) {
        const choice = document.createElement('button');
        choice.type = 'button';
        choice.className = 'mediaChoice';
        choice.append(mediaFigure(entry, true));
        choice.append(node('span', 'note', describeMedia(entry)));
        choice.onclick = () => {
          el('sheet').close();
          onChosen(entry.url);
        };
        grid.append(choice);
      }
      into.append(grid);
    });
  };
  if (state.media === null) {
    loadMedia().then(show);
    return;
  }
  show();
}
`;

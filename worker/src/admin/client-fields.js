/**
 * One control per kind of field the schema can describe.
 *
 * The panel this replaces chose its control by looking at the JavaScript type
 * of the value it found, and guessed at an uploader by running a regular
 * expression over the last word of the key (A-F4). So `portrait.src` got a
 * text box, an app that had never had a screenshot had nowhere to put one,
 * and a URL and a caption were the same control.
 *
 * Here the schema says what a field is, so a link is validated as a link, a
 * month is a month picker, a country offers the codes the site has flags for,
 * and an image field has an uploader whether or not the document currently
 * holds a path.
 *
 * Every control is labelled with a real `for`/`id` pair. The old panel drew a
 * `<label>` next to an input with no association at all (A-F5), which reads to
 * a screen reader as an unlabelled box.
 */

export const clientFields = `
/// A stable id for a control, so focus survives a re-render.
function idFor(path) {
  return 'f-' + path.join('-').replace(/[^A-Za-z0-9_-]/g, '_');
}

function pathText(path) {
  return path.join('.');
}

function node(tag, className, text) {
  const made = document.createElement(tag);
  if (className) made.className = className;
  if (text !== undefined) made.textContent = text;
  return made;
}

/// The label, its required marker, and an honest badge when the site does not
/// read this field yet.
function labelFor(field, id) {
  const label = node('label');
  label.htmlFor = id;
  label.append(document.createTextNode(field.label));
  if (field.required === true) {
    const star = node('span', 'required', ' *');
    star.title = 'Required';
    label.append(star);
  }
  if (field.consumer === 'pending' || field.consumer === 'withdrawn') {
    label.append(document.createTextNode(' '));
    label.append(node(
      'span',
      'pending',
      field.consumer === 'pending' ? 'not on the site yet' : 'no longer shown',
    ));
  }
  return label;
}

function decorate(wrap, field, path) {
  if (field.help) wrap.append(node('p', 'help', field.help));
  for (const issue of issuesAt(pathText(path))) {
    wrap.append(node('p', 'issue' + (issue.kind === 'warn' ? ' warn' : ''), issue.message));
  }
  return wrap;
}

function markInvalid(input, path) {
  const bad = issuesAt(pathText(path)).some((issue) => issue.kind === 'error');
  if (bad) input.setAttribute('aria-invalid', 'true');
  return input;
}

// --- controls --------------------------------------------------------------

const inputTypes = {
  url: 'url',
  email: 'email',
  tel: 'tel',
  month: 'month',
  number: 'number',
};

function textControl(field, value, path) {
  const wrap = node('div', 'field');
  const id = idFor(path);
  const long = field.kind === 'paragraph' || field.kind === 'localizedParagraph';
  const input = document.createElement(long ? 'textarea' : 'input');
  if (!long) input.type = inputTypes[field.kind] || 'text';
  input.id = id;
  input.value = value === undefined || value === null ? '' : String(value);
  if (field.kind === 'id') {
    input.inputMode = 'latin';
    input.spellcheck = false;
  }
  if (field.kind === 'number') {
    if (typeof field.min === 'number') input.min = String(field.min);
    if (typeof field.max === 'number') input.max = String(field.max);
    input.step = 'any';
  }
  // Read from a file rather than typed. A length the owner could disagree with
  // the recording about is worse than no length at all.
  if (field.derived === true) {
    input.readOnly = true;
    input.tabIndex = -1;
    if (input.value === '') input.placeholder = 'Set when a file is uploaded';
  } else {
    input.oninput = () => {
      if (field.kind === 'number') {
        const held = input.value.trim();
        write(path, held === '' ? undefined : Number(held), held !== '');
        return;
      }
      write(path, input.value);
    };
  }
  wrap.append(labelFor(field, id), markInvalid(input, path));

  // The site chooses a mark from the address; showing which address it read
  // is the difference between a working icon and a silently generic one.
  if (field.showDomain === true) {
    const line = node('p', 'help');
    try {
      line.textContent = input.value
        ? 'The site will look for a mark for ' + new URL(input.value).hostname
        : '';
    } catch (error) {
      line.textContent = 'Not an address the site can read a domain from';
    }
    if (line.textContent) wrap.append(line);
  }
  return decorate(wrap, field, path);
}

/// One idea in two languages, showing one at a time.
///
/// The owner asked for language tabs rather than the alternating EN, AR, EN,
/// AR run of boxes the old panel produced, in which there was no way to tell
/// the name from the positioning statement. The tab is at the top of the
/// panel and switches every field at once, so the field's own label is free to
/// say what the field is. The other language is never discarded; the line
/// underneath says whether it is written.
function localizedControl(field, value, path) {
  const held = value && typeof value === 'object' ? value : {};
  const inner = path.concat([state.lang]);
  const wrap = node('div', 'field');
  const id = idFor(inner);
  const long = field.kind === 'localizedParagraph';
  const input = document.createElement(long ? 'textarea' : 'input');
  if (!long) input.type = 'text';
  input.id = id;
  input.value = held[state.lang] === undefined || held[state.lang] === null
    ? ''
    : String(held[state.lang]);
  input.lang = state.lang;
  input.dir = state.lang === 'ar' ? 'rtl' : 'ltr';
  input.oninput = () => {
    const next = Object.assign({}, held);
    if (input.value === '') delete next[state.lang];
    else next[state.lang] = input.value;
    write(path, next);
  };
  wrap.append(labelFor(field, id), markInvalid(input, inner));

  const other = state.lang === 'en' ? 'ar' : 'en';
  const otherName = other === 'ar' ? 'Arabic' : 'English';
  const written = typeof held[other] === 'string' && held[other] !== '';
  const line = node('p', 'otherLang');
  if (written) {
    // The label is English and the value may not be. Left as one run of text
    // the colon ends up on the wrong side of the line, which is how "Arabic:
    // شخص تجريبي" renders as "شخص تجريبي:Arabic". A bdi isolates the value so
    // each half is laid out in its own direction.
    line.append(document.createTextNode(otherName + ': '));
    const isolated = document.createElement('bdi');
    isolated.textContent = held[other];
    line.append(isolated);
  } else {
    line.textContent = 'No ' + otherName + ' written.';
  }
  wrap.append(line);
  return decorate(wrap, field, path);
}

function booleanControl(field, value, path) {
  const wrap = node('div', 'field');
  const line = node('div', 'check');
  const id = idFor(path);
  const box = document.createElement('input');
  box.type = 'checkbox';
  box.id = id;
  box.checked = value === true;
  box.onchange = () => write(path, box.checked, true);
  const label = node('label', null, field.label);
  label.htmlFor = id;
  line.append(box, label);
  wrap.append(line);
  return decorate(wrap, field, path);
}

function choiceControl(field, value, path) {
  const wrap = node('div', 'field');
  const id = idFor(path);
  const select = document.createElement('select');
  select.id = id;
  if (field.required !== true) {
    const none = document.createElement('option');
    none.value = '';
    none.textContent = 'Not set';
    select.append(none);
  }
  for (const option of field.options) {
    const made = document.createElement('option');
    made.value = option.value;
    made.textContent = option.label;
    select.append(made);
  }
  select.value = value === undefined || value === null ? '' : String(value);
  select.onchange = () => {
    write(path, select.value === '' ? undefined : select.value, select.value !== '');
    render();
  };
  wrap.append(labelFor(field, id), markInvalid(select, path));
  return decorate(wrap, field, path);
}

function choiceListControl(field, value, path) {
  const held = Array.isArray(value) ? value : [];
  const wrap = node('div', 'field');
  wrap.append(node('span', 'fieldLabel', field.label + (field.required === true ? ' *' : '')));
  const group = node('div', 'checks');
  group.setAttribute('role', 'group');
  group.setAttribute('aria-label', field.label);
  for (const option of field.options) {
    const line = node('div', 'check');
    const id = idFor(path.concat([option.value]));
    const box = document.createElement('input');
    box.type = 'checkbox';
    box.id = id;
    box.checked = held.indexOf(option.value) !== -1;
    box.onchange = () => {
      const next = field.options
        .map((entry) => entry.value)
        .filter((entry) =>
          entry === option.value ? box.checked : held.indexOf(entry) !== -1);
      write(path, next, true);
      render();
    };
    const label = node('label', null, option.label);
    label.htmlFor = id;
    line.append(box, label);
    group.append(line);
  }
  wrap.append(group);
  return decorate(wrap, field, path);
}

/// A two-letter code, with the ones the site can draw a flag for offered.
function countryControl(field, value, path) {
  const wrap = node('div', 'field');
  const id = idFor(path);
  const input = document.createElement('input');
  input.id = id;
  input.type = 'text';
  input.value = value === undefined || value === null ? '' : String(value);
  input.maxLength = 2;
  input.autocapitalize = 'characters';
  input.spellcheck = false;
  input.setAttribute('list', 'knownCountries');
  input.oninput = () => write(path, input.value.toUpperCase());
  wrap.append(labelFor(field, id), markInvalid(input, path));
  return decorate(wrap, field, path);
}

function coordsControl(field, value, path) {
  const held = Array.isArray(value) ? value : [];
  const wrap = node('div', 'field');
  wrap.append(node('span', 'fieldLabel', field.label + (field.required === true ? ' *' : '')));
  const pair = node('div', 'pair');
  const parts = [
    {name: 'Latitude', index: 0},
    {name: 'Longitude', index: 1},
  ];
  for (const part of parts) {
    const cell = node('div');
    const id = idFor(path.concat([part.index]));
    const label = node('label', null, part.name);
    label.htmlFor = id;
    const input = document.createElement('input');
    input.id = id;
    input.type = 'number';
    input.step = 'any';
    input.value = typeof held[part.index] === 'number' ? String(held[part.index]) : '';
    input.oninput = () => {
      const next = [
        typeof held[0] === 'number' ? held[0] : 0,
        typeof held[1] === 'number' ? held[1] : 0,
      ];
      next[part.index] = input.value.trim() === '' ? 0 : Number(input.value);
      write(path, next, true);
    };
    cell.append(label, input);
    pair.append(cell);
  }
  wrap.append(pair);
  return decorate(wrap, field, path);
}

/// An identifier pointing at an entry in another document.
function referenceControl(field, value, path) {
  const wrap = node('div', 'field');
  const id = idFor(path);
  const select = document.createElement('select');
  select.id = id;
  const none = document.createElement('option');
  none.value = '';
  none.textContent = 'Not set';
  select.append(none);
  for (const option of referencableEntries(field.references)) {
    const made = document.createElement('option');
    made.value = option.value;
    made.textContent = option.label;
    select.append(made);
  }
  if (value !== undefined && value !== null &&
      !referencableEntries(field.references).some((o) => o.value === value)) {
    const missing = document.createElement('option');
    missing.value = String(value);
    missing.textContent = value + ' (no longer exists)';
    select.append(missing);
  }
  select.value = value === undefined || value === null ? '' : String(value);
  select.onchange = () => {
    write(path, select.value === '' ? undefined : select.value);
    render();
  };
  wrap.append(labelFor(field, id), markInvalid(select, path));
  return decorate(wrap, field, path);
}

/// What another document offers to be pointed at.
///
/// Found by looking for the list of objects that carries an identifier,
/// rather than by naming a key here, so the schema stays the only place that
/// describes a document's shape.
function referencableEntries(file) {
  const entry = state.docs.get(file);
  const document = schemaFor(file);
  if (!entry || !document) return [];
  for (const field of document.fields) {
    if (field.kind !== 'list' || field.of.kind !== 'object') continue;
    if (!field.of.fields.some((child) => child.kind === 'id')) continue;
    const items = getIn(entry.draft, [field.key]);
    if (!Array.isArray(items)) return [];
    return items
      .map((item, index) => ({
        value: item && item.id,
        label: titleOf(field.of, item, index),
      }))
      .filter((option) => typeof option.value === 'string');
  }
  return [];
}

/// A picture or a recording, either uploaded here or shipped in the bundle.
///
/// The uploader is attached because the schema says this field holds a file,
/// not because the key happened to be spelled "cover". The field can also take
/// something already in the library, which is what makes one picture usable in
/// two places without uploading it twice.
function assetControl(field, value, path) {
  const wrap = node('div', 'field');
  const id = idFor(path);
  const input = document.createElement('input');
  input.id = id;
  input.type = 'text';
  input.spellcheck = false;
  input.value = value === undefined || value === null ? '' : String(value);
  input.oninput = () => write(path, input.value);
  wrap.append(labelFor(field, id), markInvalid(input, path));

  const uploadable = field.uploadable !== false &&
    (field.media === 'image' || field.media === 'audio');
  if (!uploadable) return decorate(wrap, field, path);

  const progress = node('div', 'progress');
  progress.hidden = true;
  const bar = node('div', 'bar');
  progress.append(bar);
  const line = node('p', 'help');
  line.hidden = true;

  const tools = node('div', 'listFoot');
  const pickerId = id + '-file';
  const picker = document.createElement('input');
  picker.type = 'file';
  picker.id = pickerId;
  picker.className = 'filePicker';
  picker.accept = field.media === 'audio'
    ? 'audio/mpeg,audio/mp4,audio/wav,audio/ogg'
    : 'image/png,image/jpeg,image/webp';

  const pickLabel = node('label', 'buttonish', 'Upload');
  pickLabel.htmlFor = pickerId;

  const fromLibrary = document.createElement('button');
  fromLibrary.type = 'button';
  fromLibrary.className = 'small';
  fromLibrary.textContent = 'Choose from library';
  fromLibrary.onclick = () => openMediaPicker(field.media, (url) => {
    write(path, url, true);
    render();
  });

  const clear = document.createElement('button');
  clear.type = 'button';
  clear.className = 'small danger';
  clear.textContent = 'Clear';
  clear.disabled = input.value === '';
  clear.onclick = () => {
    write(path, undefined);
    render();
  };

  let lastFile = null;
  const retry = document.createElement('button');
  retry.type = 'button';
  retry.className = 'small';
  retry.textContent = 'Try again';
  retry.hidden = true;

  const run = async (file) => {
    lastFile = file;
    retry.hidden = true;
    progress.hidden = false;
    line.hidden = false;
    bar.style.width = '0%';
    line.textContent = 'Sending ' + file.name + '...';
    try {
      const body = await sendFile(file, field.media, (fraction) => {
        bar.style.width = Math.round(fraction * 100) + '%';
      });
      write(path, body.url, true);
      // Where the schema says a sibling holds the length, it comes from the
      // file's own header or not at all.
      if (field.durationInto) {
        const beside = path.slice(0, -1).concat([field.durationInto]);
        write(beside, typeof body.seconds === 'number' ? body.seconds : undefined);
      }
      say('Uploaded ' + file.name, 'good');
      render();
    } catch (error) {
      progress.hidden = true;
      line.textContent = error.message;
      retry.hidden = false;
      say(error.message, 'bad');
    }
  };
  picker.onchange = () => {
    const chosen = picker.files && picker.files[0];
    if (chosen) run(chosen);
  };
  retry.onclick = () => {
    if (lastFile) run(lastFile);
  };

  tools.append(pickLabel, picker, fromLibrary, clear, retry);
  wrap.append(tools, progress, line);

  const shown = shownSource(input.value);
  if (shown) {
    const preview = node('div', 'assetPreview');
    if (field.media === 'audio') {
      const player = document.createElement('audio');
      player.controls = true;
      player.preload = 'none';
      player.src = shown;
      player.setAttribute('aria-label', field.label);
      preview.append(player);
    } else {
      const thumb = document.createElement('img');
      thumb.className = 'mediaThumb';
      thumb.src = shown;
      thumb.alt = 'Current ' + field.label;
      preview.append(thumb);
    }
    wrap.append(preview);
  }
  return decorate(wrap, field, path);
}

/// Where a stored reference can actually be fetched from.
///
/// An uploaded image is served by this Worker. A bundle path belongs to the
/// site, which serves it with an open CORS header, so the panel can show it.
function shownSource(value) {
  if (!value) return '';
  if (value.indexOf('/v1/media/') === 0) return value;
  if (value.indexOf('assets/') === 0) return SITE + '/' + value;
  return '';
}

// --- groups and lists ------------------------------------------------------

function objectGroup(field, value, path) {
  const held = value && typeof value === 'object' ? value : {};
  const group = node('div', 'group');
  const head = node('div', 'groupHead');
  head.append(node('h3', null, field.label));
  group.append(head);
  if (field.help) group.append(node('p', 'help', field.help));
  for (const child of field.fields) {
    group.append(control(child, held[child.key], path.concat([child.key])));
  }
  return group;
}

function mapGroup(field, value, path) {
  const held = value && typeof value === 'object' ? value : {};
  const group = node('div', 'group');
  const head = node('div', 'groupHead');
  head.append(node('h3', null, field.label));
  group.append(head);
  if (field.help) group.append(node('p', 'help', field.help));
  for (const key of field.keys) {
    const child = Object.assign({}, field.of, {label: key.label, key: key.value});
    group.append(control(child, held[key.value], path.concat([key.value])));
  }
  for (const issue of issuesAt(pathText(path))) {
    group.append(node('p', 'issue' + (issue.kind === 'warn' ? ' warn' : ''), issue.message));
  }
  return group;
}

/// A short list of plain values, as removable chips.
function chipList(field, items, path) {
  const wrap = node('div', 'field');
  wrap.append(node('span', 'fieldLabel', field.label + ' — ' + items.length));
  const chips = node('div', 'chips');
  items.forEach((item, index) => {
    const chip = node('div', 'chip');
    const id = idFor(path.concat([index]));
    const input = document.createElement('input');
    input.id = id;
    input.type = 'text';
    input.value = item === null || item === undefined ? '' : String(item);
    input.setAttribute('aria-label', field.label + ' ' + (index + 1));
    if (field.of.kind !== 'country') input.className = 'wide';
    if (field.of.kind === 'country') {
      input.maxLength = 2;
      input.setAttribute('list', 'knownCountries');
      input.oninput = () => write(path.concat([index]), input.value.toUpperCase(), true);
    } else {
      input.oninput = () => write(path.concat([index]), input.value, true);
    }
    const remove = document.createElement('button');
    remove.type = 'button';
    remove.textContent = '\\u00D7';
    remove.setAttribute('aria-label', 'Remove ' + (item || 'entry ' + (index + 1)));
    remove.onclick = () => {
      write(path, items.filter((_, at) => at !== index), true);
      render();
    };
    chip.append(input, remove);
    chips.append(chip);
  });
  wrap.append(chips);
  const foot = node('div', 'listFoot');
  const add = document.createElement('button');
  add.type = 'button';
  add.className = 'small';
  add.textContent = field.addLabel || 'Add';
  add.onclick = () => {
    write(path, items.concat([blankFor(field.of)]), true);
    render();
    const next = document.getElementById(idFor(path.concat([items.length])));
    if (next) next.focus();
  };
  foot.append(add);
  wrap.append(foot);
  return decorate(wrap, field, path);
}

/// A list of references, one select each.
function referenceList(field, items, path) {
  const wrap = node('div', 'field');
  wrap.append(node('span', 'fieldLabel', field.label + ' — ' + items.length));
  items.forEach((item, index) => {
    const line = node('div', 'chip');
    line.style.paddingInlineStart = '4px';
    const child = Object.assign({}, field.of, {label: field.label + ' ' + (index + 1)});
    const control = referenceControl(child, item, path.concat([index]));
    control.style.margin = '0';
    control.style.flex = '1';
    const remove = document.createElement('button');
    remove.type = 'button';
    remove.textContent = '\\u00D7';
    remove.setAttribute('aria-label', 'Remove ' + (item || 'entry ' + (index + 1)));
    remove.onclick = () => {
      write(path, items.filter((_, at) => at !== index), true);
      render();
    };
    line.append(control, remove);
    wrap.append(line);
  });
  const foot = node('div', 'listFoot');
  const add = document.createElement('button');
  add.type = 'button';
  add.className = 'small';
  add.textContent = field.addLabel || 'Add';
  add.onclick = () => {
    write(path, items.concat(['']), true);
    render();
  };
  foot.append(add);
  wrap.append(foot);
  return decorate(wrap, field, path);
}

/// The reorder and remove controls every list entry carries.
function rowTools(field, items, index, path) {
  const tools = node('div', 'rowTools');
  const name = titleOf(field.of, items[index], index);
  const move = (to, glyph, what) => {
    const button = document.createElement('button');
    button.type = 'button';
    button.textContent = glyph;
    button.setAttribute('aria-label', 'Move ' + name + ' ' + what);
    button.disabled = to < 0 || to >= items.length;
    button.onclick = () => {
      const next = items.slice();
      const moved = next.splice(index, 1)[0];
      next.splice(to, 0, moved);
      write(path, next, true);
      render();
    };
    return button;
  };
  tools.append(move(index - 1, '\\u2191', 'up'), move(index + 1, '\\u2193', 'down'));
  const remove = document.createElement('button');
  remove.type = 'button';
  remove.className = 'danger';
  remove.textContent = '\\u00D7';
  remove.setAttribute('aria-label', 'Remove ' + name);
  remove.onclick = () => {
    if (!confirm('Remove "' + name + '"? This changes the draft, not the site.')) return;
    write(path, items.filter((_, at) => at !== index), true);
    render();
  };
  tools.append(remove);
  return tools;
}

/// A compact list whose entries open as their own panel.
///
/// This is the shape the owner asked for: a page of an editor is a list you
/// can read, not eleven expanded forms stacked on top of each other.
function rowList(field, items, path) {
  const wrap = node('div', 'field');
  wrap.append(node('span', 'fieldLabel', field.label + ' — ' + items.length));
  const rows = node('div', 'rows');
  if (items.length === 0) {
    rows.append(node('div', 'empty', 'Nothing here yet.'));
  }
  items.forEach((item, index) => {
    const row = node('div', 'row');
    row.append(node('span', 'grip', String(index + 1)));
    const open = document.createElement('button');
    open.type = 'button';
    open.className = 'open';
    const title = node('span', 't', titleOf(field.of, item, index));
    open.append(title);
    const subtitle = subtitleOf(field.of, item);
    if (subtitle) open.append(node('span', 's', subtitle));
    const broken = troubleBelow(pathText(path.concat([index])));
    if (broken > 0) {
      const flag = node('span', 'count bad', broken + (broken === 1 ? ' problem' : ' problems'));
      flag.style.marginInlineStart = '8px';
      title.append(document.createTextNode(' '), flag);
    }
    open.onclick = () => go(state.file, path.concat([index]));
    row.append(open, rowTools(field, items, index, path));
    rows.append(row);
  });
  wrap.append(rows);

  const foot = node('div', 'listFoot');
  const add = document.createElement('button');
  add.type = 'button';
  add.className = 'small';
  add.textContent = field.addLabel || 'Add';
  add.onclick = () => {
    write(path, items.concat([blankFor(field.of)]), true);
    go(state.file, path.concat([items.length]));
  };
  foot.append(add);
  wrap.append(foot);
  return decorate(wrap, field, path);
}

/// A short list whose entries open in place.
///
/// Used where an entry is two fields and sending the owner to another panel
/// to edit them would cost more clicks than it saves.
function inlineList(field, items, path) {
  const wrap = node('div', 'field');
  wrap.append(node('span', 'fieldLabel', field.label + ' — ' + items.length));
  if (items.length === 0) {
    const rows = node('div', 'rows');
    rows.append(node('div', 'empty', 'Nothing here yet.'));
    wrap.append(rows);
  }
  items.forEach((item, index) => {
    const at = path.concat([index]);
    const key = state.file + '/' + pathText(at);
    const card = node('div', 'inlineItem');
    const head = node('div', 'head');
    const open = document.createElement('button');
    open.type = 'button';
    open.className = 'open';
    open.textContent = titleOf(field.of, item, index);
    open.setAttribute('aria-expanded', String(openItems.has(key)));
    open.onclick = () => {
      if (openItems.has(key)) openItems.delete(key);
      else openItems.add(key);
      render();
    };
    head.append(open, rowTools(field, items, index, path));
    const body = node('div', 'body');
    body.hidden = !openItems.has(key);
    if (!body.hidden) {
      for (const child of field.of.fields) {
        body.append(control(child, (item || {})[child.key], at.concat([child.key])));
      }
    }
    card.append(head, body);
    wrap.append(card);
  });
  const foot = node('div', 'listFoot');
  const add = document.createElement('button');
  add.type = 'button';
  add.className = 'small';
  add.textContent = field.addLabel || 'Add';
  add.onclick = () => {
    openItems.add(state.file + '/' + pathText(path.concat([items.length])));
    write(path, items.concat([blankFor(field.of)]), true);
    render();
  };
  foot.append(add);
  wrap.append(foot);
  return decorate(wrap, field, path);
}

/// Which inline entries the owner has open, kept across a re-render.
const openItems = new Set();

function listControl(field, value, path) {
  const items = Array.isArray(value) ? value : [];
  if (field.of.kind === 'object') {
    return field.of.expand === 'inline'
      ? inlineList(field, items, path)
      : rowList(field, items, path);
  }
  if (field.of.kind === 'reference') return referenceList(field, items, path);
  return chipList(field, items, path);
}

/// Builds the control for one field.
function control(field, value, path) {
  switch (field.kind) {
    case 'localized':
    case 'localizedParagraph':
      return localizedControl(field, value, path);
    case 'boolean':
      return booleanControl(field, value, path);
    case 'choice':
      return choiceControl(field, value, path);
    case 'choiceList':
      return choiceListControl(field, value, path);
    case 'country':
      return countryControl(field, value, path);
    case 'coords':
      return coordsControl(field, value, path);
    case 'reference':
      return referenceControl(field, value, path);
    case 'asset':
      return assetControl(field, value, path);
    case 'object':
      return objectGroup(field, value, path);
    case 'map':
      return mapGroup(field, value, path);
    case 'list':
      return listControl(field, value, path);
    default:
      return textControl(field, value, path);
  }
}
`;

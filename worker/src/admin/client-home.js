/**
 * The home dashboard.
 *
 * The hard part of this screen is not drawing it. It is refusing to draw the
 * things it cannot honestly draw.
 *
 * The public build ships without an analytics endpoint, so the site sends
 * nothing and these counters are almost certainly empty. A dashboard that
 * responds to that by showing a tidy grid of zeros, or worse a plausible
 * curve, tells the owner his site has no visitors -- which is a different
 * claim from "nothing is being counted", and the second one is the true one.
 * So the empty state says which it is.
 *
 * And there is no weekly or monthly unique-visitor figure anywhere on it. The
 * daily counts cannot be added together, and the panel says why rather than
 * quietly leaving the number out.
 */

export const clientHome = `
/// The ranges offered, as whole days back from today.
const ranges = [
  {id: '7', label: 'Last 7 days', days: 7},
  {id: '28', label: 'Last 28 days', days: 28},
  {id: '90', label: 'Last 90 days', days: 90},
  {id: 'custom', label: 'Choose dates', days: 0},
];

function dayString(when) {
  return when.toISOString().slice(0, 10);
}

function rangeDates() {
  if (state.range.id === 'custom') {
    return {from: state.range.from, to: state.range.to};
  }
  const chosen = ranges.find((entry) => entry.id === state.range.id) || ranges[1];
  const now = new Date();
  return {
    from: dayString(new Date(now.getTime() - (chosen.days - 1) * 86400000)),
    to: dayString(now),
  };
}

async function loadInsights() {
  const dates = rangeDates();
  try {
    const response = await api(
      '/v1/admin/insights?from=' + dates.from + '&to=' + dates.to,
    );
    const body = await response.json();
    if (!response.ok) throw new Error(body.error || 'Could not read the counters');
    state.insights = body;
    state.insightsError = '';
  } catch (error) {
    state.insights = null;
    state.insightsError = error.message;
  }
}

/// One figure, with the words that make it mean something.
function figure(value, label, footnote) {
  const block = node('div', 'figure');
  block.append(node('strong', null, value));
  block.append(node('span', 'k', label));
  if (footnote) block.append(node('span', 'note', footnote));
  return block;
}

/// A breakdown as a list of bars, or nothing at all.
function breakdown(title, entries, empty) {
  const group = node('div', 'group');
  group.append(node('h3', null, title));
  if (entries.length === 0) {
    group.append(node('p', 'note', empty));
    return group;
  }
  const most = Math.max(...entries.map((entry) => entry.count));
  for (const entry of entries.slice(0, 8)) {
    const line = node('div', 'bar');
    line.append(node('span', 'barName', entry.value));
    const track = node('span', 'barTrack');
    const fill = node('span', 'barFill');
    fill.style.width = Math.round((entry.count / most) * 100) + '%';
    track.append(fill);
    line.append(track);
    line.append(node('span', 'barCount', String(entry.count)));
    group.append(line);
  }
  return group;
}

async function renderHome() {
  const pane = el('editor');
  pane.replaceChildren();

  const crumbs = node('ol', 'crumbs');
  const here = document.createElement('li');
  const label = node('span', 'here', 'Home');
  label.setAttribute('aria-current', 'true');
  here.append(label);
  crumbs.append(here);
  const wrapper = node('nav');
  wrapper.setAttribute('aria-label', 'Breadcrumb');
  wrapper.append(crumbs);
  pane.append(wrapper);

  const head = node('div', 'panelHead');
  const titles = node('div', 'titles');
  titles.append(node('h2', null, 'Home'));
  titles.append(node('p', null, 'What has been counted, and what has not.'));
  head.append(titles);
  pane.append(head);

  pane.append(rangePicker());

  if (state.insights === null && state.insightsError === '') {
    pane.append(node('p', 'note', 'Reading the counters...'));
    await loadInsights();
    if (state.view === 'home') render();
    return;
  }
  if (state.insightsError) {
    const failed = node('div', 'warn');
    failed.append(node('p', null, state.insightsError));
    const again = document.createElement('button');
    again.type = 'button';
    again.className = 'small';
    again.textContent = 'Try again';
    again.onclick = () => {
      state.insights = null;
      state.insightsError = '';
      render();
    };
    failed.append(again);
    pane.append(failed);
    return;
  }

  pane.append(releaseSection());

  const seen = state.insights;
  pane.append(collectionState(seen));

  if (seen.collection.rowsInRange === 0) {
    pane.append(publishedState());
    return;
  }

  const figures = node('div', 'figures');
  figures.append(figure(String(seen.views), 'page views', 'Every view, not people'));
  figures.append(figure(
    String(seen.interactions),
    'interactions',
    'Everything that is not a page view',
  ));
  figures.append(figure(
    seen.uniqueVisitors.busiestDay
      ? String(seen.uniqueVisitors.busiestDay.count)
      : '—',
    'busiest day',
    seen.uniqueVisitors.busiestDay
      ? 'Deduplicated within ' + seen.uniqueVisitors.busiestDay.date
      : 'No deduplicated days in range',
  ));
  pane.append(figures);

  // Said before anyone can ask why the obvious number is missing.
  const caveat = node('div', 'group');
  caveat.append(node('h3', null, 'Why there is no visitor total'));
  caveat.append(node('p', 'note', seen.uniqueVisitors.whyNoTotal));
  if (seen.dailyUniques.length > 0) {
    caveat.append(node(
      'p',
      'help',
      'Deduplicated per day: ' +
        seen.dailyUniques
          .map((entry) => entry.date + ' — ' + entry.count)
          .join(', '),
    ));
  }
  pane.append(caveat);

  pane.append(breakdown('Events', seen.events, 'Nothing recorded.'));
  pane.append(breakdown('Pages viewed', seen.routes, 'No page views recorded.'));
  pane.append(breakdown('Countries', seen.countries, 'No countries recorded.'));
  pane.append(breakdown('Devices', seen.devices, 'No devices recorded.'));
  pane.append(breakdown(
    'Where people came from',
    seen.referrers,
    'No referrer was recorded for any of these. That is what a direct visit ' +
      'looks like, and also what a browser that sends no referrer looks like.',
  ));
  pane.append(breakdown(
    'Campaigns',
    seen.campaigns,
    'No campaign tag was recorded for any of these.',
  ));

  if (seen.means.length > 0) {
    const averages = node('div', 'group');
    averages.append(node('h3', null, 'Averages'));
    averages.append(node(
      'p',
      'note',
      'A running total divided by its count. There is no per-visit record, ' +
        'deliberately, so there is no median to be had.',
    ));
    for (const entry of seen.means) {
      averages.append(node(
        'p',
        null,
        entry.event + ' on ' + entry.route + ': ' + entry.mean + ' ' +
          entry.unit + ', over ' + entry.samples + ' events',
      ));
    }
    pane.append(averages);
  }

  const kept = node('div', 'group');
  kept.append(node('h3', null, 'How long any of this is kept'));
  kept.append(node(
    'p',
    'note',
    'Counters: ' + seen.retention.counters + '. Visitor hashes: ' +
      seen.retention.visitorHashes + '. ' + seen.retention.note,
  ));
  pane.append(kept);
}

/// What a build made from the current content would be, and whether the
/// public HTML is serving it yet.
///
/// These are two different questions and the panel used to be able to answer
/// only the first. Publishing updates the content endpoint the app reads
/// immediately; the HTML follows when a release runs. Saying "published" for
/// both is the claim the contract forbids, so this says which is which.
function releaseSection() {
  const group = node('div', 'group');
  group.append(node('h3', null, 'What the site is serving'));

  if (state.release === null) {
    group.append(node('p', 'note', 'Working out the revision...'));
    loadRelease().then(() => {
      if (state.view === 'home') render();
    });
    return group;
  }
  if (state.releaseError) {
    group.append(node('p', 'issue', state.releaseError));
    return group;
  }

  const held = state.release;
  if (held.state === 'invalid' || held.revision === null) {
    group.append(node(
      'p',
      'issue',
      'The current content would not build. ' +
        held.problems.map((entry) =>
          entry.file + (entry.path ? ' ' + entry.path : '') + ': ' + entry.message)
          .join('; '),
    ));
    return group;
  }

  const short = held.revision.slice(0, 16);
  group.append(node(
    'p',
    null,
    'A build from what is published now would be revision ' + short + '.',
  ));

  const release = held.release;
  const line = node('p', release.state === 'live' ? 'note' : 'issue warn');
  if (release.state === 'live') {
    line.textContent = 'The public HTML is serving exactly this. ' + release.because;
  } else if (release.state === 'behind') {
    line.textContent = 'The public HTML is serving ' +
      String(release.live).slice(0, 16) + '. ' + release.because;
  } else {
    line.textContent = release.because;
  }
  group.append(line);

  group.append(node(
    'p',
    'help',
    'The app reads published content straight away. The HTML pages, the CV and ' +
      'the page metadata are built from a snapshot, so they change when a ' +
      'release runs and not before.',
  ));

  const copy = document.createElement('button');
  copy.type = 'button';
  copy.className = 'small';
  copy.textContent = 'Copy the snapshot';
  copy.onclick = async () => {
    try {
      await navigator.clipboard.writeText(JSON.stringify(held.snapshot, null, 2));
      say('Snapshot copied. It is what a build takes as PORTFOLIO_SNAPSHOT.', 'good');
    } catch (error) {
      say('Could not copy the snapshot', 'bad');
    }
  };
  group.append(copy);
  return group;
}

async function loadRelease() {
  // Every document the panel holds. The Worker uses its own published copy
  // wherever it has one and only falls back to these, so this cannot be used
  // to describe a document the site is already serving.
  const documents = {};
  for (const entry of SCHEMA.documents) {
    const held = state.docs.get(entry.file);
    if (held) documents[entry.file] = held.live;
  }
  try {
    const response = await api('/v1/admin/release', {
      method: 'POST',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify({
        documents: documents,
        references: knownReferences('career.json'),
      }),
    });
    const body = await response.json();
    if (!response.ok) throw new Error(body.error || 'Could not work out the revision');
    state.release = body;
    state.releaseError = '';
  } catch (error) {
    state.release = null;
    state.releaseError = error.message;
  }
}

/// Whether anything is being counted at all, said plainly.
function collectionState(seen) {
  // Only an absence is worth an alert. A range that has data in it is an
  // ordinary statement of what is being shown, and colouring it like a
  // problem teaches the owner to ignore the colour.
  const nothing = seen.collection.rowsInRange === 0;
  const block = node('div', nothing ? 'warn' : 'rangeNote');
  if (seen.collection.rowsEver === 0) {
    block.append(node('p', null, 'Nothing has ever been recorded here.'));
  } else if (seen.collection.rowsInRange === 0) {
    block.append(node(
      'p',
      null,
      'Nothing in this range. There is data outside it: ' +
        seen.collection.firstDate + ' to ' + seen.collection.lastDate + '.',
    ));
  } else {
    block.append(node(
      'p',
      null,
      'Counted between ' + seen.range.from + ' and ' + seen.range.to +
        ', by UTC calendar day.',
    ));
  }
  return block;
}

/// The reason the numbers are missing, which is not that nobody visited.
function publishedState() {
  const block = node('div', 'group');
  block.append(node('h3', null, 'This is not a quiet site'));
  block.append(node(
    'p',
    null,
    state.insights.configuration.note,
  ));
  block.append(node(
    'p',
    'help',
    'An empty dashboard here means nothing is being counted. It does not mean ' +
      'nobody came. Turning collection on is a separate decision with consent ' +
      'behaviour attached to it, and nothing in this panel does it. See ' +
      state.insights.configuration.reference + '.',
  ));
  return block;
}

function rangePicker() {
  const wrap = node('div', 'field');
  wrap.append(node('span', 'fieldLabel', 'Range'));
  const row = node('div', 'checks');
  row.setAttribute('role', 'group');
  row.setAttribute('aria-label', 'Range');
  for (const entry of ranges) {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'small';
    button.textContent = entry.label;
    button.setAttribute('aria-pressed', String(state.range.id === entry.id));
    if (state.range.id === entry.id) button.classList.add('primary');
    button.onclick = () => {
      state.range = state.range.id === entry.id && entry.id === 'custom'
        ? state.range
        : {id: entry.id, from: state.range.from, to: state.range.to};
      state.insights = null;
      state.insightsError = '';
      render();
    };
    row.append(button);
  }
  wrap.append(row);

  if (state.range.id === 'custom') {
    const pair = node('div', 'pair');
    for (const edge of [{key: 'from', name: 'From'}, {key: 'to', name: 'To'}]) {
      const cell = node('div');
      const id = 'range-' + edge.key;
      const label = node('label', null, edge.name);
      label.htmlFor = id;
      const input = document.createElement('input');
      input.type = 'date';
      input.id = id;
      input.value = state.range[edge.key];
      input.onchange = () => {
        state.range = Object.assign({}, state.range, {[edge.key]: input.value});
        state.insights = null;
        state.insightsError = '';
        render();
      };
      cell.append(label, input);
      pair.append(cell);
    }
    wrap.append(pair);
  }

  const dates = rangeDates();
  wrap.append(node(
    'p',
    'help',
    'Showing ' + dates.from + ' to ' + dates.to + ', in UTC. A day here is a ' +
      'UTC calendar day, not a day in your own timezone.',
  ));
  return wrap;
}
`;

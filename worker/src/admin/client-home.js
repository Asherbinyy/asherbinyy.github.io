/** Insights are read from the existing endpoint; collection stays disabled. */
export const clientHome = `
const ranges = [
  {id: '7', label: 'Last 7 days', days: 7},
  {id: '28', label: 'Last 28 days', days: 28},
  {id: '90', label: 'Last 90 days', days: 90},
  {id: 'custom', label: 'Choose dates', days: 0},
];
let insightsRequest = 0;
let insightsLoading = false;
let releaseLoading = false;
let releaseRequest = 0;

function dayString(when) { return when.toISOString().slice(0, 10); }
function rangeDates() {
  if (state.range.id === 'custom') return {from: state.range.from, to: state.range.to};
  const chosen = ranges.find((entry) => entry.id === state.range.id) || ranges[1];
  const now = new Date();
  return {from: dayString(new Date(now.getTime() - (chosen.days - 1) * 86400000)), to: dayString(now)};
}

async function loadInsights() {
  const dates = rangeDates();
  const ticket = ++insightsRequest;
  insightsLoading = true;
  try {
    if (!dates.from || !dates.to || dates.from > dates.to) throw new Error('Choose a start date on or before the end date.');
    const response = await api('/v1/admin/insights?from=' + dates.from + '&to=' + dates.to);
    const body = await response.json();
    if (ticket !== insightsRequest) return;
    if (!response.ok) throw new Error(body.error || 'Could not load insights');
    state.insights = body; state.insightsError = '';
  } catch (error) {
    if (ticket !== insightsRequest) return;
    state.insights = null; state.insightsError = error.message;
  } finally {
    if (ticket === insightsRequest) { insightsLoading = false; if (state.view === 'home') render(); }
  }
}

function refreshInsights() {
  // Invalidate even a response already in flight before drawing the next range.
  insightsRequest += 1; insightsLoading = false;
  state.insights = null; state.insightsError = ''; render();
}

function figure(value, label, note) {
  const block = node('div', 'figure');
  block.append(node('strong', null, value), node('span', 'k', label), node('span', 'note', note));
  return block;
}

const eventNames = {route_view: 'Page views', cv_opened: 'CV opens', outbound_click: 'Outbound clicks', section_dwell: 'Time in section', scroll_depth: 'Scroll depth', game_started: 'Game starts', game_finished: 'Game finishes'};
function breakdown(title, entries, empty) {
  const group = node('section', 'group');
  group.append(node('h3', null, title));
  if (!entries.length) { group.append(node('p', 'note', empty)); return group; }
  const most = Math.max(1, ...entries.map((entry) => entry.count));
  for (const entry of entries.slice(0, 8)) {
    const line = node('div', 'bar');
    line.append(node('span', 'barName', eventNames[entry.value] || entry.value));
    const track = node('span', 'barTrack'); track.setAttribute('aria-hidden', 'true');
    const fill = node('span', 'barFill'); fill.style.width = entry.count / most * 100 + '%';
    track.append(fill); line.append(track, node('span', 'barCount', String(entry.count))); group.append(line);
  }
  if (entries.length > 8) group.append(node('p', 'note', 'Showing the eight largest categories.'));
  return group;
}

function renderHome() {
  const pane = el('editor'); pane.replaceChildren();
  pane.append(pageHeading('Overview', 'Recorded activity and publication status.'));
  pane.append(rangePicker());
  const disabled = node('div', 'rangeNote');
  disabled.append(node('strong', null, 'Analytics collection is disabled'), node('p', null, 'The published site sends no analytics. Available historical records may appear below; missing records do not mean there were no visitors.'));
  pane.append(disabled);
  if (!state.insights && !state.insightsError) {
    pane.append(node('p', 'note', 'Loading insights…'));
    if (!insightsLoading) loadInsights();
    return;
  }
  if (state.insightsError) {
    const failed = node('div', 'group'); failed.setAttribute('role', 'alert');
    failed.append(node('p', 'issue', state.insightsError));
    const retry = node('button', 'small', 'Retry insights'); retry.onclick = refreshInsights;
    failed.append(retry); pane.append(failed); return;
  }
  const seen = state.insights, recorded = seen.collection.rowsInRange > 0;
  const figures = node('div', 'figures');
  figures.append(figure(recorded ? String(seen.views) : '—', 'Page views', recorded ? 'Recorded views in this range' : 'No records in this range'));
  figures.append(figure(recorded ? String(seen.interactions) : '—', 'Interactions', 'Recorded events excluding page views'));
  figures.append(figure(seen.uniqueVisitors.busiestDay ? String(seen.uniqueVisitors.busiestDay.count) : '—', 'Busiest day · unique visitors', seen.uniqueVisitors.busiestDay ? seen.uniqueVisitors.busiestDay.date + ' · one day only' : 'No daily unique counts available'));
  pane.append(figures);
  if (!recorded && seen.collection.rowsEver > 0) pane.append(node('p', 'note', 'No records in this range. Available records span ' + seen.collection.firstDate + ' to ' + seen.collection.lastDate + '.'));
  const charts = node('div', 'chartGrid');
  charts.append(seriesChart('Recorded activity', seen.byDay, 'All recorded events per UTC day, including views and interactions. Missing days are left blank.', true));
  charts.append(seriesChart('Daily unique visitors', seen.dailyUniques, 'Deduplicated within each UTC day. Daily counts cannot be added into weekly or monthly people totals.', true));
  charts.append(breakdown('Pages viewed', seen.routes, 'No page-view records in this range.'));
  charts.append(breakdown('Interactions by type', seen.events.filter((event) => event.value !== 'route_view'), 'No interaction records in this range.'));
  charts.append(breakdown('Countries · events', seen.countries, 'No country records in this range.'));
  charts.append(breakdown('Devices · events', seen.devices, 'No device records in this range.'));
  charts.append(breakdown('Referrers · events', seen.referrers, 'No referrer records. Direct and unreported visits are not separated.'));
  charts.append(breakdown('Campaigns · events', seen.campaigns, 'No campaign records in this range.'));
  pane.append(charts);
  pane.append(releaseSection());
  const details = node('details', 'group'); details.append(node('summary', null, 'About these figures'));
  details.append(node('p', 'note', seen.uniqueVisitors.whyNoTotal));
  details.append(node('p', 'note', 'The endpoint does not provide page views by day or exact clicked destinations. Activity is all events; audience breakdowns count events, not people.'));
  for (const entry of seen.means) details.append(node('p', 'note', (eventNames[entry.event] || entry.event) + ' on ' + entry.route + ': mean ' + entry.mean + ' ' + entry.unit + ', from ' + entry.samples + ' events.'));
  details.append(node('p', 'note', 'Retention: counters ' + seen.retention.counters + '; visitor hashes ' + seen.retention.visitorHashes + '.'));
  pane.append(details);
}

function releaseSection() {
  const group = node('section', 'group'); group.append(node('h3', null, 'Publication'));
  if (state.releaseError) {
    group.append(node('p', 'issue', state.releaseError));
    const retry = node('button', 'small', 'Retry publication status');
    retry.onclick = () => { state.releaseError = ''; state.release = null; render(); }; group.append(retry); return group;
  }
  if (!state.release) {
    group.append(node('p', 'note', 'Loading publication status…'));
    if (!releaseLoading) loadRelease();
    return group;
  }
  const held = state.release;
  if (held.state === 'invalid' || held.revision === null) {
    group.append(node('p', 'issue', 'Content needs correction before the site can be built.'));
    for (const problem of held.problems || []) group.append(node('p', 'note', problem.file + ': ' + problem.message));
    return group;
  }
  const release = held.release;
  const label = {live: 'Public HTML matches published content', behind: 'Public HTML needs a new build', unreleased: 'Public release not verified', unreadable: 'Public release status unavailable'};
  group.append(node('p', null, label[release.state] || 'Public release not verified'), node('p', 'note', release.because));
  group.append(node('p', 'note', 'Content revision ' + held.revision.slice(0, 16) + '. CV, brief and metadata update after a public build.'));
  const copy = node('button', 'small', 'Copy content snapshot');
  copy.onclick = async () => { try { await navigator.clipboard.writeText(JSON.stringify(held.snapshot, null, 2)); say('Content snapshot copied'); } catch { say('Could not copy the snapshot', 'bad'); } };
  group.append(copy); return group;
}

function rangePicker() {
  const wrap = node('div', 'field');
  const row = node('div', 'checks'); row.setAttribute('role', 'group'); row.setAttribute('aria-label', 'Date range');
  for (const range of ranges) {
    const button = node('button', 'small', range.label); button.type = 'button';
    button.setAttribute('aria-pressed', String(state.range.id === range.id));
    if (state.range.id === range.id) button.style.borderColor = 'var(--gold)';
    button.onclick = () => { state.range.id = range.id; refreshInsights(); }; row.append(button);
  }
  const refresh = node('button', 'small', 'Refresh'); refresh.onclick = refreshInsights; row.append(refresh); wrap.append(row);
  if (state.range.id === 'custom') {
    const pair = node('div', 'pair');
    for (const [key, text] of [['from', 'From'], ['to', 'To']]) {
      const cell = node('div'); const label = node('label', null, text); label.htmlFor = 'range-' + key;
      const input = node('input'); input.type = 'date'; input.id = 'range-' + key; input.value = state.range[key];
      input.onchange = () => { state.range[key] = input.value; refreshInsights(); }; cell.append(label, input); pair.append(cell);
    }
    wrap.append(pair);
  }
  const dates = rangeDates(); wrap.append(node('p', 'help', dates.from + ' — ' + dates.to + ' · UTC calendar days')); return wrap;
}
async function loadRelease() {
  const ticket = ++releaseRequest;
  releaseLoading = true;
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
    if (ticket !== releaseRequest) return;
    if (!response.ok) throw new Error(body.error || 'Could not work out the revision');
    state.release = body;
    state.releaseError = '';
  } catch (error) {
    if (ticket !== releaseRequest) return;
    state.release = null;
    state.releaseError = error.message;
  } finally {
    if (ticket === releaseRequest) { releaseLoading = false; if (state.view === 'home') render(); }
  }
}


`;

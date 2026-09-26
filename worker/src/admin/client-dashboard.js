/** Focused reports over observed analytics, with no synthetic production data. */
export const clientDashboard = `
let dashboardTab = 'overview';
let dashboardPublicationOpen = false;
let dashboardSearch = '';
let dashboardSort = {key: '', direction: -1};
const dashboardTabs = [
  ['overview', 'Overview'],
  ['links', 'Links & apps'],
  ['pages', 'Pages'],
  ['audience', 'Audience'],
];
const numberFormat = new Intl.NumberFormat('en-GB');
const percentFormat = new Intl.NumberFormat('en-GB', {maximumFractionDigits: 1});
const regionNames = typeof Intl.DisplayNames === 'function'
  ? new Intl.DisplayNames(['en'], {type: 'region'})
  : null;

function amount(value) {
  return value == null ? '—' : numberFormat.format(value);
}

function percentage(value) {
  return value == null ? '—' : percentFormat.format(value) + '%';
}

function countryName(code) {
  if (code === 'XX' || code === '-') return 'Unknown';
  try { return regionNames?.of(code) || code; } catch { return code; }
}

function pageName(path) {
  const names = {
    '/': 'Home', '/work': 'Work', '/about': 'About', '/services': 'Services',
    '/journey': 'Journey', '/courtyard': 'Courtyard', '/writing': 'Articles',
    '/cv/': 'CV', '/brief/': 'Brief',
  };
  if (names[path]) return names[path];
  const app = state.docs.get('apps.json')?.live?.apps?.find((entry) =>
    path === '/work/' + entry.id);
  return app?.name || path;
}

function linkName(link) {
  if (link.target === 'cv') return 'CV';
  if (link.target === 'booking') return 'Book a call';
  if (link.target.startsWith('app:')) {
    const [, id, platform] = link.target.split(':');
    const app = state.docs.get('apps.json')?.live?.apps?.find((entry) =>
      entry.id === id);
    const store = {ios: 'App Store', android: 'Google Play', pub: 'pub.dev'}[platform];
    return (app?.name || id) + (platform ? ' · ' + (store || platform) : '');
  }
  if (link.target.startsWith('article:')) {
    return link.target.slice('article:'.length).replaceAll('-', ' ');
  }
  if (link.destination === 'email') return 'Email';
  if (link.destination === 'phone') return 'Phone';
  if (link.destination === '-') return 'Legacy click';
  try {
    const url = new URL(link.destination);
    return url.hostname.replace(/^www\\./, '') +
      (url.pathname === '/' ? '' : url.pathname);
  } catch {
    return link.target;
  }
}

function comparisonNote(value, previous) {
  if (!state.insights.comparison.recorded) return 'No earlier records to compare';
  if (previous === 0) {
    return value ? 'First recorded activity in this comparison' : 'No change';
  }
  const delta = Math.round((value - previous) / previous * 100);
  return (delta > 0 ? '+' : '') + delta + '% · previous ' + amount(previous);
}

function dashboardNavigate(tab) {
  dashboardTab = tab;
  dashboardSearch = '';
  dashboardSort = {key: '', direction: -1};
  render();
}

function metricCard(value, label, note) {
  const card = node('article', 'metricCard');
  card.append(
    node('p', 'metricLabel', label),
    node('strong', null, value),
    node('p', 'metricNote', note),
  );
  return card;
}

function insightCard(label, value, detail) {
  const card = node('article', 'insightCard');
  card.append(
    node('p', 'cardEyebrow', label),
    node('strong', null, value),
    node('p', 'note', detail),
  );
  return card;
}

function reportTable(title, columns, rows, options = {}) {
  const searchable = options.searchable || false;
  const empty = options.empty || 'No recorded activity in this range.';
  const section = node('section', 'analyticsCard tableCard');
  const heading = node('div', 'reportHeading');
  heading.append(node('h3', null, title));
  if (searchable) {
    const search = node('input', 'reportSearch');
    search.type = 'search';
    search.placeholder = 'Search ' + title.toLowerCase();
    search.value = dashboardSearch;
    search.setAttribute('aria-label', search.placeholder);
    search.oninput = () => {
      dashboardSearch = search.value;
      drawRows();
    };
    heading.append(search);
  }
  section.append(heading);
  const wrap = node('div', 'tableScroll');
  const table = node('table', 'dataTable reportTable');
  table.append(node('caption', 'srOnly', title));
  const thead = node('thead');
  const top = node('tr');
  const body = node('tbody');
  for (const column of columns) {
    const th = node('th');
    th.scope = 'col';
    const sort = node('button', 'quiet', column.label);
    sort.onclick = () => {
      dashboardSort = {
        key: column.key,
        direction: dashboardSort.key === column.key
          ? -dashboardSort.direction
          : -1,
      };
      drawRows();
    };
    th.append(sort);
    top.append(th);
  }
  thead.append(top);
  table.append(thead, body);
  wrap.append(table);
  section.append(wrap);

  function drawRows() {
    body.replaceChildren();
    const query = searchable ? dashboardSearch.toLowerCase() : '';
    const selected = rows.filter((row) => !query || columns.some((column) =>
      String(row[column.key] ?? '').toLowerCase().includes(query)));
    const sorting = columns.find((column) => column.key === dashboardSort.key);
    if (sorting) {
      selected.sort((leftRow, rightRow) => {
        const left = leftRow[sorting.key];
        const right = rightRow[sorting.key];
        const result = typeof left === 'number' && typeof right === 'number'
          ? left - right
          : String(left ?? '').localeCompare(String(right ?? ''));
        return dashboardSort.direction * result;
      });
    }
    [...top.children].forEach((th, index) => th.setAttribute(
      'aria-sort',
      dashboardSort.key === columns[index].key
        ? dashboardSort.direction > 0 ? 'ascending' : 'descending'
        : 'none',
    ));
    if (!selected.length) {
      const row = node('tr');
      const cell = node('td', 'note', query ? 'No matches.' : empty);
      cell.colSpan = columns.length;
      row.append(cell);
      body.append(row);
    }
    for (const entry of selected) {
      const row = node('tr');
      for (const column of columns) {
        const value = entry[column.key];
        const displayed = column.format ? column.format(value)
          : value == null ? '—'
          : typeof value === 'number' ? amount(value)
          : value;
        row.append(node('td', column.numeric ? 'numeric' : null, displayed));
      }
      body.append(row);
    }
  }
  drawRows();
  return section;
}

function timelineNote(seen) {
  const unit = seen.timeline.granularity;
  if (unit === 'hour') {
    const coverage = seen.timeline.hourlyCoverage;
    if (coverage && !coverage.complete) {
      return 'UTC hours are available for ' + amount(coverage.counted) + ' of ' +
        amount(coverage.total) + ' recorded actions. Earlier activity remains in the totals.';
    }
    return 'UTC hours · updates as recorded activity arrives';
  }
  if (unit === 'month') return 'Monthly recorded totals · UTC';
  return 'Daily recorded totals · UTC';
}

function overviewReport(seen, links, pages) {
  const layout = node('div', 'overviewGrid');
  layout.append(trafficChart(seen.timeline.series, seen.timeline.granularity,
    timelineNote(seen)));
  const insights = node('section', 'insightPanel');
  insights.append(node('p', 'cardEyebrow', 'Range summary'), node('h3', null, 'What stands out'));
  const facts = node('div', 'insightList');
  const topPage = seen.insights.topPage;
  const topLink = seen.insights.topLink;
  const busiest = seen.insights.busiestDay;
  const topCountry = seen.insights.topCountry;
  if (topPage) {
    facts.append(insightCard('Most viewed page', pageName(topPage.route),
      amount(topPage.views) + ' views · ' + percentage(topPage.share) + ' of page views'));
  }
  if (topLink) {
    facts.append(insightCard('Most clicked', linkName(topLink),
      amount(topLink.clicks) + ' clicks · ' + percentage(topLink.share) + ' of link clicks'));
  }
  if (busiest) {
    facts.append(insightCard('Busiest day', busiest.date,
      amount(busiest.views) + ' page views'));
  }
  if (topCountry) {
    facts.append(insightCard('Largest country share', countryName(topCountry.code),
      amount(topCountry.views) + ' views · ' + percentage(topCountry.share)));
  }
  if (!facts.children.length) facts.append(node('p', 'note', 'No range summary is available yet.'));
  insights.append(facts);
  layout.append(insights);
  const ranks = node('div', 'rankGrid');
  ranks.append(
    rankedBars('Top pages', pages.slice(0, 7).map((page) => ({
      name: page.name, count: page.views,
    }))),
    rankedBars('Top links & apps', links.slice(0, 7).map((link) => ({
      name: link.name, count: link.clicks,
    }))),
  );
  return [layout, ranks];
}

function linksReport(seen, links, actions, linkColumns) {
  const ranks = node('div', 'rankGrid');
  ranks.append(
    rankedBars('Click distribution', links.map((link) => ({
      name: link.name, count: link.clicks,
    }))),
    rankedBars('App detail views', (seen.appOpens || []).map((entry) => ({
      name: pageName(entry.value), count: entry.count,
    }))),
  );
  return [
    ranks,
    reportTable('All links & apps', [
      ...linkColumns,
      {key: 'share', label: 'Share', numeric: true, format: percentage},
      {key: 'destination', label: 'Destination'},
    ], links, {searchable: true}),
    reportTable('Other interactions', [
      {key: 'name', label: 'Action'},
      {key: 'target', label: 'Item'},
      {key: 'page', label: 'Page'},
      {key: 'count', label: 'Count', numeric: true},
    ], actions),
  ];
}

function pagesReport(pages, pageColumns) {
  const ranks = node('div', 'rankGrid');
  ranks.append(
    rankedBars('Page views', pages.map((page) => ({name: page.name, count: page.views}))),
    rankedBars('Page interactions', pages.map((page) => ({
      name: page.name, count: page.interactions,
    }))),
  );
  const note = node('p', 'reportNote',
    'Active time excludes hidden tabs. Scroll depth is the average reported quartile from 1 to 4.');
  return [
    ranks,
    reportTable('Page performance', pageColumns, pages, {searchable: true}),
    note,
  ];
}

function audienceReport(seen) {
  const referrers = seen.referrers.map((entry) => ({
    name: entry.value === '-' ? 'Direct / unavailable' : entry.value,
    count: entry.count,
  }));
  const devices = seen.devices.map((entry) => ({
    name: entry.value === 'touch' ? 'Touch'
      : entry.value === 'pointer' ? 'Mouse / trackpad'
      : entry.value,
    count: entry.count,
  }));
  const campaigns = seen.campaigns.map((entry) => ({name: entry.value, count: entry.count}));
  const countries = seen.countries.map((entry) => ({
    name: countryName(entry.value), code: entry.value, count: entry.count,
    share: seen.views ? Math.round(entry.count / seen.views * 1000) / 10 : null,
  }));
  const ranks = node('div', 'rankGrid audienceRanks');
  ranks.append(
    rankedBars('Traffic sources', referrers),
    rankedBars('Input devices', devices),
    rankedBars('Campaigns', campaigns, 'No campaign-tagged page views in this range.'),
  );
  return [
    countryMap(seen.countries, seen.views),
    ranks,
    seriesChart(
      'Daily unique visitors',
      seen.dailyUniques,
      'A daily estimate only. Different days cannot be added into a monthly people total.',
      true,
    ),
    reportTable('Countries', [
      {key: 'name', label: 'Country'},
      {key: 'code', label: 'Code'},
      {key: 'count', label: 'Page views', numeric: true},
      {key: 'share', label: 'Share', numeric: true, format: percentage},
    ], countries),
  ];
}

function renderDashboard() {
  const pane = el('editor');
  pane.replaceChildren();
  pane.classList.add('dashboard');
  pane.append(pageHeading('Analytics', 'Portfolio traffic, content and audience from recorded first-party activity.'));

  const toolbar = node('section', 'dashboardToolbar');
  const nav = node('div', 'reportTabs');
  nav.setAttribute('role', 'tablist');
  nav.setAttribute('aria-label', 'Analytics reports');
  for (const [id, label] of dashboardTabs) {
    const button = node('button', 'quiet', label);
    button.setAttribute('role', 'tab');
    button.setAttribute('aria-selected', String(dashboardTab === id));
    button.onclick = () => dashboardNavigate(id);
    nav.append(button);
  }
  toolbar.append(nav, rangePicker());
  pane.append(toolbar);

  if (!state.insights && !state.insightsError) {
    const loading = node('div', 'dashboardLoading');
    loading.append(node('p', 'cardEyebrow', 'Analytics'), node('h3', null, 'Loading recorded activity…'));
    pane.append(loading);
    if (!insightsLoading) loadInsights();
    return;
  }
  if (state.insightsError) {
    const error = node('div', 'dashboardError');
    error.setAttribute('role', 'alert');
    error.append(node('p', 'issue', state.insightsError));
    const retry = node('button', 'small', 'Try again');
    retry.onclick = refreshInsights;
    error.append(retry);
    pane.append(error);
    return;
  }

  const seen = state.insights;
  const recorded = seen.collection.rowsInRange > 0;
  const status = node('div', 'collectionHealth');
  const statusCopy = node('div');
  const last = seen.metadata?.lastEventAt;
  statusCopy.append(node('strong', null,
    seen.configuration.knownDisabled ? 'Collection disabled'
      : last ? 'Collection active' : 'Waiting for the first visit'));
  if (last) {
    statusCopy.append(node('span', 'note',
      'Last event ' + new Date(last).toLocaleString('en-GB', {timeZone: 'UTC'}) + ' UTC'));
  }
  status.append(statusCopy);
  const download = node('button', 'small', 'Export CSV');
  download.onclick = exportDashboard;
  download.disabled = !recorded;
  status.append(download);
  pane.append(status);

  const metrics = node('section', 'dashboardMetrics');
  metrics.setAttribute('aria-label', 'Range totals');
  metrics.append(
    metricCard(recorded ? amount(seen.views) : '—', 'Page views',
      comparisonNote(seen.views, seen.comparison.views)),
    metricCard(recorded ? amount(seen.clicks) : '—', 'Link clicks',
      comparisonNote(seen.clicks, seen.comparison.clicks)),
    metricCard(recorded ? amount(seen.downloads) : '—', 'CV opens',
      comparisonNote(seen.downloads, seen.comparison.downloads)),
    metricCard(percentage(seen.clicksPer100Views), 'Clicks per 100 views',
      'Click activations divided by page views'),
  );
  pane.append(metrics);

  if (!recorded) {
    const empty = node('div', 'dashboardEmpty');
    empty.append(
      node('h3', null, 'No activity recorded for these dates'),
      node('p', 'note', seen.configuration.note),
    );
    pane.append(empty);
  }

  const links = (seen.links || []).map((link) => ({
    name: linkName(link),
    destination: link.destination,
    kind: link.kind,
    clicks: link.clicks,
    share: link.share,
    from: link.pages.map((page) =>
      pageName(page.route) + ' (' + page.count + ')').join(', '),
  }));
  const pages = (seen.pages || []).map((page) => ({...page, name: pageName(page.route)}));
  const actions = (seen.actions || []).map((action) => ({
    name: eventNames[action.event] || action.event,
    target: action.target === '-' ? '—' : action.target,
    page: pageName(action.route),
    count: action.count,
  }));
  const linkColumns = [
    {key: 'name', label: 'Link or app'},
    {key: 'kind', label: 'Type'},
    {key: 'clicks', label: 'Clicks', numeric: true},
    {key: 'from', label: 'Source pages'},
  ];
  const pageColumns = [
    {key: 'name', label: 'Page'},
    {key: 'views', label: 'Views', numeric: true},
    {key: 'viewShare', label: 'View share', numeric: true, format: percentage},
    {key: 'interactions', label: 'Interactions', numeric: true},
    {key: 'clicks', label: 'Link clicks', numeric: true},
    {key: 'meanSeconds', label: 'Avg active time', numeric: true,
      format: (value) => value == null ? '—' : amount(value) + 's'},
    {key: 'meanDepth', label: 'Avg scroll depth', numeric: true,
      format: (value) => value == null ? '—' : amount(value) + ' / 4'},
  ];

  let sections;
  if (dashboardTab === 'overview') sections = overviewReport(seen, links, pages);
  else if (dashboardTab === 'links') sections = linksReport(seen, links, actions, linkColumns);
  else if (dashboardTab === 'pages') sections = pagesReport(pages, pageColumns);
  else sections = audienceReport(seen);
  pane.append(...sections);

  const details = node('details', 'reportFootnote');
  details.append(node('summary', null, 'How these numbers are calculated'));
  details.append(
    node('p', 'note', 'Admin previews are excluded. Clicks count activations, not successful downloads, installs, bookings or messages. Direct and unavailable referrers cannot be separated.'),
    node('p', 'note', seen.uniqueVisitors.whyNoTotal),
    node('p', 'note', 'Aggregate retention is 24 months. Daily visitor hashes live for at most two days. Device data describes touch or pointer input, not a phone model.'),
  );
  pane.append(details);

  const publication = node('details', 'reportFootnote');
  publication.append(node('summary', null, 'Publication status'));
  publication.open = dashboardPublicationOpen;
  if (dashboardPublicationOpen) publication.append(releaseSection());
  publication.ontoggle = () => {
    dashboardPublicationOpen = publication.open;
    if (publication.open && publication.children.length === 1) {
      publication.append(releaseSection());
    }
  };
  pane.append(publication);
}

function exportDashboard() {
  const report = state.insights;
  let rows;
  if (dashboardTab === 'links') {
    rows = [
      ['Link or app', 'Destination', 'Type', 'Clicks', 'Click share', 'Source pages'],
      ...report.links.map((link) => [
        linkName(link), link.destination, link.kind, link.clicks, link.share,
        link.pages.map((page) => page.route + ': ' + page.count).join('; '),
      ]),
    ];
  } else if (dashboardTab === 'pages') {
    rows = [
      ['Page', 'Views', 'View share', 'Interactions', 'Link clicks', 'Average active seconds', 'Average scroll quartile'],
      ...report.pages.map((page) => [
        page.route, page.views, page.viewShare, page.interactions, page.clicks,
        page.meanSeconds, page.meanDepth,
      ]),
    ];
  } else if (dashboardTab === 'audience') {
    rows = [
      ['Dimension', 'Category', 'Page views'],
      ...['countries', 'devices', 'referrers', 'campaigns'].flatMap((key) =>
        report[key].map((entry) => [key, entry.value, entry.count])),
    ];
  } else {
    rows = [
      ['Period (UTC)', 'Page views', 'Link clicks'],
      ...report.timeline.series.map((point) => [point.label, point.views, point.clicks]),
    ];
  }
  const quote = (value) => {
    let text = String(value ?? '');
    if (/^[=+@\\-\\t\\r]/.test(text)) text = "'" + text;
    return '"' + text.replace(/"/g, '""') + '"';
  };
  const csv = rows.map((row) => row.map(quote).join(',')).join('\\r\\n');
  const url = URL.createObjectURL(new Blob([csv], {type: 'text/csv;charset=utf-8'}));
  const anchor = node('a');
  anchor.href = url;
  anchor.download = 'portfolio-' + dashboardTab + '-' +
    report.range.from + '-' + report.range.to + '.csv';
  anchor.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}
`;

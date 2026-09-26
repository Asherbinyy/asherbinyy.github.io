import {summarise, isoDay} from './insights.js';

const dayMs = 86400000;
const clickEvents = new Set(['outbound_click', 'cv_opened']);
const excludedPageActions = new Set(['route_view', 'section_dwell', 'scroll_depth']);
const sum = (rows) => rows.reduce((total, row) => total + row.count, 0);

function group(rows, keyOf) {
  const groups = new Map();
  for (const row of rows) {
    const key = keyOf(row);
    groups.set(key, (groups.get(key) ?? 0) + row.count);
  }
  return [...groups]
    .map(([value, count]) => ({value, count}))
    .sort((left, right) => right.count - left.count ||
      String(left.value).localeCompare(String(right.value)));
}

function rangeLength({from, to}) {
  return Math.round((Date.parse(to) - Date.parse(from)) / dayMs) + 1;
}

function granularity(range) {
  const days = rangeLength(range);
  if (days === 1) return 'hour';
  if (days <= 93) return 'day';
  return 'month';
}

function periodKey(row, unit) {
  if (unit === 'hour') {
    return row.dimensions[9] === undefined ? null : row.dimensions[9] + ':00';
  }
  if (unit === 'month') return row.dimensions[0].slice(0, 7);
  return row.dimensions[0];
}

function temporalSeries(views, linkRows, unit) {
  const viewGroups = new Map(group(
    views.filter((row) => periodKey(row, unit) !== null),
    (row) => periodKey(row, unit),
  ).map((entry) => [entry.value, entry.count]));
  const clickGroups = new Map(group(
    linkRows.filter((row) => periodKey(row, unit) !== null),
    (row) => periodKey(row, unit),
  ).map((entry) => [entry.value, entry.count]));
  const keys = new Set([...viewGroups.keys(), ...clickGroups.keys()]);
  return [...keys].sort().map((key) => ({
    key,
    label: key,
    views: viewGroups.get(key) ?? 0,
    clicks: clickGroups.get(key) ?? 0,
  }));
}

function percent(numerator, denominator) {
  return denominator ? Math.round(numerator / denominator * 1000) / 10 : null;
}

export function previousRange({from, to}) {
  const length = Date.parse(to) - Date.parse(from) + dayMs;
  return {
    from: isoDay(new Date(Date.parse(from) - length)),
    to: isoDay(new Date(Date.parse(from) - dayMs)),
  };
}

/** All ratios name their denominator. Repeated clicks are not conversions. */
export function dashboardReport(snapshot, range) {
  const report = summarise(snapshot.counters, snapshot.totals, range);
  const priorRange = previousRange(range);
  const prior = summarise(snapshot.counters, snapshot.totals, priorRange);
  const inRange = (row, selected) =>
    row.dimensions[0] >= selected.from && row.dimensions[0] <= selected.to;
  const ordinary = snapshot.counters.filter((row) =>
    row.dimensions.length > 2 && inRange(row, range));
  const priorOrdinary = snapshot.counters.filter((row) =>
    row.dimensions.length > 2 && inRange(row, priorRange));
  const views = ordinary.filter((row) => row.dimensions[1] === 'route_view');
  const priorViews = priorOrdinary.filter((row) =>
    row.dimensions[1] === 'route_view');
  const linkRows = ordinary.filter((row) => clickEvents.has(row.dimensions[1]));
  const priorLinkRows = priorOrdinary.filter((row) =>
    clickEvents.has(row.dimensions[1]));
  const unit = granularity(range);

  const links = new Map();
  for (const row of linkRows) {
    const [, event, route, , , , , target = '-', destination = '-'] =
      row.dimensions;
    const key = JSON.stringify([target, destination]);
    const held = links.get(key) ?? {
      target,
      destination,
      clicks: 0,
      pages: new Map(),
      kind: event === 'cv_opened' ? 'CV'
        : target.startsWith('app:') ? 'App'
        : target.startsWith('article:') ? 'Article'
        : 'Link',
    };
    held.clicks += row.count;
    held.pages.set(route, (held.pages.get(route) ?? 0) + row.count);
    links.set(key, held);
  }

  const byPage = new Map();
  for (const row of ordinary) {
    const route = row.dimensions[2];
    const held = byPage.get(route) ?? {
      route,
      views: 0,
      clicks: 0,
      interactions: 0,
      meanSeconds: null,
      meanDepth: null,
    };
    if (row.dimensions[1] === 'route_view') held.views += row.count;
    else if (!['section_dwell', 'scroll_depth'].includes(row.dimensions[1])) {
      held.interactions += row.count;
    }
    if (clickEvents.has(row.dimensions[1])) held.clicks += row.count;
    byPage.set(route, held);
  }
  for (const mean of report.means) {
    const held = byPage.get(mean.route);
    if (held && mean.event === 'section_dwell') held.meanSeconds = mean.mean;
    if (held && mean.event === 'scroll_depth') held.meanDepth = mean.mean;
  }

  const clicked = sum(linkRows);
  const downloads = sum(ordinary.filter((row) =>
    row.dimensions[1] === 'cv_opened'));
  const previousClicks = sum(priorLinkRows);
  const previousDownloads = sum(priorOrdinary.filter((row) =>
    row.dimensions[1] === 'cv_opened'));
  const dailyViews = group(views, (row) => row.dimensions[0]);
  const countries = group(views, (row) => row.dimensions[3]);
  const pages = [...byPage.values()].map((page) => ({
    ...page,
    viewShare: percent(page.views, report.views),
    clicksPer100Views: percent(page.clicks, page.views),
    interactionsPer100Views: percent(page.interactions, page.views),
  })).sort((left, right) => right.views - left.views ||
    left.route.localeCompare(right.route));
  const resolvedLinks = [...links.values()].map((link) => ({
    ...link,
    share: percent(link.clicks, clicked),
    pages: [...link.pages]
      .map(([route, count]) => ({route, count}))
      .sort((left, right) => right.count - left.count),
  })).sort((left, right) => right.clicks - left.clicks ||
    left.target.localeCompare(right.target));
  const actionRows = ordinary.filter((row) =>
    !excludedPageActions.has(row.dimensions[1]) &&
    !clickEvents.has(row.dimensions[1]));
  const actions = group(actionRows, (row) => JSON.stringify([
    row.dimensions[1], row.dimensions[7] ?? '-', row.dimensions[2],
  ])).map(({value, count}) => {
    const [event, target, route] = JSON.parse(value);
    return {event, target, route, count};
  });

  const timelineRows = [...views, ...linkRows];
  const hourlyCount = timelineRows
    .filter((row) => row.dimensions[9] !== undefined)
    .reduce((total, row) => total + row.count, 0);
  const ordinaryCount = sum(timelineRows);
  const topPage = pages[0] ?? null;
  const topLink = resolvedLinks[0] ?? null;
  const topCountry = countries[0] ?? null;
  const busiestDay = dailyViews[0] ?? null;
  const series = temporalSeries(views, linkRows, unit);

  return {
    ...report,
    clicks: clicked,
    downloads,
    clicksPer100Views: percent(clicked, report.views),
    comparison: {
      range: priorRange,
      views: prior.views,
      clicks: previousClicks,
      downloads: previousDownloads,
      clicksPer100Views: percent(previousClicks, prior.views),
      recorded: prior.collection.rowsInRange > 0,
    },
    timeline: {
      granularity: unit,
      series,
      previous: temporalSeries(priorViews, priorLinkRows, unit),
      hourlyCoverage: unit === 'hour' ? {
        counted: hourlyCount,
        total: ordinaryCount,
        complete: ordinaryCount === hourlyCount,
      } : null,
    },
    // Kept for old clients during a Worker-first deployment.
    trend: series.map((point) => ({
      date: point.key,
      views: point.views,
      clicks: point.clicks,
    })),
    links: resolvedLinks,
    actions,
    pages,
    countries,
    devices: group(views, (row) => row.dimensions[4]),
    referrers: group(views, (row) => row.dimensions[5]),
    campaigns: group(views, (row) => row.dimensions[6])
      .filter((row) => row.value !== '-'),
    appOpens: group(
      views.filter((row) => /^\/work\/[^/]+$/.test(row.dimensions[2])),
      (row) => row.dimensions[2],
    ),
    insights: {
      topPage: topPage ? {
        route: topPage.route,
        views: topPage.views,
        share: topPage.viewShare,
      } : null,
      topLink: topLink ? {
        target: topLink.target,
        destination: topLink.destination,
        clicks: topLink.clicks,
        share: topLink.share,
      } : null,
      topCountry: topCountry ? {
        code: topCountry.value,
        views: topCountry.count,
        share: percent(topCountry.count, report.views),
      } : null,
      busiestDay: busiestDay ? {
        date: busiestDay.value,
        views: busiestDay.count,
      } : null,
      activeDays: new Set(views.map((row) => row.dimensions[0])).size,
    },
    metadata: snapshot.metadata ?? null,
  };
}

/** Queries and fragments can contain input. Only public app-store IDs survive. */
export function publicDestination(value) {
  if (value === undefined || value === null) return null;
  if (typeof value !== 'string' || value.length > 500) {
    throw new TypeError('Invalid destination');
  }
  if (['email', 'phone'].includes(value)) return value;
  const url = new URL(value);
  if (!['https:', 'http:'].includes(url.protocol) || url.username ||
      url.password) {
    throw new TypeError('Invalid destination');
  }
  const id = url.hostname === 'play.google.com' ? url.searchParams.get('id') : null;
  url.search = '';
  url.hash = '';
  if (id && /^[A-Za-z0-9_.]{1,160}$/.test(id)) url.searchParams.set('id', id);
  return url.toString();
}

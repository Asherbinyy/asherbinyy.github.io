import {summarise, isoDay} from './insights.js';

const dayMs = 86400000;
const clicks = new Set(['outbound_click', 'cv_opened']);
const sum = (rows) => rows.reduce((n, row) => n + row.count, 0);
function group(rows, keyOf) {
  const groups = new Map();
  for (const row of rows) {
    const key = keyOf(row);
    groups.set(key, (groups.get(key) ?? 0) + row.count);
  }
  return [...groups].map(([value, count]) => ({value, count}))
    .sort((a, b) => b.count - a.count || a.value.localeCompare(b.value));
}

export function previousRange({from, to}) {
  const length = Date.parse(to) - Date.parse(from) + dayMs;
  return {from: isoDay(new Date(Date.parse(from) - length)), to: isoDay(new Date(Date.parse(from) - dayMs))};
}

/** All ratios name their denominator. Repeated clicks are not conversions. */
export function dashboardReport(snapshot, range) {
  const report = summarise(snapshot.counters, snapshot.totals, range);
  const priorRange = previousRange(range);
  const prior = summarise(snapshot.counters, snapshot.totals, priorRange);
  const inRange = (row, r) => row.dimensions[0] >= r.from && row.dimensions[0] <= r.to;
  const rows = snapshot.counters.filter((row) => row.dimensions.length > 2 && inRange(row, range));
  const views = rows.filter((r) => r.dimensions[1] === 'route_view');
  const linkRows = rows.filter((r) => clicks.has(r.dimensions[1]));
  const dailyViews = group(views, (r) => r.dimensions[0]);
  const dailyClicks = group(linkRows, (r) => r.dimensions[0]);
  const dates = new Set([...dailyViews, ...dailyClicks].map((d) => d.value));
  const links = new Map();
  for (const row of linkRows) {
    const [, event, route, , , , , target = '-', destination = '-'] = row.dimensions;
    const key = JSON.stringify([target, destination]);
    const held = links.get(key) ?? {target, destination, clicks: 0, pages: new Map()};
    held.clicks += row.count;
    held.pages.set(route, (held.pages.get(route) ?? 0) + row.count);
    held.kind = event === 'cv_opened' ? 'CV' : target.startsWith('app:') ? 'App' : target.startsWith('article:') ? 'Article' : 'Link';
    links.set(key, held);
  }
  const byPage = new Map();
  for (const row of rows) {
    const route = row.dimensions[2];
    const held = byPage.get(route) ?? {route, views: 0, clicks: 0, interactions: 0, meanSeconds: null, meanDepth: null};
    if (row.dimensions[1] === 'route_view') held.views += row.count;
    else if (!['section_dwell', 'scroll_depth'].includes(row.dimensions[1])) held.interactions += row.count;
    if (clicks.has(row.dimensions[1])) held.clicks += row.count;
    byPage.set(route, held);
  }
  for (const mean of report.means) {
    const held = byPage.get(mean.route);
    if (held && mean.event === 'section_dwell') held.meanSeconds = mean.mean;
    if (held && mean.event === 'scroll_depth') held.meanDepth = mean.mean;
  }
  const clicked = sum(linkRows);
  const downloads = sum(rows.filter((r) => r.dimensions[1] === 'cv_opened'));
  const previousClicks = sum(snapshot.counters.filter((r) => inRange(r, priorRange) && clicks.has(r.dimensions[1])));
  const actionRows = rows.filter((r) =>
    !['route_view', 'outbound_click', 'cv_opened', 'section_dwell', 'scroll_depth'].includes(r.dimensions[1]));
  const actions = group(actionRows, (r) => JSON.stringify([
    r.dimensions[1], r.dimensions[7] ?? '-', r.dimensions[2],
  ])).map(({value, count}) => {
    const [event, target, route] = JSON.parse(value);
    return {event, target, route, count};
  });
  return {
    ...report,
    clicks: clicked,
    downloads,
    // A click count may exceed views. Do not call this a visitor conversion rate.
    clicksPer100Views: report.views ? Math.round(clicked / report.views * 1000) / 10 : null,
    comparison: {range: priorRange, views: prior.views, clicks: previousClicks,
      recorded: prior.collection.rowsInRange > 0},
    trend: [...dates].sort().map((date) => ({date,
      views: dailyViews.find((d) => d.value === date)?.count ?? 0,
      clicks: dailyClicks.find((d) => d.value === date)?.count ?? 0})),
    links: [...links.values()].map((link) => ({...link,
      pages: [...link.pages].map(([route, count]) => ({route, count})).sort((a,b) => b.count-a.count),
    })).sort((a,b) => b.clicks-a.clicks || a.target.localeCompare(b.target)),
    actions,
    pages: [...byPage.values()].sort((a,b) => b.views-a.views || a.route.localeCompare(b.route)),
    // Audience shares count page views consistently, never unrelated events.
    countries: group(views, (r) => r.dimensions[3]),
    devices: group(views, (r) => r.dimensions[4]),
    referrers: group(views, (r) => r.dimensions[5]),
    campaigns: group(views, (r) => r.dimensions[6]).filter((r) => r.value !== '-'),
    appOpens: group(views.filter((r) => /^\/work\/[^/]+$/.test(r.dimensions[2])), (r) => r.dimensions[2]),
    metadata: snapshot.metadata ?? null,
  };
}

/** Queries and fragments can contain input. Only public app-store IDs survive. */
export function publicDestination(value) {
  if (value === undefined || value === null) return null;
  if (typeof value !== 'string' || value.length > 500) throw new TypeError('Invalid destination');
  if (['email', 'phone'].includes(value)) return value;
  const url = new URL(value);
  if (!['https:', 'http:'].includes(url.protocol) || url.username || url.password) throw new TypeError('Invalid destination');
  const id = url.hostname === 'play.google.com' ? url.searchParams.get('id') : null;
  url.search = '';
  url.hash = '';
  if (id && /^[A-Za-z0-9_.]{1,160}$/.test(id)) url.searchParams.set('id', id);
  return url.toString();
}

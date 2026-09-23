import assert from 'node:assert/strict';
import test from 'node:test';

import {handleRequest} from '../src/index.js';
import {defaultRange, summarise, validDay} from '../src/insights.js';
import {admin, environment} from './support.js';

/// An ordinary counter row, the shape `aggregateSnapshot` returns.
function counter(date, event, route, extra = {}) {
  return {
    dimensions: [
      date,
      event,
      route,
      extra.country ?? 'GB',
      extra.device ?? 'desktop',
      extra.referrer ?? '-',
      extra.campaign ?? '-',
    ],
    count: extra.count ?? 1,
  };
}

/// The other shape: two dimensions, not seven.
function unique(date, count) {
  return {dimensions: [date, 'unique_visitor'], count};
}

const range = {from: '2026-09-01', to: '2026-09-07'};

// --- the two row shapes ----------------------------------------------------

test('a unique-visitor row is never read as though it had a route', () => {
  // Seven-dimension arithmetic over a two-dimension row is how a dashboard
  // grows a route called "undefined".
  const seen = summarise(
    [counter('2026-09-02', 'route_view', '/work'), unique('2026-09-02', 4)],
    [],
    range,
  );
  assert.deepEqual(seen.routes.map((entry) => entry.value), ['/work']);
  assert.ok(seen.events.every((entry) => entry.value !== 'unique_visitor'));
  assert.equal(seen.shapes.uniqueVisitor, 1);
  assert.equal(seen.shapes.ordinary, 1);
});

test('unique visitors are counted separately from views', () => {
  const seen = summarise(
    [counter('2026-09-02', 'route_view', '/', {count: 9}), unique('2026-09-02', 3)],
    [],
    range,
  );
  assert.equal(seen.views, 9);
  assert.deepEqual(seen.dailyUniques, [{date: '2026-09-02', count: 3}]);
});

// --- the aggregate that must not be invented -------------------------------

test('daily unique counts are not added into a total', () => {
  // The salt rotates at midnight, so the same person on three days is three
  // hashes. A "9" here would be a lie with a number on it.
  const seen = summarise(
    [unique('2026-09-01', 3), unique('2026-09-02', 3), unique('2026-09-03', 3)],
    [],
    range,
  );
  assert.equal(seen.uniqueVisitors.total, null);
  assert.match(seen.uniqueVisitors.whyNoTotal, /salt/);
});

test('the honest multi-day figure is the busiest single day', () => {
  const seen = summarise(
    [unique('2026-09-01', 3), unique('2026-09-02', 11), unique('2026-09-03', 5)],
    [],
    range,
  );
  assert.deepEqual(seen.uniqueVisitors.busiestDay, {date: '2026-09-02', count: 11});
});

test('no unique rows means no busiest day, not a zero', () => {
  const seen = summarise([counter('2026-09-02', 'route_view', '/')], [], range);
  assert.equal(seen.uniqueVisitors.busiestDay, null);
});

// --- ranges ----------------------------------------------------------------

test('rows outside the range are left out', () => {
  const seen = summarise(
    [
      counter('2026-08-30', 'route_view', '/', {count: 5}),
      counter('2026-09-03', 'route_view', '/', {count: 2}),
      counter('2026-09-30', 'route_view', '/', {count: 7}),
    ],
    [],
    range,
  );
  assert.equal(seen.views, 2);
  assert.equal(seen.collection.rowsInRange, 1);
  // But the panel is still told the whole store is not empty, which is a
  // different thing from this range being empty.
  assert.equal(seen.collection.rowsEver, 3);
  assert.equal(seen.collection.firstDate, '2026-08-30');
  assert.equal(seen.collection.lastDate, '2026-09-30');
});

test('an empty store reports empty rather than zero-filled days', () => {
  const seen = summarise([], [], range);
  assert.equal(seen.collection.rowsEver, 0);
  assert.deepEqual(seen.byDay, []);
  assert.deepEqual(seen.events, []);
  assert.equal(seen.collection.lastDate, null);
});

test('the default range is the last four weeks in UTC', () => {
  const seen = defaultRange(new Date('2026-09-12T09:00:00Z'));
  assert.deepEqual(seen, {from: '2026-08-16', to: '2026-09-12'});
});

test('only a real calendar day is accepted as a range edge', () => {
  assert.ok(validDay('2026-09-12'));
  assert.ok(!validDay('12/09/2026'));
  assert.ok(!validDay('2026-13-40'));
  assert.ok(!validDay(''));
});

// --- breakdowns ------------------------------------------------------------

test('breakdowns are ordered by size and name the real dimensions', () => {
  const seen = summarise(
    [
      counter('2026-09-02', 'route_view', '/work', {country: 'GB', count: 2}),
      counter('2026-09-02', 'route_view', '/about', {country: 'EG', count: 5}),
      counter('2026-09-03', 'cv_opened', '/about', {country: 'EG', count: 1}),
    ],
    [],
    range,
  );
  assert.deepEqual(seen.routes.map((entry) => entry.value), ['/about', '/work']);
  assert.deepEqual(seen.countries[0], {value: 'EG', count: 6});
  assert.equal(seen.views, 7);
  assert.equal(seen.interactions, 1);
});

test('an absent referrer or campaign is not shown as a dash', () => {
  const seen = summarise(
    [
      counter('2026-09-02', 'route_view', '/'),
      counter('2026-09-02', 'route_view', '/', {referrer: 'medium.com'}),
    ],
    [],
    range,
  );
  assert.deepEqual(seen.referrers, [{value: 'medium.com', count: 1}]);
  assert.deepEqual(seen.campaigns, []);
});

// --- means -----------------------------------------------------------------

test('a mean says what its unit is', () => {
  // 3.2 quartiles and 3.2 seconds are different facts.
  const seen = summarise(
    [counter('2026-09-02', 'section_dwell', '/work', {count: 4})],
    [{dimensions: ['2026-09-02', 'section_dwell', '/work'], total: 200}],
    range,
  );
  assert.equal(seen.means.length, 1);
  assert.equal(seen.means[0].mean, 50);
  assert.equal(seen.means[0].unit, 'seconds');
  assert.equal(seen.means[0].samples, 4);
});

test('a total with no matching counter produces no mean', () => {
  const seen = summarise(
    [],
    [{dimensions: ['2026-09-02', 'scroll_depth', '/work'], total: 12}],
    range,
  );
  assert.deepEqual(seen.means, []);
});

// --- the endpoint ----------------------------------------------------------

test('the dashboard needs the admin token', async () => {
  const refused = await handleRequest(
    admin('/v1/admin/insights', {token: null}),
    environment(),
  );
  assert.equal(refused.status, 401);
});

test('the dashboard answers with an empty range and says collection is off', async () => {
  const response = await handleRequest(admin('/v1/admin/insights'), environment());
  assert.equal(response.status, 200);
  const body = await response.json();
  assert.equal(body.collection.rowsEver, 0);
  assert.equal(body.configuration.knownDisabled, true);
  assert.equal(body.range.timezone, 'UTC');
});

test('a range that ends before it starts is refused', async () => {
  const response = await handleRequest(
    admin('/v1/admin/insights?from=2026-09-10&to=2026-09-01'),
    environment(),
  );
  assert.equal(response.status, 400);
});

test('a nonsense range falls back to the default rather than failing', async () => {
  const response = await handleRequest(
    admin('/v1/admin/insights?from=yesterday&to=soon'),
    environment(),
  );
  assert.equal(response.status, 200);
  assert.match((await response.json()).range.from, /^\d{4}-\d{2}-\d{2}$/);
});

test('reading the dashboard writes nothing', async () => {
  // It is a report over counters. If looking at it could move a number, the
  // number would stop meaning anything.
  const env = environment();
  await env.ANALYTICS.put('counter|2026-09-02|route_view|/|GB|desktop|-|-', '4');
  const before = env.ANALYTICS.values.size;
  await handleRequest(admin('/v1/admin/insights'), env);
  assert.equal(env.ANALYTICS.values.size, before);
});

test('counters already stored are reported', async () => {
  const env = environment();
  const today = new Date().toISOString().slice(0, 10);
  await env.ANALYTICS.put(`counter|${today}|route_view|%2Fwork|GB|desktop|-|-`, '6');
  await env.ANALYTICS.put(`counter|${today}|unique_visitor`, '2');
  const body = await (await handleRequest(admin('/v1/admin/insights'), env)).json();
  assert.equal(body.views, 6);
  assert.deepEqual(body.routes, [{value: '/work', count: 6}]);
  assert.deepEqual(body.dailyUniques, [{date: today, count: 2}]);
  assert.equal(body.uniqueVisitors.total, null);
});

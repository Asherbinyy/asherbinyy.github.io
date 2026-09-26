import assert from 'node:assert/strict';
import test from 'node:test';
import {AnalyticsStore, analyticsOperation} from '../src/analytics-store.js';
import {dashboardReport, publicDestination} from '../src/analytics-report.js';
import {durableNamespace} from '../dev/durable-double.js';
import {handleRequest} from '../src/index.js';
import {admin, environment, siteOrigin} from './support.js';

const time = Date.parse('2026-09-24T12:00:00Z');
const base = {op: 'record', country: 'GB', address: '192.0.2.1', agent: 'Test browser', now: time,
  beacon: {event: 'route_view', route: '/work', deviceClass: 'pointer'}};
function setup() { return environment({ANALYTICS_STORE: durableNamespace(AnalyticsStore), ANALYTICS_ENABLED: 'true'}); }
const record = (env, input = {}) => analyticsOperation(env, {...base, ...input});
const read = (env) => analyticsOperation(env, {op: 'snapshot'});

test('concurrent visits cannot lose a view or double count a daily visitor', async () => {
  const env = setup();
  await Promise.all(Array.from({length: 30}, () => record(env)));
  const rows = (await read(env)).counters;
  assert.equal(rows.find(r => r.dimensions[1] === 'route_view').count, 30);
  assert.equal(rows.find(r => r.dimensions[1] === 'unique_visitor').count, 1);
  const saved = JSON.stringify([...env.ANALYTICS_STORE.state.storage.map]);
  assert.ok(!saved.includes(base.address));
  assert.ok(!saved.includes(base.agent));
});

test('storage failure rolls the whole event back', async () => {
  const env = setup();
  env.ANALYTICS_STORE.state.storage.failOn = 'unique|2026-09-24';
  await assert.rejects(() => record(env));
  assert.deepEqual((await read(env)).counters, []);
});

test('salt rolls on the UTC date and unrelated days cannot be linked', async () => {
  const env = setup();
  await record(env);
  const first = await env.ANALYTICS_STORE.state.storage.get('salt');
  await record(env, {now: time + 86400000});
  const second = await env.ANALYTICS_STORE.state.storage.get('salt');
  assert.notEqual(first.value, second.value);
  const keys = [...env.ANALYTICS_STORE.state.storage.map.keys()].filter(k => k.startsWith('visitor|'));
  assert.notEqual(keys[0].split('|')[2], keys[1].split('|')[2]);
});

test('link identity, page, and engagement sums survive storage and reporting', async () => {
  const env = setup();
  await record(env);
  await record(env, {beacon: {...base.beacon, event:'outbound_click', target:'app:sample', destination:'https://play.google.com/store/apps/details?id=uk.sample'}});
  await record(env, {beacon: {...base.beacon, event:'section_dwell', value: 20}});
  const report = dashboardReport(await read(env), {from:'2026-09-24',to:'2026-09-24'});
  assert.equal(report.views, 1);
  assert.equal(report.clicks, 1);
  assert.equal(report.links[0].target, 'app:sample');
  assert.deepEqual(report.links[0].pages, [{route:'/work',count:1}]);
  assert.equal(report.pages[0].meanSeconds, 20);
  assert.equal(report.countries[0].count, 1, 'audience is page views, not all events');
  assert.equal(report.uniqueVisitors.total, null);
});

test('today uses aggregate UTC hours while legacy rows stay in exact totals', async () => {
  const env = setup();
  await record(env);
  await record(env, {now: time + 2 * 60 * 60 * 1000});
  const snapshot = await read(env);
  assert.deepEqual(snapshot.counters
    .filter((row) => row.dimensions[1] === 'route_view')
    .map((row) => row.dimensions[9]), ['12', '14']);
  snapshot.counters.push({
    dimensions: ['2026-09-24', 'route_view', '/', 'GB', 'pointer', '-', '-', '-', '-'],
    count: 3,
  });
  const report = dashboardReport(snapshot, {from:'2026-09-24',to:'2026-09-24'});
  assert.equal(report.views,5);
  assert.equal(report.timeline.granularity,'hour');
  assert.deepEqual(report.timeline.series.map((point) => [point.key,point.views]), [
    ['12:00',1],['14:00',1],
  ]);
  assert.deepEqual(report.timeline.hourlyCoverage,{counted:2,total:5,complete:false});
});

test('long ranges group charts by month without changing totals', () => {
  const snapshot = {counters:[
    {dimensions:['2026-01-02','route_view','/','GB','pointer','-','-','-','-','09'],count:2},
    {dimensions:['2026-01-22','route_view','/work','GB','pointer','-','-','-','-','12'],count:3},
    {dimensions:['2026-03-01','outbound_click','/work','GB','pointer','-','-','app:x','-','14'],count:4},
  ],totals:[]};
  const report = dashboardReport(snapshot,{from:'2026-01-01',to:'2026-12-31'});
  assert.equal(report.views,5);
  assert.equal(report.clicks,4);
  assert.equal(report.timeline.granularity,'month');
  assert.deepEqual(report.timeline.series.map((point) =>
    [point.key,point.views,point.clicks]), [
    ['2026-01',5,0],['2026-03',0,4],
  ]);
});

test('named interactions remain attributable to an item and source page', async () => {
  const env = setup();
  await record(env, {beacon: {...base.beacon,event:'media_opened',target:'gallery:app:sample'}});
  const report = dashboardReport(await read(env), {from:'2026-09-24',to:'2026-09-24'});
  assert.deepEqual(report.actions, [{
    event:'media_opened', target:'gallery:app:sample', route:'/work', count:1,
  }]);
});

test('snapshot pagination returns every counter and bounds the date range', async () => {
  const env = setup();
  const storage = env.ANALYTICS_STORE.state.storage;
  for (let i=0; i<1005; i++) await storage.put('row|2026-09-24|' + i.toString().padStart(4,'0'), {dimensions:['2026-09-24','route_view','/'+i],count:1,total:0});
  await storage.put('row|2026-09-23|earlier', {dimensions:['2026-09-23','route_view','/'],count:1,total:0});
  const result = await analyticsOperation(env,{op:'snapshot',from:'2026-09-24',to:'2026-09-24'});
  assert.equal(result.counters.length,1005);
});

test('new pipeline records without a consent field', async () => {
  const env = setup();
  const request = new Request('https://worker.example/v1/beacon',{method:'POST',headers:{origin:siteOrigin},body:JSON.stringify(base.beacon)});
  assert.equal((await handleRequest(request,env,new Date(time))).status,202);
  assert.equal((await read(env)).counters[0].count,1);
});

test('public endpoint records and dashboard reports a real click', async () => {
  const env = setup();
  const beacon = {...base.beacon,event:'outbound_click',target:'contact:linkedin',destination:'https://linkedin.com/in/example?private=discard#secret'};
  const request = new Request('https://worker.example/v1/beacon',{method:'POST',headers:{origin:siteOrigin},body:JSON.stringify(beacon)});
  assert.equal((await handleRequest(request,env,new Date(time))).status,202);
  const result = await handleRequest(admin('/v1/admin/insights?from=2026-09-24&to=2026-09-24'),env,new Date(time));
  const report = await result.json();
  assert.equal(report.configuration.knownDisabled,false);
  assert.equal(report.configuration.atomic,true);
  assert.equal(report.links[0].destination,'https://linkedin.com/in/example');
});

test('destination redaction removes private inputs but preserves public store identity', () => {
  assert.equal(publicDestination('https://play.google.com/store/apps/details?id=uk.app&email=private'), 'https://play.google.com/store/apps/details?id=uk.app');
  assert.equal(publicDestination('email'),'email');
  assert.throws(()=> publicDestination('mailto:person@example.com'));
  assert.throws(()=> publicDestination('https://user:password@example.com/'));
});

test('previous-period comparison has equal length and a zero baseline is not growth', async () => {
  const env = setup();
  await record(env);
  const report = dashboardReport(await read(env),{from:'2026-09-24',to:'2026-09-30'});
  assert.deepEqual(report.comparison.range,{from:'2026-09-17',to:'2026-09-23'});
  assert.equal(report.comparison.recorded,false);
  assert.equal(report.clicksPer100Views,0);
});

test('rate limiting stops the 121st event without changing the counters', async () => {
  const env = setup();
  for (let i=0; i<120; i++) assert.deepEqual(await record(env), {accepted:true});
  assert.deepEqual(await record(env), {limited:true});
  const rows = (await read(env)).counters;
  assert.equal(rows.find(r => r.dimensions[1] === 'route_view').count, 120);
});

test('retention alarm removes expired details and keeps current aggregates', async () => {
  const env = setup();
  const storage = env.ANALYTICS_STORE.state.storage;
  await storage.put('row|2024-01-01|old', {dimensions:['2024-01-01','route_view','/'],count:1,total:0});
  await storage.put('unique|2024-01-01', 1);
  await storage.put('visitor|2026-09-20|old', true);
  await storage.put('rate|2026-09-20|old', {minute:1,count:1});
  await record(env);
  const originalNow = Date.now;
  Date.now = () => time;
  try { await env.ANALYTICS_STORE.object.alarm(); } finally { Date.now = originalNow; }
  assert.equal(await storage.get('row|2024-01-01|old'), undefined);
  assert.equal(await storage.get('unique|2024-01-01'), undefined);
  assert.equal(await storage.get('visitor|2026-09-20|old'), undefined);
  assert.equal(await storage.get('rate|2026-09-20|old'), undefined);
  assert.equal((await read(env)).counters.find(r => r.dimensions[1] === 'route_view').count, 1);
});

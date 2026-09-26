import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import test from 'node:test';
import vm from 'node:vm';
import {clientCharts} from '../src/admin/client-charts.js';
import {clientHome} from '../src/admin/client-home.js';
import {designTokens} from '../src/admin/design-tokens.js';
import {worldCountries} from '../src/admin/world-map-data.js';
import {adminPage} from '../src/admin.js';

class Element {
  constructor(tag, text = '') { this.tag = tag; this.textContent = text; this.children = []; this.attributes = {}; this.style = {}; }
  append(...children) { this.children.push(...children); }
  setAttribute(key, value) { this.attributes[key] = value; }
  all(tag) { return this.children.flatMap((child) => [ ...(child.tag === tag ? [child] : []), ...child.all(tag)]); }
}
function chartContext() {
  const context = vm.createContext({
    state: {insights: {range: {from: '2026-09-01', to: '2026-09-04'}}},
    node: (tag, cls, text) => new Element(tag, text),
    document: {createElementNS: (_ns, tag) => new Element(tag)},
  });
  vm.runInContext(clientCharts, context);
  return context;
}

test('empty chart has no fabricated points, axes or zeros', () => {
  const result = vm.runInContext("seriesChart('Activity', [], 'Recorded events')", chartContext());
  assert.equal(result.all('svg').length, 0);
  assert.ok(result.all('strong').some((node) => node.textContent === 'No recorded data'));
});

test('chart keeps exact counts and leaves a missing day unconnected', () => {
  const result = vm.runInContext("seriesChart('Activity', [{date:'2026-09-01',count:9},{date:'2026-09-02',count:4},{date:'2026-09-04',count:7}], 'Recorded events')", chartContext());
  assert.equal(result.all('circle').length, 3);
  assert.equal(result.all('line').filter((line) =>
    line.attributes.class?.split(' ').includes('chartLine')).length, 1);
  assert.deepEqual(result.all('tbody')[0].all('td').map((cell) => cell.textContent), ['2026-09-01', '9', '2026-09-02', '4', '2026-09-04', '7']);
  assert.equal(result.all('svg')[0].attributes.role, 'img');
});

test('single-day chart coordinates stay finite', () => {
  const context = chartContext();
  context.state.insights.range.to = '2026-09-01';
  const result = vm.runInContext("seriesChart('Daily unique visitors', [{date:'2026-09-01',count:0}], 'One day')", context);
  const point = result.all('circle')[0];
  assert.ok(Number.isFinite(Number(point.attributes.cx)));
  assert.ok(Number.isFinite(Number(point.attributes.cy)));
});

test('late insights response cannot replace a newer date range', async () => {
  const pending = [];
  const state = {view:'home', range:{id:'custom',from:'2026-09-01',to:'2026-09-02'}, insights:null, insightsError:''};
  const context = vm.createContext({state, api: () => new Promise((resolve) => pending.push(resolve)), render() {}});
  vm.runInContext(clientHome, context);
  const first = vm.runInContext('loadInsights()', context);
  state.range = {id:'custom',from:'2026-09-03',to:'2026-09-04'};
  const second = vm.runInContext('loadInsights()', context);
  pending[1]({ok:true,json:async()=>({range:{from:'2026-09-03',to:'2026-09-04'}})});
  await second;
  pending[0]({ok:true,json:async()=>({range:{from:'2026-09-01',to:'2026-09-02'}})});
  await first;
  assert.equal(state.insights.range.from, '2026-09-03');
});

test('invalid range is explained without asking the backend to substitute dates', async () => {
  let requests = 0;
  const state = {view:'home',range:{id:'custom',from:'',to:'2026-09-04'},insights:null,insightsError:''};
  const context = vm.createContext({state,api:()=>{requests++;},render(){}});
  vm.runInContext(clientHome,context);
  await vm.runInContext('loadInsights()',context);
  assert.equal(requests,0);
  assert.match(state.insightsError,/Choose a start date/);
});

test('today preset requests one UTC calendar day', () => {
  const state = {range:{id:'today',from:'',to:''}};
  const context = vm.createContext({state});
  vm.runInContext(clientHome,context);
  const range = vm.runInContext('rangeDates()',context);
  assert.equal(range.from,range.to);
  assert.match(range.from,/^\d{4}-\d{2}-\d{2}$/);
});

test('admin palettes keep the existing Flutter pigment values', async () => {
  const dart = await readFile(new URL('../../lib/app/theme/tokens.dart', import.meta.url), 'utf8');
  const source = new Set([...dart.matchAll(/Color\(0xFF([0-9A-F]{6})\)/g)].map((match) => match[1]));
  for (const [,color] of designTokens.matchAll(/#([0-9A-F]{6})/g)) assert.ok(source.has(color),color);
});

test('the local country map has usable unique ISO geometry', () => {
  assert.ok(worldCountries.length > 150);
  assert.equal(new Set(worldCountries.map((country) => country.code)).size,
    worldCountries.length);
  for (const code of ['EG','GB','US']) {
    const country = worldCountries.find((entry) => entry.code === code);
    assert.ok(country);
    assert.match(country.path,/^M/);
    assert.doesNotMatch(country.path,/NaN|Infinity/);
  }
});

test('review and reauthentication dialogs have separate, unique targets', () => {
  const html = adminPage('https://example.org');
  const markup = html.slice(html.indexOf('<body'), html.indexOf('<script'));
  const ids = [...markup.matchAll(/\bid="([^"]+)"/g)].map((match) => match[1]);
  assert.equal(new Set(ids).size, ids.length);
  assert.match(markup, /id="gateStatus" role="status"/);
});

test('the assembled browser module compiles', () => {
  const html = adminPage('https://example.org');
  const script = html.match(/<script type="module">([\s\S]*)<\/script>/)[1];
  assert.doesNotThrow(() => new vm.Script(script));
});

test('failed account read keeps password state unknown and can be retried', async () => {
  const {clientAccount} = await import('../src/admin/client-account.js');
  const state = {account:null, accountError:''};
  let ok = false;
  const context = vm.createContext({state,api:async()=>({ok,json:async()=>ok ? {kind:'session',passwordSet:true} : {error:'Account unavailable'}})});
  vm.runInContext(clientAccount,context);
  await vm.runInContext('loadAccount()',context);
  assert.equal(state.account,null);
  assert.equal(state.accountError,'Account unavailable');
  ok = true;
  await vm.runInContext('loadAccount()',context);
  assert.equal(state.account.passwordSet,true);
  assert.equal(state.accountError,'');
});

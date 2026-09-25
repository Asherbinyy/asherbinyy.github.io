/** Browser verification of populated analytics against the local-only store. */
import {launch} from './browser.js';
import {helpers} from './harness.js';

const base = process.env.ADMIN_BASE ?? 'http://localhost:8790';
const token = 'local-development-token-' + 'x'.repeat(24);
const checks = [];
const check = (name, value) => {
  checks.push({name, passed:Boolean(value)});
  process.stdout.write((value ? 'PASS ' : 'FAIL ') + name + '\n');
};
const beacon = async (event, route, extra = {}) => {
  const response = await fetch(base + '/v1/beacon', {
    method:'POST',
    headers:{origin:base, 'content-type':'application/json'},
    body:JSON.stringify({event,route,deviceClass:'pointer',...extra}),
  });
  if (response.status !== 202) throw new Error('Local beacon failed: ' + response.status);
};

await beacon('route_view','/work',{referrerHost:'example.org',campaign:'portfolio-review'});
await beacon('route_view','/about');
await beacon('outbound_click','/work',{target:'app:example-one:android',destination:'https://play.google.com/store/apps/details?id=com.example.one&private=discard'});
await beacon('outbound_click','/work',{target:'app:example-one:android',destination:'https://play.google.com/store/apps/details?id=com.example.one'});
await beacon('cv_opened','/',{target:'cv',destination:'https://sherbini.uk/cv/'});
await beacon('section_dwell','/work',{value:24});
await beacon('scroll_depth','/work',{value:3});
await beacon('media_opened','/about',{target:'gallery:interest:books'});

const page = await launch();
try {
  await page.goto(base + '/admin');
  await page.setup(helpers);
  await page.eval(`setValue('token', ${JSON.stringify(token)}); $('unlock').click()`);
  await page.settle(1600);
  check('overview opens', await page.eval("document.body.dataset.view === 'home'"));
  check('four report tabs are present', await page.eval("document.querySelectorAll('.reportTabs button').length === 4"));
  check('overview reports exact totals', await page.eval("[...document.querySelectorAll('.figure strong')].map(n=>n.textContent).slice(0,3).join('|') === '2|3|1'"));
  check('traffic graph has observed data', await page.eval("document.querySelectorAll('.chartCard svg circle').length === 1"));
  await page.eval("clickText('.reportTabs button','Links & apps')");
  await page.settle();
  check('app name and platform resolve', await page.eval("$('editor').innerText.includes('Example One · Google Play')"));
  check('private destination query is absent', await page.eval("!$('editor').innerText.includes('private=discard')"));
  check('source page and exact click count show', await page.eval("$('editor').innerText.includes('Work (2)') && $('editor').innerText.includes('com.example.one')"));
  check('named interactions show their item and page', await page.eval("$('editor').innerText.includes('Gallery opens') && $('editor').innerText.includes('gallery:interest:books') && $('editor').innerText.includes('About')"));
  await page.eval("document.querySelector('.reportSearch').value='missing'; document.querySelector('.reportSearch').dispatchEvent(new Event('input',{bubbles:true}))");
  check('link search has a real empty result', await page.eval("$('editor').innerText.includes('No matches.')"));
  await page.eval("clickText('.reportTabs button','Pages')");
  await page.settle();
  check('page engagement is shown', await page.eval("$('editor').innerText.includes('24s') && $('editor').innerText.includes('3 / 4')"));
  await page.eval("clickText('.reportTabs button','Audience')");
  await page.settle();
  check('audience uses page-view categories', await page.eval("$('editor').innerText.includes('example.org') && $('editor').innerText.includes('portfolio-review')"));
  await page.eval(`(() => {
    window.__download = {};
    URL.createObjectURL = (blob) => { window.__download.blob = blob; return 'blob:local'; };
    URL.revokeObjectURL = () => {};
    HTMLAnchorElement.prototype.click = function() { window.__download.name = this.download; };
  })()`);
  await page.eval("clickText('.collectionHealth button','Export CSV')");
  await page.settle();
  check('CSV export is populated and named', await page.eval("window.__download.name.startsWith('portfolio-audience-') && window.__download.blob.text().then(t=>t.includes('referrers') && t.includes('example.org'))",true));
  await page.viewport(390,844,true);
  check('dashboard fits a phone viewport', await page.eval("document.documentElement.scrollWidth <= innerWidth && $('editorPane').scrollWidth <= $('editorPane').clientWidth + 1"));
  await page.screenshot('/private/tmp/nocturne-analytics-dashboard.png');
  const errors = page.logs.filter((entry) => ['error','exception'].includes(entry.level));
  check('browser reports no JavaScript errors', errors.length === 0);
  if (errors.length) process.stdout.write(JSON.stringify(errors,null,2) + '\n');
} finally {
  await page.close();
}
process.stdout.write(checks.filter((entry)=>entry.passed).length + '/' + checks.length + ' passed\n');
if (checks.some((entry)=>!entry.passed)) process.exitCode = 1;

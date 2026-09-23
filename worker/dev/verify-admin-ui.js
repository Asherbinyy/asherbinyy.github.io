/** Review the rebuilt panel without seeding analytics or contacting production. */
import {mkdir, writeFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {launch} from './browser.js';
import {helpers} from './harness.js';

const base = process.env.ADMIN_BASE ?? 'http://localhost:8790';
const output = fileURLToPath(new URL('../../docs/audits/2026-09-14-admin-ui/', import.meta.url));
await mkdir(output, {recursive:true});
const checks = [];
const check = (name, value) => { checks.push({name, passed:Boolean(value)}); console.log((value ? 'PASS ' : 'FAIL ') + name); };
const page = await launch();
const pause = () => page.settle(500);
const navigate = async (label) => {
  await page.eval(`clickText('#rail > button.section', ${JSON.stringify(label)})`);
  await pause();
};
const capture = async (name) => { await page.screenshot(output + '/' + name + '.png'); };
try {
  await page.goto(base + '/admin'); await page.setup(helpers);
  await page.eval("setValue('token', 'incorrect-local-test-password'); $('unlock').click()"); await pause();
  check('sign-in error is visible at the gate', await page.eval("$('gateStatus').classList.contains('bad') && $('gateStatus').innerText.length > 0"));
  await capture('sign-in-desktop');
  await page.eval("setValue('token', 'local-development-token-' + 'x'.repeat(24)); $('unlock').click()"); await page.settle(1600);
  check('overview opens after sign-in', await page.eval("document.body.dataset.view === 'home'"));
  check('all portfolio font faces load', await page.eval("[...document.fonts].filter(f => f.status === 'loaded').length === 5"));
  check('collection disabled is visible', await page.eval("$('editor').innerText.includes('Analytics collection is disabled')"));
  check('empty dashboard shows unavailable metrics', await page.eval("[...document.querySelectorAll('.figure strong')].every(n => n.textContent === '—')"));
  check('empty dashboard draws no invented data', await page.eval("document.querySelectorAll('.chartCard svg').length === 0"));
  const destinations = ['Overview','Home','Journey','Work','Writing','About','Courtyard','CV & brief','Appearance','Media','Account'];
  for (const [width,height,suffix] of [[1440,900,'desktop'],[390,844,'phone']]) {
    await page.viewport(width,height,width<500);
    for (const label of destinations) {
      if (width < 500) {
        await page.eval("$('menuToggle').focus()"); await page.key('Enter','Enter',13);
        check(label + ' menu opens on phone', await page.eval("$('menuToggle').getAttribute('aria-expanded') === 'true'"));
      }
      await navigate(label);
      check(label + ' fits ' + suffix, await page.eval("document.documentElement.scrollWidth <= innerWidth && $('editorPane').scrollWidth <= $('editorPane').clientWidth + 1"));
      await capture(label.toLowerCase().replace(/[^a-z]+/g,'-') + '-' + suffix);
    }
  }
  await page.viewport(1440,900);
  await navigate('Home');
  await page.eval("document.querySelector('.pageCard').click()"); await pause();
  check('Home opens a working profile editor', await page.eval("Boolean($('f-greeting-en'))"));
  const original = await page.eval("$('f-greeting-en').value");
  await page.eval("setValue('f-greeting-en','Local UI verification draft.')"); await page.settle(900);
  await navigate('Journey'); await navigate('Home');
  await page.eval("document.querySelector('.pageCard').click()"); await pause();
  check('draft survives switching public pages', await page.eval("$('f-greeting-en').value === 'Local UI verification draft.'"));
  await page.eval("$('lang-en').focus()"); await page.key('ArrowDown','ArrowDown',40); await pause();
  check('Arabic tab supports keyboard and RTL fields', await page.eval("$('lang-ar').getAttribute('aria-selected') === 'true' && $('f-greeting-ar').dir === 'rtl'"));
  await capture('editor-arabic-desktop');
  await page.eval("$('lang-en').click()"); await pause();
  await page.eval("$('publish').click()"); await pause();
  check('review uses the visible review dialog', await page.eval("$('sheet').open && $('sheetBody').closest('dialog').id === 'sheet' && $('sheetBody').innerText.includes('Local UI verification draft.')"));
  await capture('review-desktop');
  await page.eval("clickText('#sheet button','Cancel')"); await pause();
  check('cancelling review preserves the draft', await page.eval("!$('sheet').open && $('f-greeting-en').value === 'Local UI verification draft.'"));
  check('cancelled review did not publish', await page.eval("fetch('/v1/admin/content/profile.json',{headers:{authorization:'Bearer '+sessionStorage.getItem('portfolio.admin.session')}}).then(r=>r.json()).then(r=>r.revision === 0 && !r.published)",true));
  await page.eval(`setValue('f-greeting-en', ${JSON.stringify(original)})`); await page.settle(900);
  for (const [label,index] of [['Home',0],['Journey',0],['Work',0],['About',1],['Courtyard',0]]) {
    await page.viewport(1440,900); await navigate(label);
    await page.eval(`document.querySelectorAll('.pageCard')[${index}]?.click()`); await pause();
    await capture(label.toLowerCase() + '-editor-desktop');
    await page.viewport(390,844); await pause();
    check(label + ' editor fits phone', await page.eval("document.documentElement.scrollWidth <= innerWidth && $('editorPane').scrollWidth <= $('editorPane').clientWidth + 1"));
    await capture(label.toLowerCase() + '-editor-phone');
  }
  await page.viewport(1440,900); await navigate('Appearance');
  check('Appearance explains that settings cannot change the site', await page.eval("$('editor').innerText.includes('These reference samples cannot change the website')"));
  await page.eval("$('paletteToggle').click()");
  check('base theme samples stay distinct in light mode', await page.eval("getComputedStyle(document.querySelector('.paletteSample[data-palette=dark]')).backgroundColor !== getComputedStyle(document.querySelector('.paletteSample[data-palette=light]')).backgroundColor"));
  await capture('appearance-light-desktop');
  await navigate('Overview'); await page.settle(900); await capture('overview-light-desktop');
  await page.viewport(320,740); await pause();
  check('overview fits 320px', await page.eval("document.documentElement.scrollWidth <= innerWidth && $('editorPane').scrollWidth <= $('editorPane').clientWidth + 1"));
  await capture('overview-light-small-phone');
  await page.eval("clickText('#editor .checks button','Choose dates')"); await pause();
  await page.eval("$('range-from').value = '2026-09-14'; $('range-from').dispatchEvent(new Event('change'))"); await pause();
  await page.eval("$('range-to').value = '2026-09-01'; $('range-to').dispatchEvent(new Event('change'))"); await pause();
  check('invalid range produces a visible error', await page.eval("$('editor').innerText.includes('Choose a start date on or before the end date')"));
  check('no fake telemetry words in rendered interface', await page.eval("!/standby|acquiring|telemetry|signal/i.test(document.body.innerText)"));
  check('no duplicate element IDs', await page.eval("(() => {const ids=[...document.querySelectorAll('[id]')].map(e=>e.id); return new Set(ids).size === ids.length;})()"));
  const errors=page.logs.filter(e=>e.level==='exception'||e.level==='error');
  check('no browser errors',errors.length===0);
  if(errors.length)console.log(errors);
} finally { await page.close(); }
await writeFile(output+'/checks.json',JSON.stringify(checks,null,2));
console.log(checks.filter(c=>c.passed).length + '/' + checks.length + ' passed');
if(checks.some(c=>!c.passed))process.exitCode=1;

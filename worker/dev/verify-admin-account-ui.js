/** Focused follow-up for account failure/retry and the final Media/Account copy. */
import {writeFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {launch} from './browser.js';
import {helpers} from './harness.js';
const output = fileURLToPath(new URL('../../docs/audits/2026-09-14-admin-ui/', import.meta.url));
const page = await launch();
const checks = [];
const check = (name, value) => {checks.push({name,passed:Boolean(value)});console.log((value?'PASS ':'FAIL ')+name);};
try {
 await page.goto((process.env.ADMIN_BASE ?? 'http://localhost:8790')+'/admin'); await page.setup(helpers);
 await page.eval("setValue('token','local-development-token-'+'x'.repeat(24));$('unlock').click()"); await page.settle(1400);
 await page.eval("window.savedFetch=window.fetch;window.fetch=(input, options) => String(input)==='/v1/admin/session' && !options?.method ? Promise.resolve(new Response(JSON.stringify({error:'Account details unavailable'}),{status:503,headers:{'content-type':'application/json'}})) : window.savedFetch(input,options);clickText('#rail > .section','Account')"); await page.settle(700);
 check('account failure is visible', await page.eval("$('editor').innerText.includes('Account details unavailable')"));
 check('account failure does not invent password state or expose a change form', await page.eval("!$('currentPassword') && !$('editor').innerText.includes('No admin password')"));
 await page.screenshot(output+'/account-error-desktop.png');
 await page.eval("window.fetch=window.savedFetch;clickText('#editor button','Retry account details')"); await page.settle(700);
 check('account retry recovers the real details',await page.eval("Boolean($('currentPassword')) && !$('editor').innerText.includes('Account details unavailable')"));
 for(const [width,height,suffix] of [[1440,900,'desktop'],[390,844,'phone']]) {
  await page.viewport(width,height,width<500);
  for(const label of ['Account','Media']) {
   await page.eval(`clickText('#rail > .section',${JSON.stringify(label)})`);await page.settle(500);
   await page.screenshot(output+'/'+label.toLowerCase()+'-'+suffix+'.png');
  }
 }
 check('updated pages still fit phone',await page.eval("document.documentElement.scrollWidth <= innerWidth && $('editorPane').scrollWidth <= $('editorPane').clientWidth+1"));
 check('focused account review has no browser errors',!page.logs.some(e=>e.level==='error'||e.level==='exception'));
} finally {await page.close();}
await writeFile(output+'/account-checks.json',JSON.stringify(checks,null,2));
console.log(checks.filter(c=>c.passed).length+'/'+checks.length+' passed');
if(checks.some(c=>!c.passed))process.exitCode=1;

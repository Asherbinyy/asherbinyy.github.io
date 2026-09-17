/** Actual Flutter integration. Runs against REAL_SITE=1; never seeds analytics. */
import {mkdir, writeFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {launch} from './browser.js';
import {helpers} from './harness.js';
const base = process.env.ADMIN_BASE || 'http://localhost:8790';
const output = process.env.ADMIN_AUDIT_DIR || fileURLToPath(new URL('../../docs/audits/2026-09-16-admin-final/', import.meta.url));
await mkdir(output, {recursive:true});
const checks = [];
const check = (name, value) => {checks.push({name, passed:Boolean(value)}); console.log((value ? 'PASS ' : 'FAIL ') + name);};
const page = await launch();
const pause = () => page.settle(550);
const capture = (name) => page.screenshot(output + '/' + name + '.png');
const navigate = async (label) => {await page.eval(`clickText('#rail > button', ${JSON.stringify(label)})`); await pause();};
const intro = async () => {await navigate('Home'); await page.eval("document.querySelector('.pageCard').click()"); await pause();};
const previewText = () => page.frameEval('document.body.innerText');
const ready = async () => {
  await page.settle(650);
  for (let i=0;i<30;i++) {if(await page.eval("$('previewState').innerText === 'Preview up to date'")) return true; await page.settle(350);}
  return false;
};
try {
  await page.goto(base + '/admin'); await page.setup(helpers);
  await page.eval("window.received=[]; addEventListener('message',e=>{if(e.data?.channel==='portfolio-preview') received.push({type:e.data.type,payload:e.data.payload})}); setValue('token','local-development-token-'+'x'.repeat(24)); $('unlock').click()");
  await page.settle(1300);
  check('overview shows disabled collection and no invented data', await page.eval("$('editor').innerText.includes('Analytics collection is disabled') && !document.querySelector('.chartCard svg') && [...document.querySelectorAll('.figure strong')].every(n=>n.innerText==='—')"));
  await capture('overview-desktop');
  await intro();
  check('real preview completes handshake and renders', await ready());
  check('preview is the actual Flutter app', await page.frameEval("Boolean(document.querySelector('flutter-view')) && document.title.includes('Ahmed')"));
  await page.frameEval(`(() => {const roots=[document];for(let i=0;i<roots.length;i++)for(const n of roots[i].querySelectorAll('*')){if(n.shadowRoot) roots.push(n.shadowRoot);if(n.tagName==='FLT-SEMANTICS-PLACEHOLDER'){n.click();return true;}}return false;})()`);
  await pause();
  const original = await page.eval("$('f-greeting-en').value");
  check('current bundled content is loaded in the editor', await page.eval("fetch('/assets/assets/content/profile.json').then(r=>r.json()).then(p=>p.greeting.en===$('f-greeting-en').value && p.skills.length>0)",true));
  check('current greeting appears in actual Flutter semantics', (await previewText()).includes(original));
  check('preview occupies half the desktop window', await page.eval("Math.abs($('previewPane').getBoundingClientRect().width-innerWidth/2)<2"));
  check('decorative grain and inset navigation accents are gone', await page.eval("getComputedStyle(document.body,'::before').content==='none' && getComputedStyle(document.querySelector('.section[aria-current=page]')).boxShadow==='none'"));
  check('preview makes no third-party requests', await page.frameEval("performance.getEntriesByType('resource').every(r=>['localhost','127.0.0.1'].includes(new URL(r.name).hostname))"));
  check('preview writes no browser storage', await page.frameEval("localStorage.length===0 && sessionStorage.length===0 && document.cookie===''") );
  await capture('home-preview-half');
  await page.eval("$('menuToggle').focus()"); await page.key('Enter','Enter',13);
  check('navigation minimizes from the keyboard', await page.eval("getComputedStyle($('rail')).display==='none' && $('menuToggle').getAttribute('aria-expanded')==='false'"));
  await capture('navigation-minimized');
  await page.key('Enter','Enter',13);
  check('navigation expands from the keyboard', await page.eval("getComputedStyle($('rail')).display!=='none' && $('menuToggle').getAttribute('aria-expanded')==='true'"));
  await page.eval("$('previewSize').value='third'; $('previewSize').dispatchEvent(new Event('change'))"); await pause();
  check('third-width preview stays at least one third of the screen', await page.eval("$('previewPane').getBoundingClientRect().width>=innerWidth/3 && $('previewPane').getBoundingClientRect().width<innerWidth*.36"));
  await capture('home-preview-third');
  const frameSrc=await page.eval("document.querySelector('#previewFrame iframe').src");
  await page.eval("$('minimizePreview').click()"); await pause();
  check('right panel minimizes', await page.eval("getComputedStyle($('previewPane')).display==='none' && $('previewToggle').getAttribute('aria-expanded')==='false'"));
  await capture('preview-minimized');
  await page.eval("$('previewToggle').click(); $('previewSize').value='half'; $('previewSize').dispatchEvent(new Event('change'))"); await pause();
  check('right panel restores without discarding its frame', await page.eval(`getComputedStyle($('previewPane')).display!=='none' && document.querySelector('#previewFrame iframe').src===${JSON.stringify(frameSrc)}`));
  await page.eval("setValue('f-greeting-en','Private preview check')"); check('valid draft receives render acknowledgment', await ready()); await pause();
  check('draft changes the visible Flutter text', (await previewText()).includes('Private preview check'));
  await capture('draft-preview');
  const fullName=await page.eval("$('f-name-en').value");
  await page.eval("setValue('f-name-en','')"); await page.settle(1100);
  check('invalid draft is blocked before preview', await page.eval("$('previewState').innerText.includes('Correct validation errors')"));
  check('invalid draft leaves the last valid website visible', (await previewText()).includes('Private preview check'));
  await page.eval(`setValue('f-name-en',${JSON.stringify(fullName)})`); await page.settle(900); await ready();
  await navigate('Work'); await page.settle(650); await ready();
  check('preview follows Work navigation', await page.frameEval("location.pathname==='/work'"));
  await capture('work-preview');
  await navigate('Services');
  await page.eval("document.querySelector('.pageCard').click()"); await ready();
  check('Services opens the current public page', await page.frameEval("location.pathname==='/services'"));
  const service = await page.eval("document.querySelector('#editor input[id^=f-services]').value");
  await page.eval("setValue(document.querySelector('#editor input[id^=f-services]').id,'Private service preview')"); await ready();
  check('service edits reach the real page', (await previewText()).includes('Private service preview'));
  await page.eval(`setValue(document.querySelector('#editor input[id^=f-services]').id,${JSON.stringify(service)})`); await ready();
  await capture('services-preview');
  await intro(); await ready();
  check('draft survives switching pages', await page.eval("$('f-greeting-en').value==='Private preview check'"));
  await page.eval("$('lang-ar').click()"); await page.settle(900); await ready();
  check('Arabic switches editor fields and Flutter content', await page.eval("$('f-greeting-ar').dir==='rtl'") && !(await previewText()).includes('Private preview check'));
  await capture('arabic-preview');
  await page.eval("$('lang-en').click()"); await page.settle(700); await ready();
  await page.eval("$('publish').click()"); await page.settle(750);
  check('review contains the actual unpublished change', await page.eval("$('sheet').open && $('sheetBody').innerText.includes('Private preview check')"));
  await capture('draft-review');
  await page.eval("clickText('#sheet button','Cancel')"); await pause();
  check('cancelling review preserves the draft and does not publish', await page.eval("$('f-greeting-en').value==='Private preview check' && fetch('/v1/admin/content/profile.json',{headers:{authorization:'Bearer '+sessionStorage.getItem('portfolio.admin.session')}}).then(r=>r.json()).then(r=>!r.published)",true));
  await page.eval(`setValue('f-greeting-en',${JSON.stringify(original)})`); await page.settle(900); await ready();
  await navigate('Appearance');
  check('appearance controls expose supported live settings', await page.eval("Boolean($('f-appearance-theme') && $('f-appearance-headingFont') && $('f-appearance-bodyFont'))"));
  await page.eval("$('f-appearance-theme').value='deshret'; $('f-appearance-theme').dispatchEvent(new Event('change'))"); await page.settle(900);
  check('appearance change is acknowledged by Flutter', await ready());
  await capture('appearance-light-preview');
  await page.eval("$('resetAppearance').click()"); await page.settle(900); await ready();
  check('reset returns appearance to site defaults without an empty saved object', await page.eval("$('resetAppearance').disabled && $('publish').disabled"));
  check('restored content clears navigation draft indicators', await page.eval("!document.querySelector('#rail > button .pip')"));
  await intro(); await ready();
  for (const [width,height] of [[1280,900],[1024,768],[390,844],[320,740]]) {
    await page.viewport(width,height,width<500); await pause();
    check('editor fits '+width+'px', await page.eval("document.documentElement.scrollWidth<=innerWidth && $('editorPane').scrollWidth<=$('editorPane').clientWidth+1"));
    if (width<500) {
      await page.eval("$('menuToggle').click()"); await pause();
      check('navigation expands at '+width+'px', await page.eval("getComputedStyle($('rail')).display!=='none'"));
      await page.eval("$('menuToggle').click(); $('previewToggle').click()"); await pause();
      check('preview is usable at '+width+'px', await page.eval("getComputedStyle($('previewPane')).display!=='none' && $('previewPane').getBoundingClientRect().width<=innerWidth && document.querySelector('#previewFrame iframe').clientHeight>250"));
      await capture('preview-'+width);
      await page.eval("$('minimizePreview').click()"); await pause();
      check('phone can return from preview to editor at '+width+'px', await page.eval("getComputedStyle($('editorPane')).display!=='none'"));
    }
    await capture('editor-'+width);
  }
  await page.viewport(1440,900); await navigate('About');
  await page.eval("document.querySelectorAll('.pageCard')[0].click()"); await pause(); await ready();
  await page.eval("if($('previewToggle').getAttribute('aria-expanded')==='false') $('previewToggle').click()"); await pause();
  check('current social destinations are editable', await page.eval("['tiktok','instagram','facebook','fiverr','calendly'].every(key=>$('f-contact-'+key)?.value.startsWith('https://'))"));
  check('bundled portrait source resolves to Flutter asset path', await page.eval("[...document.querySelectorAll('#editor img')].filter(n=>n.src.includes('/media/')).every(n=>n.complete && n.naturalWidth>0)"));
  await capture('about-preview');
  await navigate('Media');
  await page.eval("fetch('/assets/assets/media/portrait.jpg').then(r=>r.arrayBuffer()).then(bytes=>attachFile('upload-image',[...new Uint8Array(bytes)],'portrait.jpg','image/jpeg'))",true);
  await page.settle(1000);
  const uploaded = await page.eval("document.querySelector('.mediaCard .mono')?.innerText");
  check('media library accepts the existing portrait through its file input', /^\/v1\/media\/[a-f0-9]{32}$/.test(uploaded || ''));
  if (uploaded) {
    await navigate('About'); await page.eval("document.querySelector('.pageCard').click()"); await pause();
    const portrait = await page.eval("$('f-portrait-src').value");
    await page.eval(`setValue('f-portrait-src',${JSON.stringify(uploaded)})`); await ready(); await pause();
    let imageLoaded = false;
    for (let i=0;i<30;i++) {
      imageLoaded = await page.frameEval(`performance.getEntriesByType('resource').some(r=>new URL(r.name).pathname===${JSON.stringify(uploaded)} && r.responseStatus===200)`);
      if (imageLoaded) break;
      await page.settle(350);
    }
    check('Flutter requests the uploaded portrait', imageLoaded);
    await capture('uploaded-portrait-preview');
    await page.eval(`setValue('f-portrait-src',${JSON.stringify(portrait)})`); await ready();
  }
  const destinations = ['Overview', 'Home', 'Journey', 'Work', 'Articles', 'Services', 'About', 'Courtyard', 'CV & brief', 'Appearance', 'Media', 'Account'];
  for (const width of [1440, 390]) {
    await page.viewport(width, width === 1440 ? 900 : 844, width < 500);
    for (const label of destinations) {
      if (width < 500) await page.eval("if(!document.body.classList.contains('menuOpen')) $('menuToggle').click()");
      await navigate(label);
      await page.eval("document.querySelector('#editor .pageCard')?.click()");
      await pause();
      if (await page.eval("document.body.dataset.view==='document'")) await ready();
      check(label+' has a usable editor at '+width+'px', await page.eval("$('editor').innerText.trim().length>0 && document.documentElement.scrollWidth<=innerWidth && $('editorPane').scrollWidth<=$('editorPane').clientWidth+1"));
      await capture('page-'+label.toLowerCase().replace(/[^a-z]+/g,'-')+'-'+width);
    }
  }
  await page.viewport(1440,900);
  await navigate('Courtyard'); await ready();
  await page.frameEval(`(() => {const roots=[document];for(let i=0;i<roots.length;i++)for(const n of roots[i].querySelectorAll('*')){if(n.shadowRoot)roots.push(n.shadowRoot);if(n.tagName==='FLT-SEMANTICS-PLACEHOLDER')n.click();}})()`);
  const played = await page.frameEval(`(() => {const roots=[document];for(let i=0;i<roots.length;i++)for(const n of roots[i].querySelectorAll('*')){if(n.shadowRoot)roots.push(n.shadowRoot);if(n.getAttribute('role')==='button'&&(n.getAttribute('aria-label')||n.textContent)==='Play'){n.click();return true;}}return false;})()`);
  await page.settle(1200);
  check('the current game opens in the actual preview', played && await page.frameEval(`(() => {const roots=[document];for(let i=0;i<roots.length;i++)for(const n of roots[i].querySelectorAll('*')){if(n.shadowRoot)roots.push(n.shadowRoot);if((n.getAttribute('aria-label')||'').includes('The climb'))return true;}return false;})()`));
  check('preview play never contacts the public leaderboard', await page.frameEval("performance.getEntriesByType('resource').every(r=>!new URL(r.name).pathname.startsWith('/v1/game/'))"));
  check('preview play keeps browser storage empty', await page.frameEval("localStorage.length===0 && sessionStorage.length===0 && document.cookie===''"));
  await capture('courtyard-game-preview');
  await page.frameEval(`(() => {const roots=[document];for(let i=0;i<roots.length;i++)for(const n of roots[i].querySelectorAll('*')){if(n.shadowRoot)roots.push(n.shadowRoot);if(n.getAttribute('role')==='button'&&(n.getAttribute('aria-label')||n.textContent).includes('Close')){n.click();return true;}}return false;})()`);
  await intro(); await ready();
  await page.eval("setValue('f-greeting-en','Local publication check')"); await ready();
  await page.eval("$('publish').click()"); await page.settle(700);
  await page.eval("if($('sourceNote')) setValue('sourceNote','Local integration check only; unchanged owner figures are documented in docs/14-PROVENANCE.md.'); clickText('#sheet button','Publish Profile')");
  await page.settle(900);
  check('review publishes the selected document locally', await page.eval("$('status').innerText.includes('Published as revision')"));
  const site = await launch();
  try {
    await site.goto('http://127.0.0.1:8790/');
    let publishedText = '';
    for(let i=0;i<30;i++) {
      await site.settle(500);
      await site.eval("(() => {const roots=[document];for(let i=0;i<roots.length;i++)for(const n of roots[i].querySelectorAll('*')){if(n.shadowRoot)roots.push(n.shadowRoot);if(n.tagName==='FLT-SEMANTICS-PLACEHOLDER'){n.click();return;}}})()");
      publishedText=await site.eval('document.body.innerText');
      if(publishedText.includes('Local publication check')) break;
    }
    check('normal public app reads the local publication without admin credentials', publishedText.includes('Local publication check'));
  } finally {
    await site.close();
    check('local test publication is withdrawn after verification', await page.eval("fetch('/v1/admin/content/profile.json',{headers:{authorization:'Bearer '+sessionStorage.getItem('portfolio.admin.session')}}).then(r=>r.json()).then(head=>fetch('/v1/admin/content/profile.json',{method:'DELETE',headers:{authorization:'Bearer '+sessionStorage.getItem('portfolio.admin.session'),'x-base-revision':String(head.revision)}})).then(r=>r.ok)",true));
  }
  check('no JavaScript exception during the workflow', !page.logs.some(log=>log.level==='exception'));
} finally {
  await writeFile(output+'/checks.json',JSON.stringify(checks,null,2)+'\n');
  await page.close();
}
console.log(checks.filter(c=>c.passed).length+'/'+checks.length+' checks passed');
if(checks.some(c=>!c.passed)) process.exitCode=1;

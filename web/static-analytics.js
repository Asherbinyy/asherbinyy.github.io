/** Optional collection for the HTML CV and brief. Content works without JS. */
(() => {
  if (window.self !== window.top) return;
  const endpoint = document.currentScript?.dataset.endpoint;
  if (!endpoint?.startsWith('https://')) return;
  const key = 'flutter.nocturne.analyticsConsent.v2';
  const read = (name) => { try { return JSON.parse(localStorage.getItem(name)); } catch { return null; } };
  let choice = read(key) || (read('flutter.nocturne.consent') === 'none' ? 'none' : null);
  let viewed = false, started = null, active = 0, depth = 0, reported = false;
  const route = location.pathname;
  const campaign = new URL(location.href).searchParams.get('utm_campaign');
  const allowed = () => choice === 'session';
  function send(event, fields = {}) {
    if (!allowed()) return;
    let referrerHost;
    try { referrerHost = new URL(document.referrer).hostname; } catch { /* Direct. */ }
    const body = JSON.stringify({event, route, consent:'granted',
      deviceClass: matchMedia('(any-hover: hover) and (any-pointer: fine)').matches ? 'pointer' : 'touch',
      ...(referrerHost ? {referrerHost} : {}),
      ...(campaign && /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(campaign) && campaign.length <= 100 ? {campaign} : {}), ...fields});
    // Keepalive covers outgoing navigations without delaying the destination.
    fetch(endpoint, {method:'POST', headers:{'content-type':'application/json'}, body, keepalive:true, credentials:'omit'}).catch(() => {});
  }
  function begin() {
    if (!allowed()) return;
    if (!viewed) { viewed = true; send('route_view'); }
    if (started === null && !document.hidden) started = performance.now();
  }
  function pause() {
    if (started !== null) active += performance.now() - started;
    started = null;
  }
  function decide(value) {
    choice = value;
    try { localStorage.setItem(key, JSON.stringify(value)); } catch { /* In-memory choice still applies. */ }
    if (!allowed()) {
      pause(); active = 0; depth = 0;
      try { sessionStorage.removeItem('nocturne.session'); sessionStorage.removeItem('nocturne.campaign'); } catch { /* Storage disabled. */ }
    } else begin();
    panel.hidden = true;
    settings.focus();
  }
  const button = (label, action) => {
    const node = document.createElement('button'); node.type = 'button'; node.textContent = label; node.onclick = action; return node;
  };
  const panel = document.createElement('section'); panel.className = 'analytics-choice'; panel.setAttribute('aria-label','Analytics consent');
  const heading = document.createElement('h2'); heading.textContent = 'Analytics';
  const description = document.createElement('p'); description.textContent = 'Allow anonymous statistics about pages, links and reading activity? Nothing is recorded before you accept.';
  const actions = document.createElement('div'); actions.append(button('Allow analytics',()=>decide('session')), button('Reject',()=>decide('none')));
  const details = document.createElement('details'), summary = document.createElement('summary'), notice = document.createElement('p');
  summary.textContent = 'Privacy details';
  notice.textContent = 'Ahmed Elsherbini operates this service on Cloudflare. Consented records include pages, public link destinations, reading time, scroll quartiles, coarse country, input device, referrer host and a campaign slug. Queries, form entries and contact addresses are excluded. The request address and browser header are briefly hashed with a daily salt; raw values are discarded. Hashes expire within two days, aggregate counts after 24 months. Your choice is stored on this browser. Change it using Consent below. Use the contact links on this page for privacy requests.';
  details.append(summary,notice); panel.append(heading,description,actions,details);
  const footer = document.querySelector('footer');
  if (!footer) return;
  const settings = button('Consent',()=>{ panel.hidden = false; panel.scrollIntoView({block:'nearest'}); actions.querySelector('button').focus(); });
  footer.append(settings,panel); panel.hidden = choice !== null;
  addEventListener('storage', (event) => {
    if (event.key !== key) return;
    choice = read(key); pause(); active = 0; depth = 0; panel.hidden = choice !== null; begin();
  });
  document.addEventListener('click', (event) => {
    const anchor = event.target.closest?.('a[href]');
    if (!anchor || !allowed()) return;
    const url = new URL(anchor.href);
    let destination;
    if (url.protocol === 'mailto:') destination = 'email';
    else if (url.protocol === 'tel:') destination = 'phone';
    else if (['http:','https:'].includes(url.protocol) && !url.username && !url.password) {
      if (url.origin === location.origin && url.pathname === location.pathname) return;
      const id = url.hostname === 'play.google.com' ? url.searchParams.get('id') : null;
      url.search = ''; url.hash = '';
      if (id && /^[A-Za-z0-9_.]{1,160}$/.test(id)) url.searchParams.set('id',id);
      destination = url.href;
    }
    if (destination) send('outbound_click',{target:anchor.dataset.analyticsTarget || 'link:' + (url.hostname || url.protocol.slice(0,-1)),destination});
  }, {capture:true});
  document.addEventListener('visibilitychange', () => document.hidden ? pause() : begin());
  addEventListener('scroll', () => {
    if (!allowed() || document.hidden) return;
    const available = document.documentElement.scrollHeight - innerHeight;
    if (available > 0) depth = Math.max(depth, Math.min(4, Math.floor(scrollY / available * 4)));
  }, {passive:true});
  addEventListener('pagehide', () => {
    pause(); if (reported || !allowed()) return; reported = true;
    const seconds = Math.min(3600, Math.floor(active / 1000));
    if (seconds >= 2) send('section_dwell',{value:seconds});
    if (depth > 0) send('scroll_depth',{value:depth});
  });
  addEventListener('pageshow', (event) => { if (event.persisted) { reported=false; active=0; depth=0; viewed=false; begin(); } });
  begin();
})();

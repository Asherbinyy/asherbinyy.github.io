/** Cookieless collection for the HTML CV and brief. Content works without JS. */
(() => {
  if (window.self !== window.top) return;
  const endpoint = document.currentScript?.dataset.endpoint;
  if (!endpoint?.startsWith('https://')) return;
  let started = document.hidden ? null : performance.now();
  let active = 0, depth = 0, reported = false;
  const route = location.pathname;
  const campaign = new URL(location.href).searchParams.get('utm_campaign');

  function send(event, fields = {}) {
    let referrerHost;
    try { referrerHost = new URL(document.referrer).hostname; } catch { /* Direct. */ }
    const body = JSON.stringify({event, route,
      deviceClass: matchMedia('(any-hover: hover) and (any-pointer: fine)').matches ? 'pointer' : 'touch',
      ...(referrerHost ? {referrerHost} : {}),
      ...(campaign && /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(campaign) && campaign.length <= 100 ? {campaign} : {}),
      ...fields});
    fetch(endpoint, {method:'POST', headers:{'content-type':'application/json'}, body, keepalive:true, credentials:'omit'}).catch(() => {});
  }

  function pause() {
    if (started !== null) active += performance.now() - started;
    started = null;
  }

  function resume() {
    if (started === null && !document.hidden) started = performance.now();
  }

  document.addEventListener('click', (event) => {
    const anchor = event.target.closest?.('a[href]');
    if (!anchor) return;
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

  document.addEventListener('visibilitychange', () => document.hidden ? pause() : resume());
  addEventListener('scroll', () => {
    if (document.hidden) return;
    const available = document.documentElement.scrollHeight - innerHeight;
    if (available > 0) depth = Math.max(depth, Math.min(4, Math.floor(scrollY / available * 4)));
  }, {passive:true});
  addEventListener('pagehide', () => {
    pause();
    if (reported) return;
    reported = true;
    const seconds = Math.min(3600, Math.floor(active / 1000));
    if (seconds >= 2) send('section_dwell',{value:seconds});
    if (depth > 0) send('scroll_depth',{value:depth});
  });
  addEventListener('pageshow', (event) => {
    if (!event.persisted) return;
    reported = false; active = 0; depth = 0; resume();
    send('route_view');
  });
  send('route_view');
})();

/** Focused reports over observed analytics, with no synthetic production data. */
export const clientDashboard = `
let dashboardTab = 'overview';
let dashboardMetric = 'views';
let dashboardPublicationOpen = false;
let dashboardSearch = '';
let dashboardSort = {key: '', direction: -1};
const dashboardTabs = [['overview', 'Overview'], ['links', 'Links & apps'], ['pages', 'Pages'], ['audience', 'Audience']];
const numberFormat = new Intl.NumberFormat('en-GB');
function amount(value) { return value == null ? '—' : numberFormat.format(value); }
function pageName(path) {
  const names = {'/':'Home', '/work':'Work', '/about':'About', '/services':'Services', '/journey':'Journey', '/courtyard':'Courtyard', '/writing':'Articles', '/cv/':'CV', '/brief/':'Brief'};
  if (names[path]) return names[path];
  const app = state.docs.get('apps.json')?.live?.apps?.find((app) => path === '/work/' + app.id);
  return app?.name || path;
}
function linkName(link) {
  if (link.target === 'cv') return 'CV';
  if (link.target === 'booking') return 'Book a call';
  if (link.target.startsWith('app:')) {
    const [, id, platform] = link.target.split(':');
    const app = state.docs.get('apps.json')?.live?.apps?.find((app) => app.id === id);
    return (app?.name || id) + (platform ? ' · ' + ({ios:'App Store',android:'Google Play',pub:'pub.dev'}[platform] || platform) : '');
  }
  if (link.destination === 'email') return 'Email';
  if (link.destination === 'phone') return 'Phone';
  if (link.destination === '-') return 'Legacy click · destination unavailable';
  try { const url = new URL(link.destination); return url.hostname.replace(/^www\\./, '') + (url.pathname === '/' ? '' : url.pathname); } catch { return link.target; }
}
function comparisonNote(value, previous) {
  if (!state.insights.comparison.recorded) return 'No records in the previous period';
  if (previous === 0) return value ? 'First recorded activity in this period' : 'No change from the previous period';
  const delta = Math.round((value - previous) / previous * 100);
  return (delta > 0 ? '+' : '') + delta + '% vs previous period · ' + amount(previous);
}
function dashboardNavigate(tab) {
  dashboardTab = tab; dashboardSearch = ''; dashboardSort = {key:'', direction:-1}; render();
}
function reportTable(title, columns, rows, {searchable = false, empty = 'No recorded activity in this range.'} = {}) {
  const section = node('section', 'reportSection');
  const heading = node('div', 'reportHeading'); heading.append(node('h3', null, title));
  if (searchable) {
    const search = node('input', 'reportSearch'); search.type = 'search'; search.placeholder = 'Search ' + title.toLowerCase(); search.value = dashboardSearch;
    search.setAttribute('aria-label', search.placeholder);
    search.oninput = () => { dashboardSearch = search.value; drawRows(); };
    heading.append(search);
  }
  section.append(heading);
  const wrap = node('div', 'tableScroll'), table = node('table', 'dataTable reportTable');
  const caption = node('caption', 'srOnly', title); table.append(caption);
  const thead = node('thead'), top = node('tr'), body = node('tbody');
  for (const column of columns) {
    const th = node('th'); th.scope = 'col';
    const sort = node('button', 'quiet', column.label);
    sort.onclick = () => { dashboardSort = {key:column.key, direction:dashboardSort.key === column.key ? -dashboardSort.direction : -1}; drawRows(); };
    th.append(sort); top.append(th);
  }
  thead.append(top); table.append(thead, body); wrap.append(table); section.append(wrap);
  function drawRows() {
    body.replaceChildren();
    const query = searchable ? dashboardSearch.toLowerCase() : '';
    const selected = rows.filter((row) => !query || columns.some((column) => String(row[column.key] ?? '').toLowerCase().includes(query)));
    const sorting = columns.find((column) => column.key === dashboardSort.key);
    if (sorting) selected.sort((a,b) => {
      const left = a[sorting.key], right = b[sorting.key];
      return dashboardSort.direction * (typeof left === 'number' && typeof right === 'number' ? left-right : String(left ?? '').localeCompare(String(right ?? '')));
    });
    [...top.children].forEach((th, i) => th.setAttribute('aria-sort', dashboardSort.key === columns[i].key ? dashboardSort.direction > 0 ? 'ascending' : 'descending' : 'none'));
    if (!selected.length) { const row=node('tr'), cell=node('td','note',query ? 'No matches.' : empty); cell.colSpan=columns.length; row.append(cell); body.append(row); }
    for (const entry of selected) {
      const row = node('tr');
      for (const column of columns) {
        const value = entry[column.key];
        const cell = node('td', column.numeric ? 'numeric' : null, column.format ? column.format(value) : value == null ? '—' : typeof value === 'number' ? amount(value) : value);
        row.append(cell);
      }
      body.append(row);
    }
  }
  drawRows(); return section;
}
function dashboardTrend(seen) {
  const group = node('section', 'reportSection');
  const head = node('div', 'reportHeading'); head.append(node('h3', null, 'Traffic over time'));
  const controls = node('div', 'checks'); controls.setAttribute('aria-label', 'Chart metric');
  for (const [value, label] of [['views','Page views'],['clicks','Link clicks']]) {
    const button=node('button','small',label); button.setAttribute('aria-pressed',String(dashboardMetric === value));
    button.onclick=()=>{dashboardMetric=value;render();}; controls.append(button);
  }
  head.append(controls); group.append(head);
  const entries = (seen.trend || []).map((day)=>({date:day.date,count:day[dashboardMetric]}));
  group.append(seriesChart(dashboardMetric === 'views' ? 'Page views' : 'Link clicks', entries,
    'Recorded after consent · daily totals in UTC. Dates without records are left blank.', true));
  return group;
}
function renderDashboard() {
  const pane=el('editor'); pane.replaceChildren(); pane.classList.add('dashboard');
  pane.append(pageHeading('Overview','See what visitors read and where they go next.'));
  const nav=node('div','reportTabs'); nav.setAttribute('role','group'); nav.setAttribute('aria-label','Analytics reports');
  for (const [id,label] of dashboardTabs) {
    const button=node('button','quiet',label); button.setAttribute('aria-pressed',String(dashboardTab === id)); button.onclick=()=>dashboardNavigate(id); nav.append(button);
  }
  pane.append(nav,rangePicker());
  if (!state.insights && !state.insightsError) { pane.append(node('p','note','Loading analytics…')); if(!insightsLoading)loadInsights(); return; }
  if (state.insightsError) {
    const error=node('div','reportSection'); error.setAttribute('role','alert'); error.append(node('p','issue',state.insightsError));
    const retry=node('button','small','Try again'); retry.onclick=refreshInsights; error.append(retry); pane.append(error);return;
  }
  const seen=state.insights, recorded=seen.collection.rowsInRange>0;
  const health=node('div','collectionHealth');
  const last=seen.metadata?.lastEventAt;
  health.append(node('span',null,seen.configuration.knownDisabled ? 'Analytics collection is disabled' : last ? 'Consented activity recorded' : 'Ready · waiting for the first consented visit'));
  if(last) health.append(node('span','note','Last received ' + new Date(last).toLocaleString('en-GB',{timeZone:'UTC'}) + ' UTC'));
  const download=node('button','small','Export CSV'); download.onclick=exportDashboard; download.disabled=!recorded;health.append(download);pane.append(health);
  const cards=node('div','figures dashboardFigures');
  cards.append(figure(recorded?amount(seen.views):'—','Page views',comparisonNote(seen.views,seen.comparison.views)));
  cards.append(figure(recorded?amount(seen.clicks):'—','Link clicks',comparisonNote(seen.clicks,seen.comparison.clicks)));
  cards.append(figure(recorded?amount(seen.downloads):'—','CV opens','Opens from the portfolio; includes repeat clicks'));
  cards.append(figure(amount(seen.clicksPer100Views),'Clicks per 100 views','Click count ÷ page views. Multiple clicks can exceed 100.'));
  pane.append(cards);
  if (!recorded) { const empty=node('div','reportEmpty'); empty.append(node('h3',null,'No activity recorded for these dates'),node('p','note',seen.configuration.note)); pane.append(empty); }
  const links=(seen.links||[]).map((link)=>({name:linkName(link),destination:link.destination,kind:link.kind,clicks:link.clicks,from:link.pages.map((page)=>pageName(page.route)+' ('+page.count+')').join(', ')}));
  const pages=(seen.pages||[]).map((page)=>({...page,name:pageName(page.route)}));
  const linkColumns=[{key:'name',label:'Link or app'},{key:'kind',label:'Type'},{key:'clicks',label:'Clicks',numeric:true},{key:'from',label:'Source pages'}];
  const pageColumns=[{key:'name',label:'Page'},{key:'views',label:'Views',numeric:true},{key:'clicks',label:'Link clicks',numeric:true},{key:'meanSeconds',label:'Avg active time',numeric:true,format:(v)=>v==null?'—':amount(v)+'s'},{key:'meanDepth',label:'Avg scroll quartile',numeric:true,format:(v)=>v==null?'—':amount(v)+' / 4'}];
  const actions=(seen.actions||[]).map((action)=>({name:eventNames[action.event]||action.event,target:action.target==='-'?'—':action.target,page:pageName(action.route),count:action.count}));
  if (dashboardTab==='overview') {
    pane.append(dashboardTrend(seen));
    const columns=node('div','reportColumns');
    columns.append(reportTable('Top links & apps',linkColumns.slice(0,3),links.slice(0,5)),reportTable('Top pages',pageColumns.slice(0,3),pages.slice(0,5)));pane.append(columns);
    const more=node('div','checks');
    for(const [id,label] of [['links','All links & apps'],['pages','All pages']]) {const button=node('button','small',label);button.onclick=()=>dashboardNavigate(id);more.append(button);}pane.append(more);
  } else if(dashboardTab==='links') {
    pane.append(reportTable('Links & apps',[...linkColumns,{key:'destination',label:'Destination'}],links,{searchable:true}));
    pane.append(reportTable('App detail views',[{key:'name',label:'App'},{key:'count',label:'Views',numeric:true}],(seen.appOpens||[]).map((app)=>({name:pageName(app.value),count:app.count}))));
    pane.append(reportTable('Interactions',[{key:'name',label:'Action'},{key:'target',label:'Item'},{key:'page',label:'Page'},{key:'count',label:'Count',numeric:true}],actions));
  } else if(dashboardTab==='pages') {
    pane.append(reportTable('Pages',pageColumns,pages,{searchable:true}));
    pane.append(node('p','note','Active time excludes hidden tabs and time before consent. Reading samples are reported when a page is left; missing samples are shown as a dash.'));
  } else {
    pane.append(seriesChart('Daily unique visitors',seen.dailyUniques,'Estimated from a hash that changes daily. Counts cannot be added into monthly people totals.',true));
    const columns=node('div','reportColumns');
    for(const [key,label] of [['referrers','Traffic sources'],['countries','Countries'],['devices','Input devices'],['campaigns','Campaigns']]) {
      const entries=seen[key].map((entry)=>({name:entry.value==='-'?'Direct / unavailable':entry.value==='XX'?'Unknown':entry.value==='touch'?'Touch':entry.value==='pointer'?'Mouse / trackpad':entry.value,count:entry.count,share:seen.views?Math.round(entry.count/seen.views*1000)/10:0}));
      columns.append(reportTable(label,[{key:'name',label:label},{key:'count',label:'Page views',numeric:true},{key:'share',label:'Share',numeric:true,format:(v)=>amount(v)+'%'}],entries));
    }
    pane.append(columns);
  }
  const details=node('details','reportFootnote');details.append(node('summary',null,'What these numbers mean'));
  details.append(node('p','note','Only recorded, consented activity is included. Admin previews and rejected visits are excluded. Clicks count activations, not successful downloads, messages or bookings. Direct and unavailable referrers cannot be distinguished. Older records have no link destination.'));
  details.append(node('p','note',seen.uniqueVisitors.whyNoTotal));
  details.append(node('p','note','Aggregate retention: 24 months. Daily visitor hashes: at most two days. Input device describes touch or pointer; it is not an inferred phone model.'));
  pane.append(details);
  const publication=node('details','reportFootnote');publication.append(node('summary',null,'Publication status'));publication.open=dashboardPublicationOpen; if(dashboardPublicationOpen)publication.append(releaseSection()); publication.ontoggle=()=>{dashboardPublicationOpen=publication.open;if(publication.open && publication.children.length===1)publication.append(releaseSection());};pane.append(publication);
}
function exportDashboard() {
  const report=state.insights;
  let rows;
  if(dashboardTab==='links') rows=[['Link or app','Destination','Type','Clicks','Source pages'],...report.links.map((link)=>[linkName(link),link.destination,link.kind,link.clicks,link.pages.map((p)=>p.route+': '+p.count).join('; ')])];
  else if(dashboardTab==='pages') rows=[['Page','Views','Link clicks','Average active seconds','Average scroll quartile'],...report.pages.map((p)=>[p.route,p.views,p.clicks,p.meanSeconds,p.meanDepth])];
  else if(dashboardTab==='audience') rows=[['Dimension','Category','Page views'],...['countries','devices','referrers','campaigns'].flatMap((key)=>report[key].map((r)=>[key,r.value,r.count]))];
  else rows=[['Date (UTC)','Page views','Link clicks'],...report.trend.map((d)=>[d.date,d.views,d.clicks])];
  const quote=(value)=>{let text=String(value??'');if(/^[=+@\\-\\t\\r]/.test(text))text="'"+text;return '"'+text.replace(/"/g,'""')+'"';};
  const csv=rows.map((row)=>row.map(quote).join(',')).join('\\r\\n');
  const url=URL.createObjectURL(new Blob([csv],{type:'text/csv;charset=utf-8'}));
  const anchor=node('a');anchor.href=url;anchor.download='portfolio-'+dashboardTab+'-'+report.range.from+'-'+report.range.to+'.csv';anchor.click();setTimeout(()=>URL.revokeObjectURL(url),1000);
}
`;

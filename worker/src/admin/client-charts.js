/** SVG charts show observed rows only; every series includes an accessible table. */
export const clientCharts = `
function svgNode(tag, attributes, text) {
  const made = document.createElementNS('http://www.w3.org/2000/svg', tag);
  for (const [key, value] of Object.entries(attributes || {})) made.setAttribute(key, String(value));
  if (text !== undefined) made.textContent = text;
  return made;
}

function seriesChart(title, entries, description, wide) {
  const group = node('section', 'chartCard' + (wide ? ' wide' : ''));
  group.append(node('h3', null, title), node('p', 'note', description));
  if (!entries.length) {
    const empty = node('div', 'chartEmpty');
    empty.append(node('strong', null, 'No recorded data'), node('p', null, 'Collection is disabled. A chart will appear when recorded data is available for this range.'));
    group.append(empty);
    return group;
  }
  const points = entries.slice().sort((a, b) => a.date.localeCompare(b.date));
  const width = 680, height = 240, left = 48, right = 16, top = 16, bottom = 40;
  const parseDay = (date) => Date.parse(date + 'T00:00:00Z');
  const from = parseDay(state.insights.range.from), to = parseDay(state.insights.range.to);
  const maximum = Math.max(1, ...points.map((point) => point.count));
  const x = (date) => from === to ? width / 2 : left + (parseDay(date) - from) / (to - from) * (width - left - right);
  const y = (count) => height - bottom - count / maximum * (height - top - bottom);
  const svg = svgNode('svg', {viewBox: '0 0 ' + width + ' ' + height, role: 'img', 'aria-label': title + '. ' + description + ' Exact values in the table below.'});
  svg.append(svgNode('title', {}, title));
  for (const value of [0, maximum]) {
    svg.append(svgNode('line', {x1: left, x2: width - right, y1: y(value), y2: y(value), class: 'chartAxis'}));
    svg.append(svgNode('text', {x: left - 8, y: y(value) + 4, 'text-anchor': 'end', class: 'chartLabel'}, String(value)));
  }
  let previous = null;
  for (const point of points) {
    // A missing day is unknown. Do not draw a line across it or manufacture a zero.
    if (previous && parseDay(point.date) - parseDay(previous.date) === 86400000) {
      svg.append(svgNode('line', {x1: x(previous.date), y1: y(previous.count), x2: x(point.date), y2: y(point.count), class: 'chartLine'}));
    }
    const dot = svgNode('circle', {cx: x(point.date), cy: y(point.count), r: 4, class: 'chartPoint'});
    dot.append(svgNode('title', {}, point.date + ': ' + point.count));
    svg.append(dot); previous = point;
  }
  for (const [date, anchor] of [[state.insights.range.from, 'start'], [state.insights.range.to, 'end']]) {
    if (from === to && anchor === 'end') continue;
    svg.append(svgNode('text', {x: from === to ? width / 2 : anchor === 'start' ? left : width - right, y: height - 8, 'text-anchor': from === to ? 'middle' : anchor, class: 'chartLabel'}, date));
  }
  group.append(svg);
  const details = node('details');
  details.append(node('summary', null, 'View daily values'));
  const table = node('table', 'dataTable');
  table.append(node('caption', 'note', title + ' · UTC'));
  const heading = node('tr');
  for (const text of ['Date', 'Count']) { const th = node('th', null, text); th.scope = 'col'; heading.append(th); }
  const tableHead = node('thead'); tableHead.append(heading); table.append(tableHead);
  const body = node('tbody');
  for (const point of points) { const row = node('tr'); row.append(node('td', null, point.date), node('td', null, String(point.count))); body.append(row); }
  table.append(body); details.append(table); group.append(details);
  return group;
}
`;

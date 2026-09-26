import {worldCountries} from './world-map-data.js';

/** Accessible SVG and proportional charts over exact aggregate values. */
export const clientCharts = `
const mapCountries = ${JSON.stringify(worldCountries)};

function svgNode(tag, attributes, text) {
  const made = document.createElementNS('http://www.w3.org/2000/svg', tag);
  for (const [key, value] of Object.entries(attributes || {})) {
    made.setAttribute(key, String(value));
  }
  if (text !== undefined) made.textContent = text;
  return made;
}

function chartEmpty(message) {
  const empty = node('div', 'chartEmpty');
  empty.append(
    node('strong', null, 'No recorded data'),
    node('p', null, message || 'A chart will appear when activity is recorded in this range.'),
  );
  return empty;
}

function periodsTouch(left, right, unit) {
  if (unit === 'hour') return Number(right.slice(0, 2)) - Number(left.slice(0, 2)) === 1;
  if (unit === 'month') {
    const [leftYear, leftMonth] = left.split('-').map(Number);
    const [rightYear, rightMonth] = right.split('-').map(Number);
    return rightYear * 12 + rightMonth - (leftYear * 12 + leftMonth) === 1;
  }
  return Date.parse(right + 'T00:00:00Z') - Date.parse(left + 'T00:00:00Z') === 86400000;
}

function trafficChart(entries, unit, description) {
  const group = node('section', 'analyticsCard trafficCard');
  const heading = node('div', 'cardHeading');
  heading.append(node('div', null, ''), node('p', 'note', description));
  heading.firstChild.append(node('p', 'cardEyebrow', 'Traffic'), node('h3', null, 'Views and clicks'));
  group.append(heading);
  if (!entries.length) {
    group.append(chartEmpty());
    return group;
  }

  const width = 820;
  const height = 300;
  const left = 48;
  const right = 20;
  const top = 24;
  const bottom = 46;
  const maximum = Math.max(1, ...entries.flatMap((point) => [point.views, point.clicks]));
  const x = (index) => entries.length === 1 ? width / 2
    : left + index / (entries.length - 1) * (width - left - right);
  const y = (value) => height - bottom - value / maximum * (height - top - bottom);
  const svg = svgNode('svg', {
    viewBox: '0 0 ' + width + ' ' + height,
    role: 'img',
    'aria-label': 'Page views and link clicks over time. Exact values follow the chart.',
  });
  svg.append(svgNode('title', {}, 'Page views and link clicks'));
  for (const value of [0, Math.ceil(maximum / 2), maximum]) {
    svg.append(svgNode('line', {
      x1: left, x2: width - right, y1: y(value), y2: y(value), class: 'chartGridLine',
    }));
    svg.append(svgNode('text', {
      x: left - 9, y: y(value) + 4, 'text-anchor': 'end', class: 'chartLabel',
    }, String(value)));
  }
  for (const [metric, className] of [['views', 'chartViews'], ['clicks', 'chartClicks']]) {
    for (let index = 1; index < entries.length; index += 1) {
      if (!periodsTouch(entries[index - 1].key, entries[index].key, unit)) continue;
      svg.append(svgNode('line', {
        x1: x(index - 1), y1: y(entries[index - 1][metric]),
        x2: x(index), y2: y(entries[index][metric]),
        class: 'chartLine ' + className,
      }));
    }
    entries.forEach((point, index) => {
      const label = point.label + ': ' + point[metric] +
        (metric === 'views' ? ' page views' : ' link clicks');
      const dot = svgNode('circle', {
        cx: x(index), cy: y(point[metric]), r: 4,
        class: 'chartPoint ' + className,
        tabindex: 0, role: 'img', 'aria-label': label,
      });
      dot.append(svgNode('title', {}, label));
      svg.append(dot);
    });
  }
  const labelIndexes = [...new Set([0, Math.floor((entries.length - 1) / 2), entries.length - 1])];
  for (const index of labelIndexes) {
    svg.append(svgNode('text', {
      x: x(index), y: height - 12,
      'text-anchor': index === 0 && entries.length > 1 ? 'start'
        : index === entries.length - 1 && entries.length > 1 ? 'end' : 'middle',
      class: 'chartLabel',
    }, entries[index].label));
  }
  group.append(svg);
  const legend = node('div', 'chartLegend');
  for (const [className, label] of [['views', 'Page views'], ['clicks', 'Link clicks']]) {
    const item = node('span');
    item.append(node('i', className), document.createTextNode(label));
    legend.append(item);
  }
  group.append(legend);
  const details = node('details', 'chartData');
  details.append(node('summary', null, 'View exact values'));
  const table = node('table', 'dataTable');
  table.append(node('caption', 'srOnly', 'Exact traffic values'));
  const head = node('thead');
  const headingRow = node('tr');
  for (const label of ['Period', 'Page views', 'Link clicks']) {
    const cell = node('th', null, label);
    cell.scope = 'col';
    headingRow.append(cell);
  }
  head.append(headingRow);
  const body = node('tbody');
  for (const point of entries) {
    const row = node('tr');
    row.append(
      node('td', null, point.label),
      node('td', 'numeric', String(point.views)),
      node('td', 'numeric', String(point.clicks)),
    );
    body.append(row);
  }
  table.append(head, body);
  details.append(table);
  group.append(details);
  return group;
}

function seriesChart(title, entries, description, wide) {
  const group = node('section', 'analyticsCard chartCard' + (wide ? ' wide' : ''));
  group.append(node('h3', null, title), node('p', 'note', description));
  if (!entries.length) {
    group.append(chartEmpty());
    return group;
  }
  const points = entries.slice().sort((left, right) => left.date.localeCompare(right.date));
  const width = 680;
  const height = 240;
  const left = 48;
  const right = 16;
  const top = 16;
  const bottom = 40;
  const maximum = Math.max(1, ...points.map((point) => point.count));
  const x = (index) => points.length === 1 ? width / 2
    : left + index / (points.length - 1) * (width - left - right);
  const y = (count) => height - bottom - count / maximum * (height - top - bottom);
  const svg = svgNode('svg', {
    viewBox: '0 0 ' + width + ' ' + height,
    role: 'img',
    'aria-label': title + '. ' + description + ' Exact values follow the chart.',
  });
  svg.append(svgNode('title', {}, title));
  for (const value of [0, maximum]) {
    svg.append(svgNode('line', {
      x1: left, x2: width - right, y1: y(value), y2: y(value), class: 'chartGridLine',
    }));
    svg.append(svgNode('text', {
      x: left - 8, y: y(value) + 4, 'text-anchor': 'end', class: 'chartLabel',
    }, String(value)));
  }
  for (let index = 1; index < points.length; index += 1) {
    if (!periodsTouch(points[index - 1].date, points[index].date, 'day')) continue;
    svg.append(svgNode('line', {
      x1: x(index - 1), y1: y(points[index - 1].count),
      x2: x(index), y2: y(points[index].count), class: 'chartLine chartViews',
    }));
  }
  points.forEach((point, index) => {
    const dot = svgNode('circle', {
      cx: x(index), cy: y(point.count), r: 4, class: 'chartPoint chartViews',
      tabindex: 0, role: 'img', 'aria-label': point.date + ': ' + point.count,
    });
    dot.append(svgNode('title', {}, point.date + ': ' + point.count));
    svg.append(dot);
  });
  group.append(svg);
  const details = node('details', 'chartData');
  details.append(node('summary', null, 'View exact values'));
  const table = node('table', 'dataTable');
  const head = node('thead');
  const heading = node('tr');
  for (const label of ['Date', 'Count']) {
    const cell = node('th', null, label);
    cell.scope = 'col';
    heading.append(cell);
  }
  head.append(heading);
  const body = node('tbody');
  for (const point of points) {
    const row = node('tr');
    row.append(node('td', null, point.date), node('td', 'numeric', String(point.count)));
    body.append(row);
  }
  table.append(head, body);
  details.append(table);
  group.append(details);
  return group;
}

function rankedBars(title, entries, empty) {
  const card = node('section', 'analyticsCard rankedCard');
  card.append(node('h3', null, title));
  if (!entries.length) {
    card.append(node('p', 'note', empty || 'No recorded activity in this range.'));
    return card;
  }
  const maximum = Math.max(1, ...entries.map((entry) => entry.count));
  for (const entry of entries.slice(0, 7)) {
    const row = node('div', 'rankRow');
    const heading = node('div', 'rankHeading');
    heading.append(node('span', null, entry.name), node('strong', null, amount(entry.count)));
    const track = node('span', 'rankTrack');
    track.setAttribute('aria-hidden', 'true');
    const fill = node('span', 'rankFill');
    fill.style.width = entry.count / maximum * 100 + '%';
    track.append(fill);
    row.append(heading, track);
    card.append(row);
  }
  return card;
}

function countryMap(entries, total) {
  const card = node('section', 'analyticsCard countryCard');
  const heading = node('div', 'cardHeading');
  heading.append(node('div', null, ''), node('p', 'note', 'Page views by Cloudflare country code'));
  heading.firstChild.append(node('p', 'cardEyebrow', 'Geography'), node('h3', null, 'Where views came from'));
  card.append(heading);
  if (!entries.length) {
    card.append(chartEmpty('The map will appear when a page view includes a country code.'));
    return card;
  }
  const counts = new Map(entries.map((entry) => [entry.value, entry.count]));
  const maximum = Math.max(1, ...entries.map((entry) => entry.count));
  const svg = svgNode('svg', {
    viewBox: '0 0 960 480', role: 'img',
    'aria-label': 'World map of recorded page views. Exact values follow the map.',
  });
  svg.append(svgNode('title', {}, 'Recorded page views by country'));
  for (const country of mapCountries) {
    const count = counts.get(country.code) || 0;
    const level = count ? Math.max(1, Math.ceil(count / maximum * 4)) : 0;
    const label = country.name + ': ' + count + ' page views';
    const path = svgNode('path', {
      d: country.path,
      class: 'mapCountry mapLevel' + level,
      'data-code': country.code,
      'aria-label': label,
    });
    if (count) {
      path.setAttribute('tabindex', '0');
      path.setAttribute('role', 'img');
    } else {
      path.setAttribute('aria-hidden', 'true');
    }
    path.append(svgNode('title', {}, label));
    svg.append(path);
  }
  card.append(svg);
  const legend = node('p', 'mapLegend', 'Lighter to stronger shading shows relative page views. Exact counts are listed below.');
  card.append(legend);
  return card;
}
`;

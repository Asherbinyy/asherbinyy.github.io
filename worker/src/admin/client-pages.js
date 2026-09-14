/** Page destinations map to existing documents; publication remains per document. */
export const clientPages = `
const sitePages = [
  {id: 'site-home', label: 'Home', route: '/', description: 'Introduction, figures and the work shown on the home page.', sections: [
    ['Introduction', 'profile.json', [], 'Name, greeting, positioning, figures and countries.'],
    ['Career', 'career.json', ['roles'], 'Work history shared with Journey.'],
  ], unavailable: 'Skills, learning topics and tools need the current profile fields added to the admin schema.'},
  {id: 'journey', label: 'Journey', route: '/journey', description: 'Career stops, locations and linked projects.', sections: [
    ['Journey stops', 'career.json', ['roles'], 'Add, reorder and edit stops, dates and project references.'],
  ]},
  {id: 'work', label: 'Work', route: '/work', description: 'Projects and their individual detail pages.', sections: [
    ['Projects', 'apps.json', ['apps'], 'Descriptions, store links, screenshots and galleries.'],
  ], unavailable: 'New gallery fields can be edited, but the public gallery renderer is still pending.'},
  {id: 'writing', label: 'Writing', route: '/writing', description: 'Articles supplied by the connected Medium feed.', sections: [
    ['Medium profile', 'profile.json', ['contact'], 'Edit the existing Medium contact link.'],
  ], unavailable: 'Article titles, covers and feed selection are managed outside this panel. Changing the contact link does not change the article feed.'},
  {id: 'about', label: 'About', route: '/about', description: 'Biography, portrait, education and contact details.', sections: [
    ['Biography & portrait', 'profile.json', [], 'Biography, portrait, location and contact details.'],
    ['Education & research', 'education.json', ['entries'], 'Qualifications, modules, marks and supplied evidence.'],
    ['Links', 'profile.json', ['links'], 'New flexible links await the public renderer.'],
    ['Name recording', 'profile.json', ['nameAudio'], 'Upload or record pronunciation; the public player integration is pending.'],
  ]},
  {id: 'courtyard', label: 'Courtyard', route: '/courtyard', description: 'Interests, favourite things and the game.', sections: [
    ['Interests', 'interests.json', ['interests'], 'Interest text, links and galleries.'],
  ], unavailable: 'Game physics, levels and leaderboard controls are not available in the admin. Interest galleries still await the public renderer.'},
  {id: 'resume', label: 'CV & brief', route: '/cv/', description: 'Shared information used by the generated CV and brief.', sections: [
    ['Identity & CV file', 'profile.json', [], 'Identity, contact details and the bundled PDF path.'],
    ['Experience', 'career.json', ['roles'], 'Career history shared with Home and Journey.'],
    ['Qualifications', 'education.json', ['entries'], 'Education and evidence shared with About.'],
  ], unavailable: 'The CV, brief and metadata update when the public site is rebuilt. Publishing a content document alone does not rebuild them. PDF upload is not supported.'},
];

const pageFields = {
  'site-home': ['name', 'displayName', 'greeting', 'positioning', 'status', 'venture', 'stats', 'reach', 'contact', 'cvFile'],
  about: ['name', 'displayName', 'biography', 'portrait', 'location', 'status', 'contact'],
};

function closeMenu() {
  document.body.classList.remove('menuOpen');
  el('menuToggle').setAttribute('aria-expanded', 'false');
}

function pageFor(id) { return sitePages.find((page) => page.id === id); }

function renderPage() {
  const page = pageFor(state.view);
  const pane = el('editor');
  pane.replaceChildren();
  pane.append(pageHeading(page.label, page.description, page.route));
  const cards = node('div', 'pageGrid');
  for (const [label, file, path, description] of page.sections) {
    const card = node('button', 'pageCard');
    card.type = 'button';
    card.append(node('strong', null, label), node('span', 'note', description));
    const held = state.docs.get(file);
    card.append(node('span', 'meta', dirty(file) ? 'Unpublished changes' : held?.source === 'published' ? 'Content revision ' + held.revision : 'Bundled content'));
    card.onclick = () => { state.page = page.id; go(file, path); };
    cards.append(card);
  }
  pane.append(cards);
  if (page.unavailable) {
    const limits = node('div', 'group');
    limits.append(node('h3', null, 'Not available yet'), node('p', 'note', page.unavailable));
    pane.append(limits);
  }
  pane.append(node('p', 'note', 'Shared content keeps one draft across pages. Review and publish applies to the selected content document, including changes made from other pages.'));
}

function pageHeading(title, description, route) {
  const head = node('div', 'panelHead');
  const titles = node('div', 'titles');
  titles.append(node('h2', null, title), node('p', null, description));
  head.append(titles);
  if (route) {
    const link = node('a', 'siteLink', 'View page ↗');
    link.href = new URL(route, SITE).href;
    link.target = '_blank';
    link.rel = 'noopener noreferrer';
    link.setAttribute('aria-label', 'View ' + title + ' on the portfolio');
    head.append(link);
  }
  return head;
}

function renderAppearance() {
  const pane = el('editor');
  pane.replaceChildren(pageHeading('Appearance', 'The portfolio’s themes, typography and page backgrounds.'));
  const notice = node('div', 'warn');
  notice.append(node('strong', null, 'Site settings are not connected yet'), node('p', null, 'The public app does not read published appearance settings. These reference samples cannot change the website.'));
  pane.append(notice);
  const themes = node('div', 'pageGrid');
  for (const [label, palette] of [['Kemet', 'dark'], ['Deshret', 'light']]) {
    const sample = node('section', 'paletteSample');
    sample.dataset.palette = palette;
    sample.append(node('strong', null, label), node('p', null, 'Permanent base theme'), node('p', 'note', 'Space Grotesk headings · IBM Plex body text'));
    const swatches = node('div', 'swatches');
    swatches.setAttribute('aria-hidden', 'true');
    for (const role of ['surface', 'raised', 'text', 'gold']) {
      const swatch = node('span');
      swatch.style.background = 'var(--' + role + ')';
      swatches.append(swatch);
    }
    sample.append(swatches);
    themes.append(sample);
  }
  pane.append(themes);
  const settings = node('div', 'group');
  settings.append(node('h3', null, 'Typography & backgrounds'));
  const table = node('table', 'dataTable');
  const caption = node('caption', 'note', 'Current design references and unavailable settings');
  table.append(caption);
  for (const [name, value] of [
    ['Headings', 'Space Grotesk'], ['Latin body text', 'IBM Plex Sans'],
    ['Arabic text', 'IBM Plex Sans Arabic'], ['Numbers', 'IBM Plex Mono'],
    ['Font selection', 'Unavailable until the app reads published font settings'],
    ['Page backgrounds', 'Unavailable until the app exposes supported patterns'],
    ['Extra presets', 'Unavailable; no approved preset definitions'],
  ]) {
    const row = node('tr');
    const heading = node('th', null, name); heading.scope = 'row';
    row.append(heading, node('td', null, value)); table.append(row);
  }
  settings.append(table); pane.append(settings);
}

// Use the existing font files through the already allowed bundle connection.
// Loading ArrayBuffers needs no new font host or CSP relaxation.
async function loadPortfolioFonts() {
  const base = BUNDLE.replace(/\\/content\\/?$/, '/fonts/');
  const fonts = [
    ['Space Grotesk', 'SpaceGrotesk-Medium-subset.ttf', '500'],
    ['IBM Plex Sans', 'IBMPlexSans-Regular-subset.ttf', '400'],
    ['IBM Plex Sans', 'IBMPlexSans-SemiBold-subset.ttf', '600'],
    ['IBM Plex Sans Arabic', 'IBMPlexSansArabic-Regular-subset.ttf', '400'],
    ['IBM Plex Mono', 'IBMPlexMono-Regular-subset.ttf', '400'],
  ];
  await Promise.allSettled(fonts.map(async ([family, file, weight]) => {
    const response = await fetch(base + file);
    if (!response.ok) return;
    const face = new FontFace(family, await response.arrayBuffer(), {weight: weight});
    await face.load(); document.fonts.add(face);
  }));
}
loadPortfolioFonts();
`;

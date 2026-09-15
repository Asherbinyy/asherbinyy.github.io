/** Page destinations map to existing documents; publication remains per document. */
export const clientPages = `
const sitePages = [
  {id: 'site-home', label: 'Home', route: '/', description: 'Introduction, figures and the work shown on the home page.', sections: [
    ['Introduction', 'profile.json', [], 'Name, greeting, positioning, figures and countries.'],
    ['Career', 'career.json', ['roles'], 'Work history shared with Journey.'],
  ]},
  {id: 'journey', label: 'Journey', route: '/journey', description: 'Career stops, locations and linked projects.', sections: [
    ['Journey stops', 'career.json', ['roles'], 'Add, reorder and edit stops, dates and project references.'],
  ]},
  {id: 'work', label: 'Work', route: '/work', description: 'Projects and their individual detail pages.', sections: [
    ['Projects', 'apps.json', ['apps'], 'Descriptions, store links, screenshots and galleries.'],
  ]},
  {id: 'writing', label: 'Articles', route: '/work', description: 'Articles on Work, supplied by the connected Medium feed.', sections: [
    ['Medium profile', 'profile.json', ['contact'], 'Edit the existing Medium contact link.'],
  ], unavailable: 'Article titles, covers and feed selection are managed outside this panel. Changing the contact link does not change the article feed.'},
  {id: 'services', label: 'Services', route: '/services', description: 'Your supplied services and ways to get in touch.', sections: [
    ['Services offered', 'profile.json', ['services'], 'Add, reorder and edit the services shown on the public page.'],
    ['Contact & booking', 'profile.json', ['contact'], 'Contact cards and the booking destination.'],
  ]},
  {id: 'about', label: 'About', route: '/about', description: 'Biography, portrait, education and contact details.', sections: [
    ['Biography & portrait', 'profile.json', [], 'Biography, portrait, location and contact details.'],
    ['Education & research', 'education.json', ['entries'], 'Qualifications, modules, marks and supplied evidence.'],
    ['Links', 'profile.json', ['links'], 'Public links in your chosen order.'],
    ['Name recording', 'profile.json', ['nameAudio'], 'Upload or record pronunciation for the public player.'],
  ]},
  {id: 'courtyard', label: 'Courtyard', route: '/courtyard', description: 'Interests, favourite things and the game.', sections: [
    ['Interests', 'interests.json', ['interests'], 'Interest text, links and galleries.'],
  ], unavailable: 'Game physics, levels and leaderboard controls are not available in the admin.'},
  {id: 'resume', label: 'CV & brief', route: '/cv/', description: 'Shared information used by the generated CV and brief.', sections: [
    ['Identity & CV file', 'profile.json', [], 'Identity, contact details and the bundled PDF path.'],
    ['Experience', 'career.json', ['roles'], 'Career history shared with Home and Journey.'],
    ['Qualifications', 'education.json', ['entries'], 'Education and evidence shared with About.'],
  ], unavailable: 'The CV, brief and metadata update when the public site is rebuilt. Publishing a content document alone does not rebuild them. PDF upload is not supported.'},
];

const pageFields = {
  'site-home': ['name', 'displayName', 'greeting', 'positioning', 'status', 'venture', 'stats', 'reach', 'contact', 'cvFile', 'skills', 'learning', 'tools'],
  about: ['name', 'displayName', 'biography', 'portrait', 'location', 'status', 'contact', 'skills', 'learning', 'tools'],
};

function closeMenu() {
  document.body.classList.remove('menuOpen');
  syncPanelControls();
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
  state.page = null;
  go('profile.json', ['appearance']);
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

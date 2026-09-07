// ignore_for_file: avoid_print
/// Build-time generator for static routes.
///
/// Reads `assets/content/{profile,career,apps,education}.json` and produces:
///   - `web/cv/index.html`    — full semantic HTML CV, JSON-LD Person schema
///   - `web/brief/index.html` — recruiter 60-second read
///   - `web/robots.txt`
///   - `web/sitemap.xml`
///
/// Runs as `dart run tool/generate_static.dart` in CI before `flutter build`.
/// No Flutter imports — pure Dart with dart:io for file access.
library;

import 'dart:convert';
import 'dart:io';

/// Base URL for the published site. Single constant to update when a custom
/// domain is configured.
const String baseUrl = 'https://asherbinyy.github.io';

// ---------------------------------------------------------------------------
// Entry
// ---------------------------------------------------------------------------

void main() {
  final projectRoot = _findProjectRoot();
  final contentDir = Directory('$projectRoot/assets/content');
  final webDir = Directory('$projectRoot/web');

  // Load content JSON.
  final profile = _readJson(File('${contentDir.path}/profile.json'));
  final career = _readJson(File('${contentDir.path}/career.json'));
  final apps = _readJson(File('${contentDir.path}/apps.json'));
  final education = _readJson(File('${contentDir.path}/education.json'));

  // Generate pages.
  _writeFile(
    File('${webDir.path}/cv/index.html'),
    _generateCv(profile, career, apps, education),
  );
  _writeFile(
    File('${webDir.path}/brief/index.html'),
    _generateBrief(profile, apps, education),
  );
  _writeFile(File('${webDir.path}/robots.txt'), _generateRobots());
  _writeFile(File('${webDir.path}/sitemap.xml'), _generateSitemap());

  print('Static routes generated successfully.');
}

// ---------------------------------------------------------------------------
// Content helpers
// ---------------------------------------------------------------------------

/// Reads and decodes a JSON file.
Map<String, dynamic> _readJson(File file) {
  if (!file.existsSync()) {
    throw FileSystemException('Required content file not found', file.path);
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

/// Creates parent directories and writes content.
void _writeFile(File file, String content) {
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
  print('  wrote ${file.path}');
}

/// Locates the project root by walking up to find pubspec.yaml.
String _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 10; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir.path;
    dir = dir.parent;
  }
  // Fall back to the current directory — CI runs from the project root.
  return Directory.current.path;
}

/// Extracts the English text from a localized text map, falling back to an
/// empty string.
/// The name a human reads: `displayName` where set, else the legal `name`.
///
/// Only `/brief`'s heading uses this. `/cv` shows the legal name throughout,
/// and every `<title>`, Open Graph tag and JSON-LD `Person` record on both
/// pages keeps it too -- those are what an ATS parses and what a recruiter
/// types into a search box, and a page that answers to "Sherbini" alone is a
/// page that does not surface when someone searches the name on his CV.
String _shownName(Map<String, dynamic> profile) {
  final display = _en(profile['displayName']);
  return display.isEmpty ? _en(profile['name']) : display;
}

String _en(dynamic localizedText) {
  if (localizedText is Map) {
    return (localizedText['en'] ?? '') as String;
  }
  return localizedText?.toString() ?? '';
}

/// HTML-encodes text content — escapes &amp;, &lt;, &gt; for safe text display.
String _esc(String text) =>
    const HtmlEscape(HtmlEscapeMode.element).convert(text);

/// HTML-encodes for use inside double-quoted attributes — also escapes quotes.
String _escAttr(String text) =>
    const HtmlEscape(HtmlEscapeMode.attribute).convert(text);

/// Formats a YYYY-MM date string for display.
String _formatDate(String? date) {
  if (date == null || date.isEmpty) return 'Present';
  final parts = date.split('-');
  if (parts.length < 2) return date;
  const months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = int.tryParse(parts[1]) ?? 0;
  final monthName = month > 0 && month < 13 ? months[month] : parts[1];
  return '$monthName ${parts[0]}';
}

// ---------------------------------------------------------------------------
// Shared CSS — inline, no external requests
// ---------------------------------------------------------------------------

/// Critical CSS matching Nocturne design tokens, inlined in both pages.
/// Both palettes, transcribed from `01-DESIGN-SYSTEM.md` §2.
///
/// These carry the contrast corrections, which this file had missed until
/// Milestone 3: `--text-muted` was still `#57687B`, measuring 3.53:1 against
/// the page. `/cv` and `/brief` are the two indexable pages, so they were the
/// worst place on the site to leave below AA.
///
/// The app follows the viewer's stored theme choice. These are static HTML
/// with nowhere to store one and no JavaScript to read it, so they follow the
/// operating system instead — the only preference a plain document can honour.
///
/// Comments live here rather than inside the emitted CSS: every byte of that
/// string ships to every reader, and the reasoning is for whoever edits this
/// file next.
String _criticalCss() => '''
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  color-scheme:dark light;
  --void:#121826;--surface:#1A2233;--surface-raised:#232D40;
  --hairline:#2E3A50;--hairline-strong:#3F4D66;
  --beacon:#E3A93F;--beacon-dim:#92702E;
  --instrument:#CBD6E6;--instrument-mid:#93A2B8;--instrument-dim:#69788F;
  --text-primary:#EDF1F8;--text-secondary:#A8B4C6;--text-muted:#8895A8;
}
@media(prefers-color-scheme:light){
  :root{
    --void:#F2E9D8;--surface:#E9DEC8;--surface-raised:#FCF7EC;
    --hairline:#D6C8AC;--hairline-strong:#AD9C7C;
    --beacon:#885912;--beacon-dim:#9C7534;
    --instrument:#37424F;--instrument-mid:#586472;--instrument-dim:#8A7C63;
    --text-primary:#13181F;--text-secondary:#48545F;--text-muted:#5A6470;
  }
}
html{font-size:16px;line-height:1.6;color:var(--text-primary);background:var(--void);font-family:'IBM Plex Sans',-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;-webkit-font-smoothing:antialiased}
body{max-width:720px;margin:0 auto;padding:32px 20px 64px}
a{color:var(--beacon);text-decoration:none}
a:hover,a:focus{text-decoration:underline;outline:2px solid var(--beacon);outline-offset:2px}
a:visited{color:var(--beacon-dim)}
h1{font-family:'Space Grotesk','IBM Plex Sans',sans-serif;font-size:clamp(26px,3.2vw,40px);font-weight:500;line-height:1.1;letter-spacing:-0.01em;color:var(--text-primary);margin-bottom:8px}
h2{font-family:'Space Grotesk','IBM Plex Sans',sans-serif;font-size:22px;font-weight:500;line-height:1.25;color:var(--text-primary);margin:32px 0 12px;padding-bottom:8px;border-bottom:1px solid var(--hairline)}
h3{font-size:18px;font-weight:500;color:var(--text-primary);margin:16px 0 4px}
p,li{color:var(--text-secondary);max-width:68ch}
ul{list-style:none;padding:0}
.meta{font-family:'IBM Plex Mono',monospace;font-size:13px;color:var(--text-muted);line-height:1.3}
.positioning{font-size:18px;color:var(--text-secondary);margin-bottom:4px}
.status{font-size:14px;color:var(--text-muted);margin-bottom:24px}
.role-item{padding:16px 0;border-bottom:1px solid var(--hairline)}
.role-item:last-child{border-bottom:none}
.role-header{display:flex;justify-content:space-between;align-items:baseline;flex-wrap:wrap;gap:4px}
.company{font-weight:600;color:var(--text-primary)}
.dates{font-family:'IBM Plex Mono',monospace;font-size:13px;color:var(--text-muted);white-space:nowrap}
.title{color:var(--text-secondary);font-size:14px}
.location{color:var(--text-muted);font-size:13px}
.stack{display:flex;flex-wrap:wrap;gap:6px;margin-top:8px}
.stack span{font-size:12px;color:var(--instrument-mid);border:1px solid var(--hairline);border-radius:2px;padding:1px 6px}
.app-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:12px;margin-top:8px}
.app-card{border:1px solid var(--hairline);border-radius:2px;padding:12px}
.app-card h3{margin:0 0 4px;font-size:16px}
.app-card .domain{font-size:12px;color:var(--text-muted)}
.app-card .metric{font-family:'IBM Plex Mono',monospace;font-size:13px;color:var(--beacon)}
.app-links{margin-top:6px;font-size:13px}
.app-links a{margin-right:12px}
.contact-list{margin-top:8px}
.contact-list li{padding:4px 0}
.contact-list li a{font-family:'IBM Plex Mono',monospace;font-size:14px}
.module-list{margin-top:8px}
.module-item{display:flex;justify-content:space-between;padding:2px 0;font-size:14px}
.module-mark{font-family:'IBM Plex Mono',monospace;color:var(--instrument);font-variant-numeric:tabular-nums}
.highlight{color:var(--text-secondary);font-size:14px;padding:4px 0}
.skills-list{display:flex;flex-wrap:wrap;gap:8px;margin-top:8px}
.skills-list span{font-size:13px;color:var(--instrument-mid);border:1px solid var(--hairline);border-radius:2px;padding:2px 8px}
footer{margin-top:48px;padding-top:16px;border-top:1px solid var(--hairline);font-size:13px;color:var(--text-muted)}
@media(max-width:600px){body{padding:20px 16px 48px}.role-header{flex-direction:column}.app-grid{grid-template-columns:1fr}}
''';

// ---------------------------------------------------------------------------
// JSON-LD Person schema
// ---------------------------------------------------------------------------

String _jsonLd(Map<String, dynamic> profile, Map<String, dynamic> education) {
  final contact = profile['contact'] as Map<String, dynamic>? ?? {};
  final sameAs = <String>[
    if (contact['linkedin'] != null) contact['linkedin'] as String,
    if (contact['github'] != null) contact['github'] as String,
    if (contact['gitlab'] != null) contact['gitlab'] as String,
    if (contact['medium'] != null) contact['medium'] as String,
    if (contact['linktree'] != null) contact['linktree'] as String,
  ];

  final entries = education['entries'] as List<dynamic>? ?? [];
  final alumniOf = <Map<String, dynamic>>[
    for (final entry in entries.cast<Map<String, dynamic>>())
      {'@type': 'CollegeOrUniversity', 'name': _en(entry['institution'])},
  ];

  final knowsAbout = <String>[
    'Flutter',
    'Dart',
    'Mobile Engineering',
    'Swift',
    'SwiftUI',
    'UIKit',
    'Firebase',
    'REST APIs',
    'CI/CD',
    'Clean Architecture',
  ];

  final schema = <String, dynamic>{
    '@context': 'https://schema.org',
    '@type': 'Person',
    'name': _en(profile['name']),
    'jobTitle': 'Mobile Engineer',
    'url': baseUrl,
    'email': contact['email'],
    'sameAs': sameAs,
    'alumniOf': alumniOf,
    'knowsAbout': knowsAbout,
    if (_en(profile['location']).isNotEmpty)
      'address': {
        '@type': 'PostalAddress',
        'addressLocality': 'Manchester',
        'addressCountry': 'GB',
      },
  };

  return jsonEncode(schema);
}

// ---------------------------------------------------------------------------
// /cv generator
// ---------------------------------------------------------------------------

String _generateCv(
  Map<String, dynamic> profile,
  Map<String, dynamic> career,
  Map<String, dynamic> apps,
  Map<String, dynamic> education,
) {
  // /cv shows the legal name everywhere, with no exception. It is the page an
  // ATS parses and the one a recruiter matches against a CV already on file,
  // and a mismatch there is a rejected application rather than a style choice.
  final name = _esc(_en(profile['name']));
  final positioning = _esc(_en(profile['positioning']));
  final location = _esc(_en(profile['location']));
  final status = _esc(_en(profile['status']));
  // Element escaping leaves double quotes intact, which would break out of a
  // meta tag's content attribute, so attribute positions get their own values.
  final nameAttr = _escAttr(_en(profile['name']));
  final positioningAttr = _escAttr(_en(profile['positioning']));
  final locationAttr = _escAttr(_en(profile['location']));
  final contact = profile['contact'] as Map<String, dynamic>? ?? {};

  final buf = StringBuffer()
    ..writeln('<!DOCTYPE html>')
    ..writeln('<html lang="en" dir="ltr">')
    ..writeln('<head>')
    ..writeln('<meta charset="UTF-8">')
    ..writeln(
      '<meta name="viewport" '
      'content="width=device-width, initial-scale=1.0">',
    )
    // One per scheme, so the browser chrome matches the page it frames.
    ..writeln(
      '<meta name="theme-color" media="(prefers-color-scheme: dark)" '
      'content="#121826">',
    )
    ..writeln(
      '<meta name="theme-color" media="(prefers-color-scheme: light)" '
      'content="#F2E9D8">',
    )
    ..writeln(
      '<meta name="description" content="$positioningAttr '
      '${locationAttr.isNotEmpty ? '— $locationAttr' : ''}">',
    )
    ..writeln('<title>$name — CV</title>')
    ..writeln('<link rel="icon" type="image/png" href="/favicon.png">')
    ..writeln('<link rel="canonical" href="$baseUrl/cv/">')
    // Open Graph
    ..writeln('<meta property="og:type" content="profile">')
    ..writeln('<meta property="og:title" content="$nameAttr — CV">')
    ..writeln('<meta property="og:description" content="$positioningAttr">')
    ..writeln('<meta property="og:url" content="$baseUrl/cv/">')
    ..writeln(
      '<meta property="og:image" '
      'content="$baseUrl/icons/icon-512.png">',
    )
    // Twitter Card
    ..writeln('<meta name="twitter:card" content="summary">')
    ..writeln('<meta name="twitter:title" content="$nameAttr — CV">')
    ..writeln('<meta name="twitter:description" content="$positioningAttr">')
    ..writeln('<style>')
    ..write(_criticalCss())
    ..writeln('</style>')
    // JSON-LD
    ..writeln(
      '<script type="application/ld+json">'
      '${_jsonLd(profile, education)}'
      '</script>',
    )
    ..writeln('</head>')
    ..writeln('<body>')
    // Header
    ..writeln('<header>')
    ..writeln('<h1>$name</h1>')
    ..writeln('<p class="positioning">$positioning</p>');

  if (status.isNotEmpty) {
    buf.writeln('<p class="status">$status</p>');
  }
  if (location.isNotEmpty) {
    buf.writeln('<p class="meta">$location</p>');
  }

  buf
    ..writeln('</header>')
    // Main content
    ..writeln('<main>')
    // Experience section
    ..writeln('<section>')
    ..writeln('<h2>Experience</h2>');
  final roles = (career['roles'] as List<dynamic>? ?? [])
      .cast<Map<String, dynamic>>()
      .reversed
      .toList();
  for (final role in roles) {
    _writeCvRole(buf, role);
  }
  buf
    ..writeln('</section>')
    // Applications section
    ..writeln('<section>')
    ..writeln('<h2>Shipped applications</h2>')
    ..writeln('<div class="app-grid">');
  final allApps = (apps['apps'] as List<dynamic>? ?? [])
      .cast<Map<String, dynamic>>();
  for (final app in allApps) {
    _writeCvApp(buf, app);
  }
  buf
    ..writeln('</div>')
    ..writeln('</section>')
    // Education section
    ..writeln('<section>')
    ..writeln('<h2>Education</h2>');
  final entries = (education['entries'] as List<dynamic>? ?? [])
      .cast<Map<String, dynamic>>();
  for (final entry in entries) {
    _writeCvEducation(buf, entry);
  }
  buf
    ..writeln('</section>')
    // Skills section
    ..writeln('<section>')
    ..writeln('<h2>Skills</h2>')
    ..writeln('<div class="skills-list">');
  const skills = [
    'Flutter',
    'Dart',
    'Swift',
    'SwiftUI',
    'UIKit',
    'Firebase',
    'REST',
    'CI/CD',
    'GitHub Actions',
    'Codemagic',
    'Fastlane',
    'Clean Architecture',
    'Git',
    'Jira',
    'Azure DevOps',
    'Power BI',
  ];
  for (final skill in skills) {
    buf.writeln('<span>${_esc(skill)}</span>');
  }
  buf
    ..writeln('</div>')
    ..writeln('</section>')
    // Contact section
    ..writeln('<section>')
    ..writeln('<h2>Contact</h2>');
  _writeContactList(buf, contact);
  buf
    ..writeln('</section>')
    ..writeln('</main>')
    // Footer
    ..writeln('<footer>')
    ..writeln(
      '<p>This page is generated from structured data and renders '
      'without JavaScript.</p>',
    )
    ..writeln('</footer>')
    ..writeln('</body>')
    ..writeln('</html>');

  return buf.toString();
}

/// Writes a single career role block for the CV page.
void _writeCvRole(StringBuffer buf, Map<String, dynamic> role) {
  final company = _esc(role['company']?.toString() ?? role['id'] as String);
  final title = _esc(_en(role['title']));
  final city = _esc(role['city']?.toString() ?? '');
  final country = _esc(role['country']?.toString() ?? '');
  final start = _formatDate(role['start'] as String?);
  final end = _formatDate(role['end'] as String?);
  final summary = _esc(_en(role['summary']));
  final stack = (role['stack'] as List<dynamic>?)?.cast<String>() ?? <String>[];

  buf
    ..writeln('<article class="role-item">')
    ..writeln('<div class="role-header">')
    ..writeln('<span class="company">$company</span>')
    ..writeln('<span class="dates">$start – $end</span>')
    ..writeln('</div>');

  if (title.isNotEmpty) {
    buf.writeln('<p class="title">$title</p>');
  }
  if (city.isNotEmpty || country.isNotEmpty) {
    buf.writeln(
      '<p class="location">'
      '${[city, country].where((s) => s.isNotEmpty).join(', ')}'
      '</p>',
    );
  }
  if (summary.isNotEmpty) {
    buf.writeln('<p>$summary</p>');
  }
  if (stack.isNotEmpty) {
    buf.writeln('<div class="stack">');
    for (final tech in stack) {
      buf.writeln('<span>${_esc(tech)}</span>');
    }
    buf.writeln('</div>');
  }

  buf.writeln('</article>');
}

/// Writes a single app card for the CV page.
void _writeCvApp(StringBuffer buf, Map<String, dynamic> app) {
  final name = _esc(app['name'] as String? ?? '');
  final domain = _esc(app['domain'] as String? ?? '');
  final roleDesc = _esc(_en(app['role']));
  final metric = app['metric'] as String?;
  final store = app['store'] as Map<String, dynamic>? ?? {};

  buf
    ..writeln('<div class="app-card">')
    ..writeln('<h3>$name</h3>')
    ..writeln('<p class="domain">$domain</p>');

  if (roleDesc.isNotEmpty) {
    buf.writeln('<p class="title">$roleDesc</p>');
  }
  if (metric != null && metric.isNotEmpty) {
    buf.writeln('<p class="metric">${_esc(metric)}</p>');
  }
  if (store.isNotEmpty) {
    buf.writeln('<div class="app-links">');
    if (store['ios'] != null) {
      buf.writeln(
        '<a href="${_escAttr(store['ios'] as String)}" '
        'rel="noopener noreferrer" target="_blank">App Store</a>',
      );
    }
    if (store['android'] != null) {
      buf.writeln(
        '<a href="${_escAttr(store['android'] as String)}" '
        'rel="noopener noreferrer" target="_blank">Google Play</a>',
      );
    }
    buf.writeln('</div>');
  }

  buf.writeln('</div>');
}

/// Writes an education entry for the CV page.
void _writeCvEducation(StringBuffer buf, Map<String, dynamic> entry) {
  final institution = _esc(_en(entry['institution']));
  final award = _esc(_en(entry['award']));
  final start = _formatDate(entry['start'] as String?);
  final end = _formatDate(entry['end'] as String?);
  final status = entry['status'] == null ? null : _en(entry['status']);
  final overallMark = entry['overallMark'];
  final modules =
      (entry['modules'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
  final highlights = (entry['highlights'] as List<dynamic>? ?? [])
      .map(_en)
      .where((h) => h.isNotEmpty)
      .toList();

  buf
    ..writeln('<article class="role-item">')
    ..writeln('<div class="role-header">')
    ..writeln('<span class="company">$institution</span>')
    ..writeln('<span class="dates">$start – $end</span>')
    ..writeln('</div>')
    ..writeln('<p class="title">$award</p>');

  if (status != null && status.isNotEmpty) {
    buf.writeln('<p class="meta">${_esc(status)}</p>');
  }
  if (overallMark != null) {
    buf.writeln(
      '<p class="meta">Overall mark: '
      '<span class="module-mark">$overallMark%</span></p>',
    );
  }

  if (modules.isNotEmpty) {
    buf.writeln('<div class="module-list">');
    for (final mod in modules) {
      final modName = _esc(_en(mod['name']));
      final mark = mod['mark'];
      buf.writeln(
        '<div class="module-item"><span>$modName</span><span class="module-mark">${mark ?? ''}%</span></div>',
      );
    }
    buf.writeln('</div>');
  }

  for (final highlight in highlights) {
    buf.writeln('<p class="highlight">• ${_esc(highlight)}</p>');
  }

  buf.writeln('</article>');
}

/// Writes the contact links list.
void _writeContactList(StringBuffer buf, Map<String, dynamic> contact) {
  buf.writeln('<ul class="contact-list">');

  final email = contact['email'] as String?;
  if (email != null && email.isNotEmpty) {
    buf.writeln(
      '<li><a href="mailto:${_escAttr(email)}">${_esc(email)}</a></li>',
    );
  }

  // The phone number is deliberately not published here. These two pages exist
  // to be crawled, and an indexed tel: link is harvested by scrapers; email and
  // the profile links are how recruiters actually make contact. It stays in
  // profile.json for the CV document itself.

  final linkedin = contact['linkedin'] as String?;
  if (linkedin != null && linkedin.isNotEmpty) {
    buf.writeln(
      '<li><a href="${_escAttr(linkedin)}" rel="noopener noreferrer" '
      'target="_blank">LinkedIn</a></li>',
    );
  }

  final github = contact['github'] as String?;
  if (github != null && github.isNotEmpty) {
    buf.writeln(
      '<li><a href="${_escAttr(github)}" rel="noopener noreferrer" '
      'target="_blank">GitHub</a></li>',
    );
  }

  final gitlab = contact['gitlab'] as String?;
  if (gitlab != null && gitlab.isNotEmpty) {
    buf.writeln(
      '<li><a href="${_escAttr(gitlab)}" rel="noopener noreferrer" '
      'target="_blank">GitLab</a></li>',
    );
  }

  final medium = contact['medium'] as String?;
  if (medium != null && medium.isNotEmpty) {
    buf.writeln(
      '<li><a href="${_escAttr(medium)}" rel="noopener noreferrer" '
      'target="_blank">Medium</a></li>',
    );
  }

  final linktree = contact['linktree'] as String?;
  if (linktree != null && linktree.isNotEmpty) {
    buf.writeln(
      '<li><a href="${_escAttr(linktree)}" rel="noopener noreferrer" '
      'target="_blank">Linktree</a></li>',
    );
  }

  buf.writeln('</ul>');
}

// ---------------------------------------------------------------------------
// /brief generator
// ---------------------------------------------------------------------------

String _generateBrief(
  Map<String, dynamic> profile,
  Map<String, dynamic> apps,
  Map<String, dynamic> education,
) {
  // The heading greets the reader with the name the owner uses; the title and
  // every metadata tag below keep the legal one, so searching the name on his
  // CV still lands here.
  final name = _esc(_shownName(profile));
  final legalName = _esc(_en(profile['name']));
  final positioning = _esc(_en(profile['positioning']));
  final location = _esc(_en(profile['location']));
  final status = _esc(_en(profile['status']));
  final nameAttr = _escAttr(_en(profile['name']));
  final positioningAttr = _escAttr(_en(profile['positioning']));
  final contact = profile['contact'] as Map<String, dynamic>? ?? {};

  final featured = (apps['apps'] as List<dynamic>? ?? [])
      .cast<Map<String, dynamic>>()
      .where((a) => a['featured'] == true)
      .toList();

  final entries = (education['entries'] as List<dynamic>? ?? [])
      .cast<Map<String, dynamic>>();

  final buf = StringBuffer()
    ..writeln('<!DOCTYPE html>')
    ..writeln('<html lang="en" dir="ltr">')
    ..writeln('<head>')
    ..writeln('<meta charset="UTF-8">')
    ..writeln(
      '<meta name="viewport" '
      'content="width=device-width, initial-scale=1.0">',
    )
    // One per scheme, so the browser chrome matches the page it frames.
    ..writeln(
      '<meta name="theme-color" media="(prefers-color-scheme: dark)" '
      'content="#121826">',
    )
    ..writeln(
      '<meta name="theme-color" media="(prefers-color-scheme: light)" '
      'content="#F2E9D8">',
    )
    ..writeln(
      '<meta name="description" content="$nameAttr — $positioningAttr">',
    )
    ..writeln('<title>$legalName — Brief</title>')
    ..writeln('<link rel="icon" type="image/png" href="/favicon.png">')
    ..writeln('<link rel="canonical" href="$baseUrl/brief/">')
    // Open Graph
    ..writeln('<meta property="og:type" content="profile">')
    ..writeln('<meta property="og:title" content="$nameAttr — Brief">')
    ..writeln('<meta property="og:description" content="$positioningAttr">')
    ..writeln('<meta property="og:url" content="$baseUrl/brief/">')
    ..writeln(
      '<meta property="og:image" '
      'content="$baseUrl/icons/icon-512.png">',
    )
    ..writeln('<style>')
    ..write(_criticalCss())
    ..writeln('</style>')
    ..writeln('</head>')
    ..writeln('<body>')
    ..writeln('<header>')
    ..writeln('<h1>$name</h1>')
    ..writeln('<p class="positioning">$positioning</p>');

  if (status.isNotEmpty) {
    buf.writeln('<p class="status">$status</p>');
  }
  if (location.isNotEmpty) {
    buf.writeln('<p class="meta">$location</p>');
  }

  buf
    ..writeln('</header>')
    ..writeln('<main>');

  // Featured apps only
  if (featured.isNotEmpty) {
    buf
      ..writeln('<section>')
      ..writeln('<h2>Shipped applications</h2>')
      ..writeln('<div class="app-grid">');
    for (final app in featured) {
      _writeCvApp(buf, app);
    }
    buf
      ..writeln('</div>')
      ..writeln('</section>');
  }

  // Education summary — institution and award only
  if (entries.isNotEmpty) {
    buf
      ..writeln('<section>')
      ..writeln('<h2>Education</h2>');
    for (final entry in entries) {
      final institution = _esc(_en(entry['institution']));
      final award = _esc(_en(entry['award']));
      final entryStatus = entry['status'] == null ? null : _en(entry['status']);
      final overallMark = entry['overallMark'];
      buf
        ..writeln('<article class="role-item">')
        ..writeln('<h3>$institution</h3>')
        ..writeln('<p class="title">$award</p>');
      if (entryStatus != null && entryStatus.isNotEmpty) {
        buf.writeln('<p class="meta">${_esc(entryStatus)}</p>');
      }
      if (overallMark != null) {
        buf.writeln(
          '<p class="meta">Overall: '
          '<span class="module-mark">$overallMark%</span></p>',
        );
      }
      buf.writeln('</article>');
    }
    buf.writeln('</section>');
  }

  // Contact
  buf
    ..writeln('<section>')
    ..writeln('<h2>Contact</h2>');
  _writeContactList(buf, contact);
  buf
    ..writeln('</section>')
    ..writeln('</main>')
    ..writeln('<footer>')
    ..writeln('<p><a href="$baseUrl/">View full portfolio</a></p>')
    ..writeln('</footer>')
    ..writeln('</body>')
    ..writeln('</html>');

  return buf.toString();
}

// ---------------------------------------------------------------------------
// robots.txt
// ---------------------------------------------------------------------------

String _generateRobots() =>
    'User-agent: *\n'
    'Allow: /\n'
    'Sitemap: $baseUrl/sitemap.xml\n';

// ---------------------------------------------------------------------------
// sitemap.xml
// ---------------------------------------------------------------------------

String _generateSitemap() {
  final now = DateTime.now().toUtc().toIso8601String().split('T').first;
  // The application routes carry no trailing slash — AppRoute declares them
  // as '/work', not '/work/' — and go_router resolves the slashed forms to its
  // error route. Only the two static directories keep theirs, because Pages
  // serves them as directories.
  final routes = <String>[
    '/',
    '/cv/',
    '/brief/',
    '/signal',
    '/work',
    '/about',
    '/writing',
    '/privacy',
  ];

  final buf = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');

  for (final route in routes) {
    buf
      ..writeln('  <url>')
      ..writeln('    <loc>$baseUrl$route</loc>')
      ..writeln('    <lastmod>$now</lastmod>');

    // Static routes get higher priority — they are the indexable surface.
    if (route == '/cv/' || route == '/brief/') {
      buf.writeln('    <priority>0.9</priority>');
    } else if (route == '/') {
      buf.writeln('    <priority>1.0</priority>');
    } else {
      buf.writeln('    <priority>0.7</priority>');
    }

    buf.writeln('  </url>');
  }

  buf.writeln('</urlset>');
  return buf.toString();
}

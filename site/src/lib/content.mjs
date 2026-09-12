import { createHash } from 'node:crypto';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

function findRepositoryRoot() {
  let directory = process.cwd();
  while (true) {
    if (existsSync(resolve(directory, '.fvmrc')) && existsSync(resolve(directory, 'assets/content/profile.json'))) return directory;
    const parent = dirname(directory);
    if (parent === directory) throw new Error('Run from the portfolio repository or site directory');
    directory = parent;
  }
}

export const repositoryRoot = findRepositoryRoot();
export const siteUrl = 'https://asherbinyy.github.io';
export const documentNames = ['profile', 'career', 'apps', 'education', 'interests'];
export const locales = ['en', 'ar'];

function object(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

export function stableJson(value) {
  if (Array.isArray(value)) return `[${value.map(stableJson).join(',')}]`;
  if (object(value)) return `{${Object.keys(value).sort().map(key =>
    `${JSON.stringify(key)}:${stableJson(value[key])}`).join(',')}}`;
  return JSON.stringify(value);
}

export function digest(documents) {
  return createHash('sha256').update(stableJson(documents)).digest('hex');
}

/** Consumer validation; the admin publish schema remains Claude's responsibility. */
export function validateDocuments(documents) {
  for (const name of documentNames) {
    if (!object(documents?.[`${name}.json`])) throw new Error(`Missing document: ${name}.json`);
  }
  const profile = documents['profile.json'];
  for (const locale of locales) {
    for (const field of ['name', 'positioning']) {
      if (typeof profile[field]?.[locale] !== 'string' || !profile[field][locale].trim()) {
        throw new Error(`Missing profile.${field}.${locale}`);
      }
    }
  }
  for (const [name, field] of [
    ['career', 'roles'], ['apps', 'apps'], ['education', 'entries'], ['interests', 'interests'],
  ]) {
    if (!Array.isArray(documents[`${name}.json`][field])) throw new Error(`Invalid ${name}.${field}`);
  }
  const ids = new Set();
  for (const app of documents['apps.json'].apps) {
    if (!object(app) || !/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(app.id ?? '') ||
        typeof app.name !== 'string' || !app.name.trim() || ids.has(app.id)) {
      throw new Error('Invalid or duplicate project ID/name');
    }
    ids.add(app.id);
    for (const url of Object.values(app.store ?? {})) {
      if (url !== null && !safeUrl(url)) throw new Error(`Unsafe store URL for ${app.id}`);
    }
  }
  return documents;
}

export function loadSnapshot(snapshotFile = process.env.PORTFOLIO_SNAPSHOT) {
  let documents;
  if (snapshotFile) {
    const snapshot = JSON.parse(readFileSync(resolve(snapshotFile), 'utf8'));
    if (snapshot.schemaVersion !== 1) throw new Error('Unsupported snapshot schema');
    documents = validateDocuments(snapshot.documents);
    if (snapshot.revision !== digest(documents)) throw new Error('Snapshot revision mismatch');
  } else {
    documents = Object.fromEntries(documentNames.map(name => [
      `${name}.json`, JSON.parse(readFileSync(resolve(repositoryRoot, 'assets/content', `${name}.json`), 'utf8')),
    ]));
    validateDocuments(documents);
  }
  return { schemaVersion: 1, revision: digest(documents), documents };
}

export function text(value, locale = 'en') {
  if (typeof value === 'string') return value;
  return value?.[locale] || value?.en || '';
}

export function textLanguage(value, locale) {
  return typeof value === 'string' ? 'en' : value?.[locale] ? locale : 'en';
}

export function safeUrl(value) {
  if (typeof value !== 'string') return null;
  try {
    const url = new URL(value);
    return url.protocol === 'https:' && !url.username && !url.password ? url.href : null;
  } catch { return null; }
}

export function assetUrl(value) {
  if (typeof value !== 'string' || !/^assets\/[a-zA-Z0-9_./-]+$/.test(value) || value.split('/').includes('..')) {
    throw new Error('Invalid bundled public asset path');
  }
  return `/${value}`;
}

export function pathFor(kind, locale, id) {
  const prefix = locale === 'ar' ? '/ar' : '';
  if (kind === 'home') return `${prefix}/`;
  if (kind === 'work') return `${prefix}/work/`;
  if (kind === 'project' && /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(id ?? '')) return `${prefix}/work/${id}/`;
  throw new Error('Unsupported public route');
}

export function publicPages(snapshot) {
  const apps = snapshot.documents['apps.json'].apps;
  return locales.flatMap(locale => [
    { kind: 'home', locale, path: pathFor('home', locale) },
    { kind: 'work', locale, path: pathFor('work', locale) },
    ...apps.map(app => ({ kind: 'project', locale, id: app.id, path: pathFor('project', locale, app.id) })),
  ]);
}

const strings = Object.fromEntries(locales.map(locale => [locale,
  JSON.parse(readFileSync(resolve(repositoryRoot, `lib/app/l10n/app_${locale}.arb`), 'utf8')),
]));

export function ui(key, locale) {
  const value = strings[locale]?.[key];
  if (typeof value !== 'string') throw new Error(`Missing existing UI string: ${key}.${locale}`);
  return value;
}

export function metadata(page, snapshot) {
  const profile = snapshot.documents['profile.json'];
  const app = snapshot.documents['apps.json'].apps.find(app => app.id === page.id);
  const name = text(profile.name, page.locale);
  const title = page.kind === 'home' ? name : `${app?.name ?? ui('navWork', page.locale)} · ${name}`;
  const description = page.kind === 'project'
    ? `${app.name}. ${text(app.role, page.locale) || app.domain}`
    : text(profile.positioning, page.locale);
  const canonical = new URL(page.path, siteUrl).href;
  const sameAs = ['linkedin', 'github', 'gitlab', 'medium', 'linktree']
    .map(key => safeUrl(profile.contact?.[key])).filter(Boolean);
  return {
    title, description, canonical,
    schema: {
      '@context': 'https://schema.org',
      '@type': page.kind === 'home' ? 'ProfilePage' : 'WebPage',
      '@id': `${canonical}#page`, url: canonical, name: title,
      inLanguage: page.locale, description,
      ...(page.kind === 'home' ? { mainEntity: {
        '@type': 'Person', '@id': `${siteUrl}/#person`, name,
        alternateName: text(profile.name, page.locale === 'en' ? 'ar' : 'en'),
        url: `${siteUrl}/`, sameAs,
      } } : { about: { '@id': `${siteUrl}/#person` } }),
    },
  };
}

export function safeJson(value) {
  return JSON.stringify(value).replaceAll('<', '\\u003c');
}

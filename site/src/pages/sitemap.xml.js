import { loadSnapshot, publicPages, siteUrl } from '../lib/content.mjs';

export function GET() {
  const pages = publicPages(loadSnapshot());
  return new Response(`<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">${pages.map(page => `<url><loc>${siteUrl}${page.path}</loc></url>`).join('')}</urlset>`, {
    headers: { 'Content-Type': 'application/xml' },
  });
}

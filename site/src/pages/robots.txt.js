import { siteUrl } from '../lib/content.mjs';

export function GET() {
  return new Response(`User-agent: *\nAllow: /\nSitemap: ${siteUrl}/sitemap.xml\n`, {
    headers: { 'Content-Type': 'text/plain' },
  });
}

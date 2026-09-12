import { loadSnapshot, publicPages } from '../lib/content.mjs';

export function GET() {
  const snapshot = loadSnapshot();
  return new Response(JSON.stringify({
    schemaVersion: snapshot.schemaVersion,
    revision: snapshot.revision,
    pages: publicPages(snapshot).map(page => page.path),
  }), { headers: { 'Content-Type': 'application/json' } });
}

import { copyFileSync, mkdirSync, rmSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { assetUrl, loadSnapshot, repositoryRoot } from '../src/lib/content.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const profile = loadSnapshot().documents['profile.json'];
const assets = [
  'assets/brand/mark.svg',
  'assets/fonts/SpaceGrotesk-Medium-subset.ttf',
  'assets/fonts/IBMPlexSans-Regular-subset.ttf',
  'assets/fonts/IBMPlexSans-SemiBold-subset.ttf',
  'assets/fonts/IBMPlexSansArabic-Regular-subset.ttf',
  'assets/fonts/IBMPlexSansArabic-SemiBold-subset.ttf',
  ...(profile.portrait?.src && !profile.portrait.isPlaceholder ? [profile.portrait.src] : []),
  ...(profile.cvFile ? [profile.cvFile] : []),
];
// This directory is generated and ignored. Removed/replaced assets must not
// survive into the next public revision merely because a build is incremental.
rmSync(resolve(root, 'public', 'assets'), { recursive: true, force: true });
for (const asset of assets) {
  assetUrl(asset);
  const destination = resolve(root, 'public', asset);
  mkdirSync(dirname(destination), { recursive: true });
  copyFileSync(resolve(repositoryRoot, asset), destination);
}
console.log(`Prepared ${assets.length} explicitly referenced public assets.`);

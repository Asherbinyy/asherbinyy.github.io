import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://asherbinyy.github.io',
  output: 'static',
  // Existing shared links omit the slash; both forms resolve during migration.
  // Metadata still names one directory-style canonical URL.
  trailingSlash: 'ignore',
  build: { format: 'directory' },
  devToolbar: { enabled: false },
});

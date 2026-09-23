{{flutter_js}}
{{flutter_build_config}}

// Private preview uses the same country-flag font as the engine, served locally.
// No Google font request is needed while editing the owner's draft.
const isPreview = new URLSearchParams(location.search).get('preview') === '1';
_flutter.loader.load({
  config: isPreview
    ? {fontFallbackBaseUrl: new URL('fonts/fallback/', document.baseURI).href}
    : {},
});

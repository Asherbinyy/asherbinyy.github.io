import 'dart:ui_web' as ui_web;

/// Uses SDK history support without adding flutter_web_plugins to the deps.
void configure() {
  ui_web.urlStrategy = const _RootPathStrategy();
}

// The specified username Pages repository serves at '/', permanently.
// Override only URL representation; retain SDK popstate and history handling.
class _RootPathStrategy extends ui_web.HashUrlStrategy {
  const _RootPathStrategy();

  static const _location = ui_web.BrowserPlatformLocation();

  @override
  String getPath() => '${_location.pathname}${_location.search}';

  @override
  String prepareExternalUrl(String internalUrl) {
    if (internalUrl.isEmpty) return '/';
    if (!internalUrl.startsWith('/')) {
      throw ArgumentError.value(
        internalUrl,
        'internalUrl',
        'Expected a root-relative route.',
      );
    }
    return internalUrl;
  }
}

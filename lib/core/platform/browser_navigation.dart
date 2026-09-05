import 'package:nocturne/core/platform/browser_navigation_stub.dart'
    if (dart.library.js_interop) 'package:nocturne/core/platform/browser_navigation_web.dart'
    as browser;

/// Installs root-relative path URLs before Flutter initializes its router.
void configureBrowserNavigation() => browser.configure();

import 'package:nocturne/core/platform/static_route_stub.dart'
    if (dart.library.js_interop) 'package:nocturne/core/platform/static_route_web.dart'
    as browser;

/// Opens a path served outside the Flutter app.
///
/// `/cv` and `/brief` are hand-written HTML that GitHub Pages serves directly,
/// so the router must not try to resolve them — the browser has to leave the
/// app. Routing them client-side would render the reserved empty placeholder
/// instead of the real page.
void openStaticRoute(String path) => browser.open(path);

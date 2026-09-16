import 'package:nocturne/core/platform/render_scale_stub.dart'
    if (dart.library.js_interop) 'package:nocturne/core/platform/render_scale_web.dart'
    as impl;

/// Caps the browser's reported device pixel ratio for as long as the climb
/// is open, and hands the real one back when it closes.
///
/// The whole rationale is in `web/index.html`, next to the shim this calls:
/// Flutter Web shares one canvas for the entire app, sized from
/// `window.devicePixelRatio`, so nothing short of that value actually
/// changes how many physical pixels the game's masonry and dust get filled
/// into every frame. A per-widget resolution trick was tried first and
/// measured, under emulation, to change nothing.
abstract final class RenderScale {
  /// Below this, nothing is touched -- an ordinary phone or desktop screen
  /// keeps its native sharpness. Only a 3x-class display is actually capped.
  static const double gameCap = 1.75;

  /// Call once when the climb opens.
  static void capForGame() => impl.capDevicePixelRatio(gameCap);

  /// Call once when the climb closes, however it closes.
  static void restore() => impl.restoreDevicePixelRatio();
}

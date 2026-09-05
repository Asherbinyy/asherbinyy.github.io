import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/app.dart';
import 'package:nocturne/core/platform/platform_provider.dart';
import 'package:nocturne/core/platform/pointer_capabilities.dart';
import 'package:nocturne/core/platform/preference_store.dart';
import 'package:nocturne/app/theme/theme_controller.dart';

/// The four documented breakpoints, with a width inside each band.
enum ChromeBreakpoint {
  /// Below 600px.
  compact(360, 720),

  /// 600 to 1023px.
  medium(800, 900),

  /// 1024 to 1439px.
  expanded(1200, 900),

  /// 1440px and up.
  large(1600, 1000);

  const ChromeBreakpoint(this.width, this.height);

  /// Viewport width in logical pixels.
  final double width;

  /// Viewport height in logical pixels.
  final double height;

  /// Whether the rail is present at this width.
  bool get hasRail => index >= ChromeBreakpoint.expanded.index;
}

const PointerCapabilities pointerBrowser = PointerCapabilities(
  canHover: true,
  hasFinePointer: true,
);

const PointerCapabilities touchBrowser = PointerCapabilities(
  hasCoarsePointer: true,
);

/// Pumps the real app at [breakpoint] with an isolated preference store.
///
/// Sizes the test view rather than wrapping in a `MediaQuery`, because the
/// chrome resolves its layout through `PlatformService`, which reads the real
/// view metrics. [breakpoint] is required so no test silently depends on a
/// default width when the thing under test is width-dependent.
Future<ProviderContainer> pumpChrome(
  WidgetTester tester, {
  required ChromeBreakpoint breakpoint,
  PointerCapabilities capabilities = pointerBrowser,
  Map<String, String>? preferences,
  ThemeMode? themeMode,
  Locale? locale,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = Size(breakpoint.width, breakpoint.height);
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      preferenceStoreProvider.overrideWithValue(
        InMemoryPreferenceStore(preferences),
      ),
      platformCapabilitiesProvider.overrideWith(
        () => _FixedCapabilities(capabilities),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: NocturneApp(themeMode: themeMode, locale: locale),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

class _FixedCapabilities extends PlatformCapabilities {
  _FixedCapabilities(this._capabilities);

  final PointerCapabilities _capabilities;

  @override
  Stream<PointerCapabilities> build() => Stream.value(_capabilities);
}

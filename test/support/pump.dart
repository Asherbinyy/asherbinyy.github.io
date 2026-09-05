import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/theme/tokens.dart';

/// Advances enough frames for content, layout and one-shot animations.
///
/// `pumpAndSettle` cannot be used once the telemetry trace is mounted: it idles
/// at 0.2Hz for the life of the page, which `01-DESIGN-SYSTEM.md` section 5
/// explicitly permits, so the tree never reaches quiescence and the pump times
/// out. Bounded pumps get the same result without waiting for a stillness that
/// is not coming.
Future<void> pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(Tokens.acquisition);
  await tester.pump(Tokens.standard);
  await tester.pump(Tokens.standard);
}

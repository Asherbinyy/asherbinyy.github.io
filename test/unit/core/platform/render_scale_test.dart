import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/core/platform/render_scale.dart';

void main() {
  group('RenderScale', () {
    test('the cap is below full resolution and above a blur', () {
      // Below 3, so a 3x-class phone is actually reduced; above 1, so a game
      // played on an ordinary screen still looks like something.
      expect(RenderScale.gameCap, greaterThan(1.0));
      expect(RenderScale.gameCap, lessThan(3.0));
    });

    test('capping and restoring is safe to call from any test host', () {
      // The VM test runner takes the stub, which does nothing -- this proves
      // only that the call shape is safe, not the real browser behaviour,
      // which is not something flutter test can exercise. That was verified
      // separately, under emulation, in the worklog.
      expect(RenderScale.capForGame, returnsNormally);
      expect(RenderScale.restore, returnsNormally);
      expect(RenderScale.restore, returnsNormally);
    });
  });
}

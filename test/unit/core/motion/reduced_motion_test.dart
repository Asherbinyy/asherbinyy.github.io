import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';

void main() {
  test(
    'ordinary animations settle immediately when reduced motion is enabled',
    () {
      expect(
        ReducedMotion.resolve(disableAnimations: true, normal: Tokens.standard),
        Duration.zero,
      );
    },
  );

  test('ordinary animations retain their timing when motion is allowed', () {
    expect(
      ReducedMotion.resolve(
        disableAnimations: false,
        normal: Tokens.considered,
      ),
      Tokens.considered,
    );
  });

  testWidgets('media-query changes update motion policy and acquisition fade', (
    tester,
  ) async {
    bool? disabled;
    Duration? ordinary;
    Duration? acquisition;
    final probe = Builder(
      builder: (context) {
        disabled = ReducedMotion.of(context);
        ordinary = ReducedMotion.duration(context, Tokens.standard);
        acquisition = ReducedMotion.acquisition(context);
        return const SizedBox.shrink();
      },
    );

    await tester.pumpWidget(
      MediaQuery(data: const MediaQueryData(), child: probe),
    );
    expect(disabled, isFalse);
    expect(ordinary, Tokens.standard);
    expect(acquisition, Tokens.sequence);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: probe,
      ),
    );
    expect(disabled, isTrue);
    expect(ordinary, Duration.zero);
    expect(acquisition, Tokens.reducedAcquisition);
  });
}

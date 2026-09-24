import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/platform/platform_service.dart';
import 'package:nocturne/core/platform/pointer_capabilities.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_contract.dart';
import 'package:nocturne/features/courtyard/game/presentation/ascent_controls.dart';

import '../../support/loading_harness.dart';

/// The controls on a phone-sized touch screen, reporting into [inputs].
Future<void> _pump(WidgetTester tester, List<AscentInput> inputs) async {
  tester.view.physicalSize = const Size(390, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    LoadingHarness(
      child: PlatformScope(
        service: const PlatformService(
          capabilities: PointerCapabilities(hasCoarsePointer: true),
          viewportWidth: 390,
        ),
        child: SizedBox.expand(child: AscentControls(onChanged: inputs.add)),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'a touch anywhere on the right jumps, for as long as it is held',
    (tester) async {
      final inputs = <AscentInput>[];
      await _pump(tester, inputs);

      final thumb = await tester.startGesture(const Offset(330, 200));
      expect(inputs.last.isLeaping, isTrue);
      expect(inputs.last.steer, 0);
      await thumb.up();
      expect(inputs.last.isLeaping, isFalse);
    },
  );

  testWidgets('sliding a thumb on the left steers, from where it landed', (
    tester,
  ) async {
    final inputs = <AscentInput>[];
    await _pump(tester, inputs);

    final thumb = await tester.startGesture(const Offset(100, 400));
    expect(inputs.last.steer, 0, reason: 'landing is not steering');
    await thumb.moveBy(const Offset(-40, 0));
    expect(inputs.last.steer, -1);
    await thumb.moveBy(const Offset(80, 0));
    expect(inputs.last.steer, 1);
    await thumb.up();
    expect(inputs.last.steer, 0);
  });

  testWidgets('steering and jumping work at once, one thumb each', (
    tester,
  ) async {
    final inputs = <AscentInput>[];
    await _pump(tester, inputs);

    final left = await tester.startGesture(const Offset(100, 400), pointer: 1);
    await left.moveBy(const Offset(40, 0));
    final right = await tester.startGesture(const Offset(330, 400), pointer: 2);
    expect(inputs.last.steer, 1);
    expect(inputs.last.isLeaping, isTrue);
    await right.up();
    expect(inputs.last.steer, 1, reason: 'lifting the jump keeps steering');
    expect(inputs.last.isLeaping, isFalse);
    await left.up();
  });
}

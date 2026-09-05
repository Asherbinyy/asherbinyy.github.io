import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/widgets/loading/skeleton_panel.dart';
import 'package:nocturne/core/widgets/loading/sweep_scope.dart';
import 'package:nocturne/core/widgets/loading/sweep_shimmer.dart';

import '../../support/loading_harness.dart';

/// Reports the sweep animation visible at its position in the tree.
class _SweepProbe extends StatelessWidget {
  const _SweepProbe(this.report);

  final void Function(Animation<double>?) report;

  @override
  Widget build(BuildContext context) {
    report(SweepScope.maybeOf(context));
    return const SizedBox.shrink();
  }
}

void main() {
  testWidgets('every sweeping surface on a page shares one animation', (
    tester,
  ) async {
    final seen = <Animation<double>?>[];

    await tester.pumpWidget(
      LoadingHarness(
        child: SweepScope(
          child: Column(
            children: [
              _SweepProbe(seen.add),
              _SweepProbe(seen.add),
              _SweepProbe(seen.add),
            ],
          ),
        ),
      ),
    );

    expect(seen, hasLength(3));
    expect(seen.first, isNotNull);
    expect(seen.every((animation) => identical(animation, seen.first)), isTrue);
  });

  testWidgets(
    'a primitive outside a scope renders static rather than throwing',
    (tester) async {
      final seen = <Animation<double>?>[];

      await tester.pumpWidget(LoadingHarness(child: _SweepProbe(seen.add)));

      expect(seen, [isNull]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the band crosses in one pass and holds through the pause', (
    tester,
  ) async {
    Animation<double>? sweep;

    await tester.pumpWidget(
      LoadingHarness(
        child: SweepScope(child: _SweepProbe((value) => sweep = value)),
      ),
    );
    final animation = sweep;
    expect(animation, isNotNull);
    if (animation == null) return;

    expect(animation.value, 0);

    await tester.pump(Tokens.sweep ~/ 2);
    expect(animation.value, closeTo(0.5, 0.02));

    await tester.pump(Tokens.sweep ~/ 2);
    expect(animation.value, closeTo(1, 0.02));

    // The pause is dead time at the end of the pass, not a second traversal.
    await tester.pump(Tokens.sweepPause ~/ 2);
    expect(animation.value, closeTo(1, 0.02));

    // Removing the scope stops the repeating controller for the next test.
    await tester.pumpWidget(const LoadingHarness(child: SizedBox.shrink()));
  });

  testWidgets('reduced motion settles the sweep entirely', (tester) async {
    Animation<double>? sweep;

    await tester.pumpWidget(
      LoadingHarness(
        reducedMotion: true,
        child: SweepScope(child: _SweepProbe((value) => sweep = value)),
      ),
    );

    expect(sweep, isNull);
    // A repeating controller would never settle, so reaching the next line is
    // itself the proof that nothing is still animating.
    await tester.pumpAndSettle();
  });

  testWidgets('the shimmer overlays a band only while the sweep runs', (
    tester,
  ) async {
    await tester.pumpWidget(
      const LoadingHarness(
        child: SweepScope(
          child: SweepShimmer(child: SizedBox(width: 200, height: 40)),
        ),
      ),
    );
    expect(find.byType(ShaderMask), findsOneWidget);

    await tester.pumpWidget(
      const LoadingHarness(
        reducedMotion: true,
        child: SweepScope(
          child: SweepShimmer(child: SizedBox(width: 200, height: 40)),
        ),
      ),
    );
    expect(find.byType(ShaderMask), findsNothing);
    expect(find.byType(SizedBox), findsWidgets);
  });

  testWidgets('a skeleton keeps the exact geometry of what replaces it', (
    tester,
  ) async {
    await tester.pumpWidget(
      const LoadingHarness(
        child: SweepScope(child: SkeletonPanel(width: 320, height: 200)),
      ),
    );

    expect(tester.getSize(find.byType(SkeletonPanel)), const Size(320, 200));

    await tester.pumpWidget(const LoadingHarness(child: SizedBox.shrink()));
  });

  testWidgets('skeletons are hidden from screen readers', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const LoadingHarness(
        child: SweepScope(child: SkeletonPanel(width: 320, height: 200)),
      ),
    );

    expect(find.byType(ExcludeSemantics), findsWidgets);
    await tester.pumpWidget(const LoadingHarness(child: SizedBox.shrink()));
    semantics.dispose();
  });
}

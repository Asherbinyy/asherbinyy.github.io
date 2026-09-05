import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/widgets/loading/carrier_empty_state.dart';
import 'package:nocturne/core/widgets/loading/carrier_loader.dart';
import 'package:nocturne/core/widgets/loading/skeleton_panel.dart';
import 'package:nocturne/core/widgets/loading/skeleton_text.dart';
import 'package:nocturne/core/widgets/loading/station_card.dart';
import 'package:nocturne/core/widgets/loading/sweep_scope.dart';

import '../support/loading_harness.dart';

// Alchemist 0.11 cannot implement Flutter 3.47's Canvas API, so these use the
// SDK comparator like the existing placeholder goldens. See worklog 05.

/// One page's worth of loading surfaces under a single shared sweep.
class _LoadingSurfaces extends StatelessWidget {
  const _LoadingSurfaces();

  static const int _lines = 3;

  @override
  Widget build(BuildContext context) {
    final style = context.type.body;
    // The panel is sized from the same metrics the real content will use.
    // Arabic raises line height by 0.15, so a hard-coded height would clip in
    // one direction and leave a gap in the other — which is the layout shift
    // the skeleton exists to prevent.
    final lineHeight =
        (style.fontSize ?? Tokens.bodySize) *
        (style.height ?? Tokens.bodyHeight);
    final panelHeight =
        lineHeight * _lines + Tokens.space16 * 2 + Tokens.cornerTickOffset * 2;

    return SweepScope(
      child: ColoredBox(
        color: context.tokens.void_,
        child: Padding(
          padding: const EdgeInsets.all(Tokens.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonPanel(
                width: 320,
                height: panelHeight,
                padding: const EdgeInsets.all(Tokens.space16),
                child: SkeletonText(lines: _lines, style: style),
              ),
              const SizedBox(height: Tokens.space24),
              const CarrierLoader(),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    for (final language in ['en', 'ar']) {
      final suffix = '${mode.name}_$language';

      testWidgets('loading surfaces in $suffix', (tester) async {
        await tester.pumpWidget(
          LoadingHarness(
            themeMode: mode,
            language: language,
            child: const _LoadingSurfaces(),
          ),
        );
        // Half a pass puts the band mid-travel, which is the frame worth
        // comparing; the test clock makes it exactly reproducible.
        await tester.pump(Tokens.sweep ~/ 2);

        await expectLater(
          find.byType(_LoadingSurfaces),
          matchesGoldenFile('goldens/loading_$suffix.png'),
        );

        await tester.pumpWidget(const LoadingHarness(child: SizedBox.shrink()));
      });

      testWidgets('empty state in $suffix', (tester) async {
        await tester.pumpWidget(
          LoadingHarness(
            themeMode: mode,
            language: language,
            child: const SizedBox(
              width: 320,
              child: CarrierEmptyState(direction: 'Fixture direction line'),
            ),
          ),
        );

        await expectLater(
          find.byType(CarrierEmptyState),
          matchesGoldenFile('goldens/empty_state_$suffix.png'),
        );
      });

      testWidgets('station card in $suffix', (tester) async {
        await tester.pumpWidget(
          LoadingHarness(
            themeMode: mode,
            language: language,
            child: const StationCard(
              seedId: 'az-courses',
              name: 'AZ Courses',
              width: 320,
              height: 200,
              domainLabel: 'Education',
              country: 'EG',
              latitude: 31.0409,
              longitude: 31.3785,
            ),
          ),
        );

        await expectLater(
          find.byType(StationCard),
          matchesGoldenFile('goldens/station_card_$suffix.png'),
        );
      });
    }
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/core/widgets/name_cartouche.dart';

import '../support/loading_harness.dart';

void main() {
  group('the cartouche', () {
    for (final theme in [ThemeMode.dark, ThemeMode.light]) {
      testWidgets('renders in ${theme.name}', (tester) async {
        await tester.pumpWidget(
          LoadingHarness(
            themeMode: theme,
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: NameCartouche(name: 'Sherbini', height: 56),
            ),
          ),
        );

        await expectLater(
          find.byType(NameCartouche),
          matchesGoldenFile('goldens/cartouche_${theme.name}.png'),
        );
      });
    }
  });
}

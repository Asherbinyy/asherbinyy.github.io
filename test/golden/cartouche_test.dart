@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/core/widgets/name_cartouche.dart';

import '../support/loading_harness.dart';

// Tagged so this runs only on the goldens runner. `dart_test.yaml` records
// why: Skia's antialiasing differs between macOS and Linux by up to 3.29% of
// pixels on an identical tree, and a tolerance wide enough to absorb that
// would also hide a real change. Missing the tag is what made `verify` fail
// on CI while passing locally.
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

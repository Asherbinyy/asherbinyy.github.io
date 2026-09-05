import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/app.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/core/widgets/placeholder_screen.dart';

// Alchemist 0.11 cannot implement Flutter 3.47's Canvas API. Keep the same
// screenshot coverage with the SDK comparator until the package is compatible.
void main() {
  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    for (final language in ['en', 'ar']) {
      testWidgets('empty ${mode.name} placeholder in $language', (
        tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(
            child: NocturneApp(themeMode: mode, locale: Locale(language)),
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(PlaceholderScreen));
        expect(context.l10n.localeName, language);
        expect(
          Directionality.of(context),
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        await expectLater(
          find.byType(PlaceholderScreen),
          matchesGoldenFile('goldens/placeholder_${mode.name}_$language.png'),
        );
      });
    }
  }
}

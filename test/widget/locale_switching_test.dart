import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nocturne/app/app.dart';
import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/locale_controller.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/core/widgets/placeholder_screen.dart';

void main() {
  testWidgets('switching languages updates delegates and preserves the route', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: NocturneApp()));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(PlaceholderScreen));
    final router = GoRouter.of(context)..go('/work/fixture');
    final controller = ProviderScope.containerOf(context)
        .read(localeControllerProvider.notifier);
    await tester.pumpAndSettle();

    for (final locale in [AppLocale.arabic, AppLocale.english]) {
      controller.locale = locale;
      await tester.pumpAndSettle();
      final active = tester.element(find.byType(PlaceholderScreen));

      expect(active.l10n.localeName, locale.languageCode);
      expect(Localizations.localeOf(active).languageCode, locale.languageCode);
      expect(
        Directionality.of(active),
        locale == AppLocale.arabic ? TextDirection.rtl : TextDirection.ltr,
      );
      expect(GoRouter.of(active), same(router));
      expect(router.routeInformationProvider.value.uri.path, '/work/fixture');
      // The chrome's own copy must follow the channel, not just the direction.
      // The footer is present at every width, unlike the route links.
      expect(find.text(active.l10n.footerLocation), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

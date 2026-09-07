import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nocturne/app/app.dart';
import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/locale_controller.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';

import '../support/pump.dart';

void main() {
  testWidgets('switching languages updates delegates and preserves the route', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: NocturneApp()));
    await pumpFrames(tester);
    final context = tester.element(find.byType(ChromeScaffold));
    final router = GoRouter.of(context)..go('/work/fixture');
    final controller = ProviderScope.containerOf(context)
        .read(localeControllerProvider.notifier);
    await pumpFrames(tester);

    for (final locale in [AppLocale.arabic, AppLocale.english]) {
      controller.locale = locale;
      await pumpFrames(tester);
      final active = tester.element(find.byType(ChromeScaffold));

      expect(active.l10n.localeName, locale.languageCode);
      expect(Localizations.localeOf(active).languageCode, locale.languageCode);
      expect(
        Directionality.of(active),
        locale == AppLocale.arabic ? TextDirection.rtl : TextDirection.ltr,
      );
      expect(GoRouter.of(active), same(router));
      expect(router.routeInformationProvider.value.uri.path, '/work/fixture');
      // The chrome's own copy must follow the channel, not just the direction.
      // The mark's accessible name is the check: it is present at every width,
      // unlike the route links, and it survived the footer being emptied in
      // milestone 4 -- the footer's city used to carry this assertion, which
      // made a test of localisation depend on a piece of copy that turned out
      // to be removable.
      expect(find.bySemanticsLabel(active.l10n.markLink), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

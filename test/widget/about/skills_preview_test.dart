import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';

import '../../support/chrome_harness.dart';
import '../../support/content_readers.dart';
import '../../support/pump.dart';
import '../../support/station_harness.dart';

void main() {
  testWidgets(
    'an open skills group shows its first rows, the rest on request',
    (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.about,
        reducedMotion: true,
      );
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;
      // From the content, not a pinned list: the owner will keep adding skills.
      final skills =
          (bundledJson('assets/content/profile.json')['skills']
                  as List<dynamic>)
              .cast<String>();
      expect(skills.length, greaterThan(Tokens.skillsPreviewCount));

      final firstHidden = skills[Tokens.skillsPreviewCount];
      final lastShown = skills[Tokens.skillsPreviewCount - 1];
      expect(find.text(lastShown), findsOneWidget);
      expect(find.text(firstHidden), findsNothing);

      final more = find.text(
        l10n.profileSkillsMore(skills.length - Tokens.skillsPreviewCount),
      );
      await tester.ensureVisible(more);
      await tester.tap(more);
      await pumpFrames(tester);

      expect(find.text(firstHidden), findsOneWidget);
      expect(find.text(skills.last), findsOneWidget);
      expect(find.text(l10n.profileSkillsLess), findsOneWidget);
    },
  );
}

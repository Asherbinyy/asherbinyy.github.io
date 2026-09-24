import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/core/widgets/skill_groups.dart';

import '../../support/chrome_harness.dart';
import '../../support/content_readers.dart';
import '../../support/pump.dart';
import '../../support/station_harness.dart';

/// The owner's groups, straight from the content, so adding one to the
/// profile does not leave these tests asserting a stale list.
List<({String title, List<String> skills})> _groups() => [
  for (final group
      in bundledJson('assets/content/profile.json')['skillGroups']
          as List<dynamic>)
    (
      title:
          ((group as Map<String, dynamic>)['title']
                  as Map<String, dynamic>)['en']
              as String,
      skills: (group['skills'] as List<dynamic>).cast<String>(),
    ),
];

Finder _within(Finder finder) =>
    find.descendant(of: find.byType(SkillGroups), matching: finder);

void main() {
  for (final route in [AppRoute.home, AppRoute.about]) {
    testWidgets('skills sit under titles, the first one open (${route.name})', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: route,
        reducedMotion: true,
      );
      final groups = _groups();
      expect(groups, isNotEmpty);

      // Every title is on the panel.
      for (final group in groups) {
        expect(_within(find.text(group.title)), findsOneWidget);
      }
      // The first group is open: its skills are showing, the next one's not.
      for (final skill in groups.first.skills) {
        expect(_within(find.text(skill)), findsOneWidget, reason: skill);
      }
      expect(_within(find.text(groups[1].skills.first)), findsNothing);
    });
  }

  testWidgets('pressing a title opens its skills in place of the last', (
    tester,
  ) async {
    await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.large,
      reducedMotion: true,
    );
    final groups = _groups();
    final second = groups[1];

    final title = _within(find.text(second.title));
    await tester.ensureVisible(title);
    await tester.tap(title);
    await pumpFrames(tester);

    for (final skill in second.skills) {
      expect(_within(find.text(skill)), findsOneWidget, reason: skill);
    }
    expect(_within(find.text(groups.first.skills.first)), findsNothing);
  });

  testWidgets('nothing he is learning is labelled as learning', (tester) async {
    await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.large,
      initialRoute: AppRoute.about,
      reducedMotion: true,
    );

    // The owner asked for those topics to sit with the rest, plainly.
    expect(find.textContaining('learning', findRichText: true), findsNothing);
    expect(
      bundledJson('assets/content/profile.json')['learning'] as List<dynamic>,
      isEmpty,
    );
  });
}

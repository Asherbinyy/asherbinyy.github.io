import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';
import 'package:nocturne/features/work/presentation/widgets/device_frame.dart';
import 'package:nocturne/features/work/presentation/widgets/embed_view.dart';
import 'package:nocturne/features/work/presentation/widgets/prototype_embed.dart';

import '../../support/chrome_harness.dart';
import '../../support/content_readers.dart';
import '../../support/pump.dart';
import '../../support/station_harness.dart';

/// Stands in for a study the owner has not written.
///
/// `assets/content/studies/` is deliberately empty — 09-ROADMAP.md says an
/// agent cannot write these — so the machinery is proven against a fixture
/// rather than against invented prose shipped to the live site.
Map<String, Object?> studyFixture({
  int screens = 3,
  Map<String, Object?>? prototype,
}) => {
  'id': 'fixture-study',
  'title': {'en': 'Fixture Study'},
  'context': {'en': 'The context paragraph.'},
  'problem': {'en': 'The problem paragraph.'},
  'approach': {'en': 'The approach paragraph.'},
  'outcome': {'en': 'The outcome paragraph.'},
  'stack': ['Flutter', 'Dart'],
  'screens': [
    for (var i = 0; i < screens; i++)
      {
        'src': 'assets/screens/fixture/0$i.webp',
        'caption': {'en': 'Screen $i'},
      },
  ],
  if (prototype != null) 'prototype': prototype,
};

Future<void> pumpStudy(
  WidgetTester tester, {
  Map<String, Object?>? study,
  ChromeBreakpoint breakpoint = ChromeBreakpoint.large,
}) => pumpStation(
  tester,
  breakpoint: breakpoint,
  initialRoute: AppRoute.caseStudy,
  pathParameters: const {'slug': 'fixture'},
  reader: bundledContent(
    overrides: {
      if (study != null) 'assets/content/studies/fixture.json': asAsset(study),
    },
  ),
);

void main() {
  group('a written case study', () {
    testWidgets('renders the four sections in the order the spec fixes', (
      tester,
    ) async {
      await pumpStudy(tester, study: studyFixture());
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      final order = [
        tester.getTopLeft(find.text(l10n.caseStudyContext)).dy,
        tester.getTopLeft(find.text(l10n.caseStudyProblem)).dy,
        tester.getTopLeft(find.text(l10n.caseStudyApproach)).dy,
        tester.getTopLeft(find.text(l10n.caseStudyOutcome)).dy,
      ];

      expect(order, orderedEquals([...order]..sort()));
    });

    testWidgets('pins a device frame beside the narrative when wide', (
      tester,
    ) async {
      await pumpStudy(tester, study: studyFixture());

      expect(find.byType(DeviceFrame), findsOneWidget);
      final frame = tester.getTopLeft(find.byType(DeviceFrame));
      final context = tester.getTopLeft(
        find.text(
          tester.element(find.byType(ChromeScaffold)).l10n.caseStudyContext,
        ),
      );
      expect(frame.dx, greaterThan(context.dx));
    });

    testWidgets('stacks the frame above the narrative when narrow', (
      tester,
    ) async {
      await pumpStudy(
        tester,
        study: studyFixture(),
        breakpoint: ChromeBreakpoint.compact,
      );

      final frame = tester.getTopLeft(find.byType(DeviceFrame));
      final context = tester.getTopLeft(
        find.text(
          tester.element(find.byType(ChromeScaffold)).l10n.caseStudyContext,
        ),
      );
      expect(frame.dy, lessThan(context.dy));
    });
  });

  group('scrubbing', () {
    test('maps scroll progress across the screens', () {
      expect(DeviceFrame.indexFor(0, 3), 0);
      expect(DeviceFrame.indexFor(0.5, 3), 1);
      expect(DeviceFrame.indexFor(0.9, 3), 2);
    });

    test('holds the last screen at the foot of the page', () {
      // Progress reaches 1.0 exactly, which floor() would push out of range.
      expect(DeviceFrame.indexFor(1, 3), 2);
      expect(DeviceFrame.indexFor(1.5, 3), 2);
    });

    test('stays on the only screen when a study has one', () {
      expect(DeviceFrame.indexFor(0.99, 1), 0);
    });
  });

  group('the embedded prototype', () {
    testWidgets('costs nothing until the viewer asks for it', (tester) async {
      await pumpStudy(
        tester,
        study: studyFixture(
          prototype: {
            'url': 'https://prototype.example/tour',
            'status': {'en': 'Early-stage prototype. No company formed.'},
          },
        ),
      );

      // The poster is present; the frame that would fetch a third-party page
      // is not built until pressed.
      expect(find.byType(PrototypeEmbed), findsOneWidget);
      expect(find.byType(EmbedView), findsNothing);
    });

    testWidgets('states its status honestly above the frame', (tester) async {
      await pumpStudy(
        tester,
        study: studyFixture(
          prototype: {
            'url': 'https://prototype.example/tour',
            'status': {'en': 'Early-stage prototype. No company formed.'},
          },
        ),
      );

      expect(
        find.text('Early-stage prototype. No company formed.'),
        findsOneWidget,
      );
    });

    testWidgets('loads the frame only after an explicit press', (tester) async {
      await pumpStudy(
        tester,
        study: studyFixture(
          prototype: {
            'url': 'https://prototype.example/tour',
            'status': {'en': 'Early-stage prototype. No company formed.'},
          },
        ),
      );
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      await tester.ensureVisible(find.text(l10n.caseStudyLoadPrototype));
      await pumpFrames(tester);
      await tester.tap(find.text(l10n.caseStudyLoadPrototype));
      await pumpFrames(tester);

      expect(find.byType(EmbedView), findsOneWidget);
    });

    testWidgets('is absent for a study that declares none', (tester) async {
      await pumpStudy(tester, study: studyFixture());

      expect(find.byType(PrototypeEmbed), findsNothing);
    });
  });

  group('a study that does not exist', () {
    testWidgets('says so rather than inventing prose', (tester) async {
      // This is production's actual state: no study files are shipped.
      await pumpStudy(tester);
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      expect(find.text(l10n.caseStudyUnavailable), findsOneWidget);
      expect(find.byType(DeviceFrame), findsNothing);
    });

    testWidgets('offers a way back to the ledger', (tester) async {
      await pumpStudy(tester);
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      expect(
        find.descendant(
          of: find.byType(BeaconButton),
          matching: find.text(l10n.caseStudyBackToWork),
        ),
        findsOneWidget,
      );
    });
  });
}

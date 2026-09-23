import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/core/net/relay.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/platform/platform_service.dart';
import 'package:nocturne/core/platform/pointer_capabilities.dart';
import 'package:nocturne/features/courtyard/game/data/leaderboard_client.dart';
import 'package:nocturne/features/courtyard/game/domain/leaderboard.dart';
import 'package:nocturne/features/courtyard/game/presentation/leaderboard_controller.dart';
import 'package:nocturne/features/courtyard/game/presentation/widgets/join_prompt.dart';
import 'package:nocturne/features/courtyard/game/presentation/widgets/leaderboard_panel.dart';

import '../../support/loading_harness.dart';

class _Server extends http.BaseClient {
  _Server(this.reply);

  final (int, String) Function() reply;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final (status, body) = reply();
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      status,
      request: request,
    );
  }
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required (int, String) Function() reply,
  bool refreshFirst = true,
  String language = 'en',
  Widget panel = const LeaderboardPanel(),
}) async {
  final container = ProviderContainer(
    overrides: [
      relayEndpointProvider.overrideWithValue(
        Uri.parse('https://worker.example'),
      ),
      leaderboardClientProvider.overrideWithValue(
        LeaderboardClient(
          client: _Server(reply),
          origin: Uri.parse('https://worker.example'),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: LoadingHarness(
        language: language,
        child: _Machine(child: panel),
      ),
    ),
  );
  if (refreshFirst) {
    await container.read(leaderboardControllerProvider.notifier).refresh();
    await tester.pump();
  }
}

/// A pointer machine, which is what `GameControl` asks the platform about.
class _Machine extends StatelessWidget {
  const _Machine({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => PlatformScope(
    service: const PlatformService(
      capabilities: PointerCapabilities(canHover: true, hasFinePointer: true),
      viewportWidth: 800,
    ),
    child: child,
  );
}

void main() {
  group('the board panel says which of four things is true', () {
    testWidgets('a board with entries prints them in order', (tester) async {
      await _pumpPanel(
        tester,
        reply: () => (
          200,
          jsonEncode({
            'entries': [
              {'rank': 1, 'nickname': 'Ahmed', 'metres': 362},
              {'rank': 2, 'nickname': 'Nour', 'metres': 140},
            ],
          }),
        ),
      );

      expect(find.text('Ahmed'), findsOneWidget);
      expect(find.text('362 m'), findsOneWidget);
      expect(find.text('Nour'), findsOneWidget);
      expect(find.text('Top climbers'), findsOneWidget);
      // The claim that makes the numbers mean anything.
      expect(
        find.text('Every height here was replayed on the server.'),
        findsOneWidget,
      );
    });

    testWidgets('the first three places are marked, the rest are numbered', (
      tester,
    ) async {
      // The owner asked for an emoji on the top three. It is also the thing
      // that makes the rail legible at a glance during a climb -- and the
      // reason it stops at three is that a column of identical medals marks
      // nothing at all.
      await _pumpPanel(
        tester,
        reply: () => (
          200,
          jsonEncode({
            'entries': [
              {'rank': 1, 'nickname': 'Ahmed', 'metres': 507},
              {'rank': 2, 'nickname': 'Nour', 'metres': 362},
              {'rank': 3, 'nickname': 'Salma', 'metres': 140},
              {'rank': 4, 'nickname': 'Omar', 'metres': 98},
            ],
          }),
        ),
      );

      expect(find.text('\u{1F947}'), findsOneWidget);
      expect(find.text('\u{1F948}'), findsOneWidget);
      expect(find.text('\u{1F949}'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      // The medal is decoration; the rank is what is announced.
      expect(
        find.bySemanticsLabel('1. Ahmed, 507 m'),
        findsOneWidget,
        reason: 'a screen reader was read an emoji instead of a place',
      );
    });

    testWidgets('it stops at five, however many the server sends', (
      tester,
    ) async {
      await _pumpPanel(
        tester,
        reply: () => (
          200,
          jsonEncode({
            'entries': [
              for (var rank = 1; rank <= 9; rank++)
                {
                  'rank': rank,
                  'nickname': 'Climber $rank',
                  'metres': 500 - rank,
                },
            ],
          }),
        ),
      );

      expect(find.text('Climber 5'), findsOneWidget);
      expect(find.text('Climber 6'), findsNothing);
    });

    testWidgets('the rail beside the climb drops everything but the names', (
      tester,
    ) async {
      // The quiet variant sits over the playfield, so it loses the border, the
      // footnote and -- when the board cannot be reached -- itself. What it
      // must not lose is the title, because a column of names with no heading
      // over a game is not obviously a leaderboard at all.
      await _pumpPanel(
        tester,
        panel: const LeaderboardPanel(isQuiet: true),
        reply: () => (
          200,
          jsonEncode({
            'entries': [
              {'rank': 1, 'nickname': 'Ahmed', 'metres': 507},
            ],
          }),
        ),
      );

      expect(find.text('Top climbers'), findsOneWidget);
      expect(find.text('Ahmed'), findsOneWidget);
      expect(
        find.text('Every height here was replayed on the server.'),
        findsNothing,
      );
    });

    testWidgets('the rail says nothing at all when the board is away', (
      tester,
    ) async {
      // A retry button floating over a game somebody is playing is an errand.
      // The results screen behind it offers the same button at the moment it
      // is worth pressing.
      await _pumpPanel(
        tester,
        panel: const LeaderboardPanel(isQuiet: true),
        reply: () => (503, ''),
      );

      expect(find.text('The board is not answering.'), findsNothing);
      expect(find.text('Try again'), findsNothing);
      expect(find.text('Top climbers'), findsNothing);
    });

    testWidgets('an empty board is not confused with a broken one', (
      tester,
    ) async {
      await _pumpPanel(tester, reply: () => (200, '{"entries":[]}'));
      expect(find.text('Nobody has climbed yet.'), findsOneWidget);
      expect(find.text('The board is not answering.'), findsNothing);
    });

    testWidgets('a board that cannot be reached says so, with a way back', (
      tester,
    ) async {
      await _pumpPanel(tester, reply: () => (500, 'gateway'));
      expect(find.text('The board is not answering.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(
        find.text('Nobody has climbed yet.'),
        findsNothing,
        reason: 'a dropped connection told the visitor nobody had ever played',
      );
    });

    testWidgets('a row reads as one thing to a screen reader', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpPanel(
        tester,
        reply: () => (
          200,
          jsonEncode({
            'entries': [
              {'rank': 3, 'nickname': 'Nour', 'metres': 140},
            ],
          }),
        ),
      );
      expect(find.bySemanticsLabel('3. Nour, 140 m'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('it renders in Arabic and right to left', (tester) async {
      await _pumpPanel(
        tester,
        language: 'ar',
        reply: () => (200, '{"entries":[]}'),
      );
      expect(find.text('أفضل المتسلّقين'), findsOneWidget);
      expect(find.text('لم يتسلّق أحد بعد.'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(LeaderboardPanel))),
        TextDirection.rtl,
      );
    });

    testWidgets('with no leaderboard configured it draws nothing at all', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [leaderboardClientProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const LoadingHarness(
            child: _Machine(child: LeaderboardPanel()),
          ),
        ),
      );
      expect(find.text('Top climbers'), findsNothing);
    });
  });

  group('the join prompt', () {
    testWidgets('asks for a name and nothing else', (tester) async {
      // The owner's instruction, in as many words: "just ask the name to join
      // the leaderboard, that's it, no more and no hints". This is the guard
      // on that -- the next person to feel the sheet is under-explained will
      // reach for a paragraph, and the paragraph is what was wrong with it.
      Participation? chosen;
      await tester.pumpWidget(
        ProviderScope(
          child: LoadingHarness(
            child: _Machine(
              child: JoinPrompt(onChosen: (value) => chosen = value),
            ),
          ),
        ),
      );

      // What it still says is enough to know where the name goes: the sheet is
      // titled with the board, the field is labelled for it, and so is the
      // button. Disclosure by naming rather than by explaining.
      expect(find.text('Top climbers'), findsOneWidget);
      expect(find.text('Name on the board'), findsOneWidget);
      expect(find.text('Join the board'), findsOneWidget);

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(
        find.textContaining('No account'),
        findsNothing,
        reason: 'the explanatory paragraph is back',
      );
      expect(
        find.text('A place belongs to a browser, not a person.'),
        findsNothing,
      );
      expect(chosen, isNull, reason: 'showing the prompt decided something');
    });

    testWidgets('refuses a name the server would refuse anyway', (
      tester,
    ) async {
      Participation? chosen;
      await tester.pumpWidget(
        ProviderScope(
          child: LoadingHarness(
            child: _Machine(
              child: JoinPrompt(onChosen: (value) => chosen = value),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Join the board'));
      await tester.pump();
      expect(
        find.text('Two to sixteen characters, and no links.'),
        findsOneWidget,
      );
      expect(chosen, isNull);

      await tester.enterText(find.byType(TextField), 'see www.example.com');
      await tester.pump();
      await tester.tap(find.text('Join the board'));
      await tester.pump();
      expect(chosen, isNull, reason: 'a link went onto a public board');

      await tester.enterText(find.byType(TextField), '  Ahmed  ');
      await tester.pump();
      await tester.tap(find.text('Join the board'));
      await tester.pump();
      expect(chosen, isA<Joined>());
      expect((chosen! as Joined).nickname, 'Ahmed');
    });

    testWidgets('playing on is a button, not a dismissal in grey', (
      tester,
    ) async {
      Participation? chosen;
      await tester.pumpWidget(
        ProviderScope(
          child: LoadingHarness(
            child: _Machine(
              child: JoinPrompt(onChosen: (value) => chosen = value),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Just play'));
      await tester.pump();
      expect(chosen, isA<PlayingLocally>());
    });

    testWidgets('remembers either answer, so it is only asked once', (
      tester,
    ) async {
      // The tick box that used to ask went with the rest of the sheet, which
      // makes this the assertion that matters: both answers have to stick.
      // If a decline stopped being stored, the prompt would come back after
      // every single climb, which is the toll gate the design rules out.
      Participation? chosen;
      await tester.pumpWidget(
        ProviderScope(
          child: LoadingHarness(
            child: _Machine(
              child: JoinPrompt(onChosen: (value) => chosen = value),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Ahmed');
      await tester.pump();
      await tester.tap(find.text('Join the board'));
      await tester.pump();

      expect((chosen! as Joined).remembered, isTrue);
      expect(chosen!.persisted(), isNotNull);

      await tester.tap(find.text('Just play'));
      await tester.pump();
      expect(chosen, isA<PlayingLocally>());
      expect(
        chosen!.persisted(),
        isNotNull,
        reason: 'a visitor who declined would be asked again every climb',
      );
    });
  });
}

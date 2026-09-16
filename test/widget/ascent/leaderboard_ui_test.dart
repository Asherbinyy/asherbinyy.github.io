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
        child: const _Machine(child: LeaderboardPanel()),
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
    testWidgets('says what becomes public before anything is chosen', (
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

      expect(find.text('Climb for the record?'), findsOneWidget);
      expect(
        find.textContaining('public board'),
        findsOneWidget,
        reason: 'joining must state what is published before it happens',
      );
      expect(
        find.text('A place belongs to a browser, not a person.'),
        findsOneWidget,
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

    testWidgets('a choice not to be remembered stores nothing', (tester) async {
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

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Ahmed');
      await tester.pump();
      await tester.tap(find.text('Join the board'));
      await tester.pump();

      expect((chosen! as Joined).remembered, isFalse);
      expect(
        chosen!.persisted(),
        isNull,
        reason: 'a visitor who declined to be remembered was remembered',
      );
    });
  });
}

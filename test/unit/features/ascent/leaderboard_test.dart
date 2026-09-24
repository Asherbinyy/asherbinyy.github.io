import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:nocturne/core/platform/preference_store.dart';
import 'package:nocturne/features/courtyard/game/data/leaderboard_client.dart';
import 'package:nocturne/features/courtyard/game/domain/leaderboard.dart';
import 'package:nocturne/features/courtyard/game/presentation/leaderboard_controller.dart';

/// A Worker that answers whatever the test tells it to.
class _Server extends http.BaseClient {
  _Server(this.reply);

  /// Called with the method and path; returns a status and a body.
  final (int, String) Function(String method, String path) reply;

  final List<String> seen = [];
  final List<String> bodies = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    seen.add('${request.method} ${request.url.path}');
    if (request is http.Request) bodies.add(request.body);
    final (status, body) = reply(request.method, request.url.path);
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      status,
      request: request,
    );
  }
}

LeaderboardClient _clientFor(_Server server) => LeaderboardClient(
  client: server,
  origin: Uri.parse('https://worker.example'),
);

void main() {
  group('reading what the Worker sends', () {
    test('a board with entries', () {
      final board = Board.fromJson({
        'entries': [
          {'rank': 1, 'nickname': 'Ahmed', 'metres': 362},
          {'rank': 2, 'nickname': 'Nour', 'metres': 140},
        ],
        'updatedAt': 1758000000000,
      });
      expect(board!.entries, hasLength(2));
      expect(board.entries.first.nickname, 'Ahmed');
      expect(board.isEmpty, isFalse);
    });

    test('an empty board is an answer, not a failure', () {
      final board = Board.fromJson({'entries': <Object>[]});
      expect(board, isNotNull);
      expect(board!.isEmpty, isTrue);
    });

    test('anything malformed is refused rather than half-read', () {
      expect(Board.fromJson(null), isNull);
      expect(Board.fromJson('entries'), isNull);
      expect(Board.fromJson({'entries': 'nope'}), isNull);
      expect(
        Board.fromJson({
          'entries': [
            {'rank': 1, 'nickname': 'Ahmed'},
          ],
        }),
        isNull,
        reason: 'a row missing its height should not become a row',
      );
      expect(RunChallenge.fromJson({'runId': 'x'}), isNull);
      expect(Verdict.fromJson({'status': 'invented'}), isNull);
    });

    test('a verdict of each kind', () {
      expect(
        Verdict.fromJson({'status': 'pending', 'ticksChecked': 512}),
        isA<VerdictPending>().having((v) => v.ticksChecked, 'ticks', 512),
      );
      final checked =
          Verdict.fromJson({
                'status': 'checked',
                'metres': 300,
                'rank': 3,
                'outcome': 'accepted',
              })!
              as VerdictChecked;
      expect(checked.isRanked, isTrue);
      final missed =
          Verdict.fromJson({
                'status': 'checked',
                'metres': 4,
                'rank': null,
                'outcome': 'not-qualified',
              })!
              as VerdictChecked;
      expect(missed.isRanked, isFalse);
      expect(
        Verdict.fromJson({'status': 'rejected', 'reason': 'incomplete-run'}),
        isA<VerdictRejected>(),
      );
    });
  });

  group('the client never insists the server answer', () {
    test('a 503 leaderboard reads as absent, not as an error', () async {
      final server = _Server((_, _) => (503, '{"error":"not configured"}'));
      expect(await _clientFor(server).board(), isNull);
    });

    test('a body that is not JSON reads as absent', () async {
      final server = _Server((_, _) => (200, '<html>gateway</html>'));
      expect(await _clientFor(server).board(), isNull);
    });

    test('a thrown transport reads as absent', () async {
      final client = LeaderboardClient(
        client: _Throwing(),
        origin: Uri.parse('https://worker.example'),
      );
      expect(await client.board(), isNull);
      expect(await client.beginRun('0' * 32), isNull);
      expect(await client.forget('0' * 32), isFalse);
    });
  });

  group('the participant', () {
    test('a fresh key is 128 bits of hex and not derived from the device', () {
      final joined = Joined.fresh(
        nickname: 'Ahmed',
        submitsAutomatically: true,
        remembered: true,
        random: math.Random(1),
      );
      expect(joined.playerKey, matches(RegExp(r'^[0-9a-f]{32}$')));
      final other = Joined.fresh(
        nickname: 'Ahmed',
        submitsAutomatically: true,
        remembered: true,
        random: math.Random(2),
      );
      expect(other.playerKey, isNot(joined.playerKey));
    });

    test('a choice not to be remembered leaves nothing to restore', () {
      expect(const PlayingLocally(remembered: false).persisted(), isNull);
      expect(
        Joined.fresh(
          nickname: 'Ahmed',
          submitsAutomatically: false,
          remembered: false,
        ).persisted(),
        isNull,
      );
      expect(const Undecided().persisted(), isNull);
    });

    test('a remembered choice survives a reload intact', () {
      final joined = Joined.fresh(
        nickname: 'Ahmed',
        submitsAutomatically: true,
        remembered: true,
        random: math.Random(3),
      );
      final restored = Participation.restore(joined.persisted()) as Joined;
      expect(restored.playerKey, joined.playerKey);
      expect(restored.nickname, 'Ahmed');
      expect(restored.submitsAutomatically, isTrue);
    });

    test('a stored value that makes no sense means ask again', () {
      expect(Participation.restore(null), isA<Undecided>());
      expect(Participation.restore('not json'), isA<Undecided>());
      expect(Participation.restore('{"choice":"what"}'), isA<Undecided>());
      expect(
        Participation.restore('{"choice":"joined"}'),
        isA<Undecided>(),
        reason: 'a joined record with no key cannot be used to submit',
      );
    });
  });

  group('the controller', () {
    test('writes nothing before an explicit choice', () async {
      final store = InMemoryPreferenceStore();
      final server = _Server((_, _) => (200, '{"entries":[]}'));
      final controller = LeaderboardController(
        client: _clientFor(server),
        store: store,
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(controller.state.participation, isA<Undecided>());
      expect(
        store.read(PreferenceKey.gameParticipation.storageKey),
        isNull,
        reason: 'merely looking at the board stored something',
      );
      expect(server.seen, [
        'GET /v1/game/leaderboard',
      ], reason: 'no player key should be sent by somebody who has not joined');
    });

    test(
      'playing locally without remembering keeps the device clean',
      () async {
        final store = InMemoryPreferenceStore();
        final controller = LeaderboardController(client: null, store: store);
        addTearDown(controller.dispose);

        await controller.choose(const PlayingLocally(remembered: false));
        expect(store.read(PreferenceKey.gameParticipation.storageKey), isNull);
        expect(controller.state.participation, isA<PlayingLocally>());
      },
    );

    test(
      'a ranked run is never started by somebody who has not joined',
      () async {
        final store = InMemoryPreferenceStore();
        final server = _Server((_, _) => (200, '{}'));
        final controller = LeaderboardController(
          client: _clientFor(server),
          store: store,
        );
        addTearDown(controller.dispose);

        await controller.choose(const PlayingLocally(remembered: true));
        expect(await controller.beginRankedRun(), isNull);
        expect(server.seen, isEmpty);
      },
    );

    test('a climb finished before joining goes up once they join', () async {
      // The owner played, joined, and found nothing on the board: the first
      // climb was never played for the record. Now it is, under a key that
      // lives only in the tab, and joining claims it.
      final server = _Server((method, path) {
        if (path == '/v1/game/runs' && method == 'POST') {
          return (
            200,
            jsonEncode({
              'runId': 'run-1',
              'seed': 7,
              'token': 'signed',
              'expiresAt': 1758000600000,
            }),
          );
        }
        if (path == '/v1/game/leaderboard' && method == 'POST') {
          return (202, '{"status":"pending","ticksChecked":0}');
        }
        return (200, '{"status":"pending","ticksChecked":1}');
      });
      final store = InMemoryPreferenceStore();
      final controller = LeaderboardController(
        client: _clientFor(server),
        store: store,
      );
      addTearDown(controller.dispose);

      expect(controller.canTryRanked, isTrue);
      final challenge = (await controller.beginRankedRun())!;
      expect(controller.takeChallenge(), same(challenge));
      await controller.finish(challenge: challenge, tape: 'AAAA');
      expect(
        server.seen.where((call) => call == 'POST /v1/game/leaderboard'),
        isEmpty,
        reason: 'nothing goes up before they say they want to be on it',
      );
      expect(store.read(PreferenceKey.gameParticipation.storageKey), isNull);

      await controller.choose(
        Joined.fresh(
          nickname: 'Ahmed',
          submitsAutomatically: true,
          remembered: true,
        ),
      );
      expect(server.seen.last, 'POST /v1/game/leaderboard');
      final issuedTo = jsonDecode(server.bodies.first) as Map;
      final submitted = jsonDecode(server.bodies.last) as Map;
      expect(
        submitted['playerKey'],
        issuedTo['playerKey'],
        reason: 'the run must be submitted by the key it was issued to',
      );
      expect(controller.state.verdict, isA<VerdictPending>());
    });

    test('somebody playing on their own is never issued a run', () async {
      final server = _Server((_, _) => (200, '{}'));
      final controller = LeaderboardController(
        client: _clientFor(server),
        store: InMemoryPreferenceStore(),
      );
      addTearDown(controller.dispose);

      await controller.choose(const PlayingLocally(remembered: false));
      expect(controller.canTryRanked, isFalse);
      expect(await controller.beginRankedRun(), isNull);
      expect(server.seen, isEmpty);
    });

    test('a whole ranked run, from challenge to board', () async {
      var verdictCalls = 0;
      final server = _Server((method, path) {
        if (path == '/v1/game/runs' && method == 'POST') {
          return (
            200,
            jsonEncode({
              'runId': 'run-1',
              'seed': 7,
              'token': 'signed',
              'expiresAt': 1758000600000,
            }),
          );
        }
        if (path == '/v1/game/leaderboard' && method == 'POST') {
          return (202, '{"status":"pending","ticksChecked":0}');
        }
        if (path == '/v1/game/runs/run-1') {
          verdictCalls++;
          // Still checking the first time it is asked; the point is that the
          // client waits for the server rather than showing its own number.
          return verdictCalls < 2
              ? (200, '{"status":"pending","ticksChecked":512}')
              : (
                  200,
                  '{"status":"checked","metres":362,"rank":1,'
                      '"outcome":"accepted"}',
                );
        }
        return (
          200,
          jsonEncode({
            'entries': [
              {'rank': 1, 'nickname': 'Ahmed', 'metres': 362},
            ],
          }),
        );
      });
      final controller = LeaderboardController(
        client: _clientFor(server),
        store: InMemoryPreferenceStore(),
      );
      addTearDown(controller.dispose);

      await controller.choose(
        Joined.fresh(
          nickname: 'Ahmed',
          submitsAutomatically: true,
          remembered: true,
          random: math.Random(4),
        ),
      );
      final challenge = await controller.beginRankedRun();
      expect(challenge, isNotNull);
      expect(challenge!.seed, 7, reason: 'the seed must come from the server');

      // The stage takes the challenge when the run starts, so the controller
      // is no longer holding it by the time the climb ends -- which is the
      // whole point: a challenge fetched for the *next* run cannot be clobbered
      // by the reply to this one.
      expect(controller.takeChallenge(), same(challenge));
      expect(controller.state.challenge, isNull);
      await controller.submit(challenge: challenge, tape: 'AAAA');
      expect(controller.state.verdict, isA<VerdictPending>());
      expect(
        controller.state.board,
        isNull,
        reason: 'the board must not change before the server has checked',
      );

      // Let the poll run to the answer.
      await Future<void>.delayed(
        LeaderboardController.pollInterval * 2 +
            const Duration(milliseconds: 400),
      );
      final verdict = controller.state.verdict;
      expect(verdict, isA<VerdictChecked>());
      expect((verdict! as VerdictChecked).metres, 362);
      expect((verdict as VerdictChecked).rank, 1);
      expect(controller.state.board!.entries.single.nickname, 'Ahmed');
    });

    test(
      'restarting does not abandon the climb already being checked',
      () async {
        // A player who has just fallen presses the button again straight away.
        // The check of the run they submitted has to finish anyway: it is what
        // refreshes the board, and cancelling it left the board stale for the
        // rest of the session and the player never told they had placed.
        var verdictCalls = 0;
        var boardCalls = 0;
        final server = _Server((method, path) {
          if (path == '/v1/game/runs' && method == 'POST') {
            return (
              200,
              jsonEncode({
                'runId': 'run-1',
                'seed': 7,
                'token': 'signed',
                'expiresAt': 1758000600000,
              }),
            );
          }
          if (path == '/v1/game/leaderboard' && method == 'POST') {
            return (202, '{"status":"pending","ticksChecked":0}');
          }
          if (path == '/v1/game/runs/run-1') {
            verdictCalls++;
            return verdictCalls < 2
                ? (200, '{"status":"pending","ticksChecked":512}')
                : (
                    200,
                    '{"status":"checked","metres":120,"rank":2,'
                        '"outcome":"accepted"}',
                  );
          }
          boardCalls++;
          return (
            200,
            jsonEncode({
              'entries': [
                {'rank': 2, 'nickname': 'Ahmed', 'metres': 120},
              ],
            }),
          );
        });
        final controller = LeaderboardController(
          client: _clientFor(server),
          store: InMemoryPreferenceStore(),
        );
        addTearDown(controller.dispose);

        await controller.choose(
          Joined.fresh(
            nickname: 'Ahmed',
            submitsAutomatically: true,
            remembered: true,
            random: math.Random(9),
          ),
        );
        final challenge = (await controller.beginRankedRun())!;
        controller.takeChallenge();
        await controller.submit(challenge: challenge, tape: 'AAAA');
        expect(controller.state.verdict, isA<VerdictPending>());

        // Straight into the next climb, before the check has finished.
        controller.clearVerdict();
        expect(controller.state.verdict, isNull, reason: 'the screen is stale');

        await Future<void>.delayed(
          LeaderboardController.pollInterval * 2 +
              const Duration(milliseconds: 400),
        );

        expect(
          controller.state.verdict,
          isNull,
          reason: "the previous run's result appeared over a newer run",
        );
        expect(
          boardCalls,
          greaterThan(0),
          reason: 'the check was abandoned, so the board was never refreshed',
        );
        expect(controller.state.board!.entries.single.metres, 120);
      },
    );

    test(
      'forgetting removes the entry first, then the device record',
      () async {
        final store = InMemoryPreferenceStore();
        final order = <String>[];
        final server = _Server((method, path) {
          order.add('$method $path');
          if (method == 'DELETE') return (200, '{"removed":true,"entries":[]}');
          return (200, '{"entries":[]}');
        });
        final controller = LeaderboardController(
          client: _clientFor(server),
          store: store,
        );
        addTearDown(controller.dispose);

        await controller.choose(
          Joined.fresh(
            nickname: 'Ahmed',
            submitsAutomatically: false,
            remembered: true,
            random: math.Random(5),
          ),
        );
        expect(
          store.read(PreferenceKey.gameParticipation.storageKey),
          isNotNull,
        );

        expect(await controller.forget(), isTrue);
        expect(
          order.first,
          'DELETE /v1/game/leaderboard',
          reason: 'the key that authorises removal was discarded too early',
        );
        expect(store.read(PreferenceKey.gameParticipation.storageKey), isNull);
        expect(controller.state.participation, isA<Undecided>());
      },
    );

    test('with no leaderboard at all, everything still answers', () async {
      final controller = LeaderboardController(
        client: null,
        store: InMemoryPreferenceStore(),
      );
      addTearDown(controller.dispose);

      expect(controller.isAvailable, isFalse);
      await controller.refresh();
      expect(controller.state.board, isNull);
      expect(
        controller.state.boardFailed,
        isFalse,
        reason: 'absent is not failed',
      );
      expect(await controller.beginRankedRun(), isNull);
      expect(controller.takeChallenge(), isNull);
      await controller.submit(
        challenge: RunChallenge(
          runId: 'run-1',
          seed: 1,
          token: 'signed',
          expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        ),
        tape: 'AAAA',
      );
      expect(controller.state.verdict, isNull);
    });

    test('a board that cannot be reached is said to have failed', () async {
      final server = _Server((_, _) => (500, 'gateway'));
      final controller = LeaderboardController(
        client: _clientFor(server),
        store: InMemoryPreferenceStore(),
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(controller.state.boardFailed, isTrue);
      expect(controller.state.board, isNull);
    });
  });
}

class _Throwing extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      Future<http.StreamedResponse>.error(http.ClientException('no'));
}

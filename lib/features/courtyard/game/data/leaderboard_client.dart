import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:nocturne/features/courtyard/game/domain/leaderboard.dart';

/// Talks to the climb's leaderboard, and never insists that it answer.
///
/// Every method returns null rather than throwing. That is the whole posture of
/// this class: the board is an ornament on a game that has to keep working
/// without it. A visitor who is offline, who declined, whose Worker has no
/// leaderboard configured, or whose browser is behind something that eats the
/// request, still gets a climb and a best score kept on their own device — and
/// is never shown a number that pretends to be a ranking.
class LeaderboardClient {
  /// Talks to the Worker at [origin].
  const LeaderboardClient({
    required http.Client client,
    required Uri origin,
    this.timeout = const Duration(seconds: 6),
  }) : _http = client,
       _base = origin;

  final http.Client _http;
  final Uri _base;

  /// How long any one call is given before it is treated as absent.
  final Duration timeout;

  Uri _path(String path) => _base.replace(path: path);

  Future<Map<String, dynamic>?> _send(
    String method,
    Uri url, {
    Map<String, Object?>? body,
  }) async {
    try {
      final request = http.Request(method, url)
        ..headers['accept'] = 'application/json';
      if (body != null) {
        request
          ..headers['content-type'] = 'application/json'
          ..body = jsonEncode(body);
      }
      final streamed = await _http.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode >= 500) return null;
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on Object {
      // Deliberately everything: a timeout, a socket, a body that is not JSON,
      // a Worker answering 503 because no leaderboard is configured. The game
      // does not care which, and neither does the player.
      return null;
    }
  }

  /// The top ten, or null when the board cannot be reached.
  Future<Board?> board() async =>
      Board.fromJson(await _send('GET', _path('/v1/game/leaderboard')));

  /// Asks for a shaft to climb for the record.
  ///
  /// Called only when a participant chooses a ranked run. A visitor playing
  /// locally never reaches this, so their browser never sends a player key.
  Future<RunChallenge?> beginRun(String playerKey) async =>
      RunChallenge.fromJson(
        await _send(
          'POST',
          _path('/v1/game/runs'),
          body: {'playerKey': playerKey},
        ),
      );

  /// Submits a finished climb for checking.
  ///
  /// Returns the first verdict, which is all but certainly [VerdictPending]:
  /// the server replays a run in pieces and will not have finished yet. Poll
  /// [verdict] for the answer.
  Future<Verdict?> submit({
    required String token,
    required String playerKey,
    required String nickname,
    required String tape,
  }) async => Verdict.fromJson(
    await _send(
      'POST',
      _path('/v1/game/leaderboard'),
      body: {
        'token': token,
        'playerKey': playerKey,
        'nickname': nickname,
        'tape': tape,
      },
    ),
  );

  /// How the check of [runId] is going, or how it ended.
  Future<Verdict?> verdict(String runId) async =>
      Verdict.fromJson(await _send('GET', _path('/v1/game/runs/$runId')));

  /// Removes this participant's entry from the board.
  ///
  /// Authorised by holding the key, which is the only thing that can prove an
  /// entry is theirs — and the reason the server stores only its hash.
  Future<bool> forget(String playerKey) async {
    final reply = await _send(
      'DELETE',
      _path('/v1/game/leaderboard'),
      body: {'playerKey': playerKey},
    );
    return reply?['removed'] == true;
  }
}

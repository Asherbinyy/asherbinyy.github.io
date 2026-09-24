import 'dart:convert';
import 'dart:math' as math;

import 'package:meta/meta.dart';

/// One place on the public board.
@immutable
class BoardEntry {
  /// Creates an entry.
  const BoardEntry({
    required this.rank,
    required this.nickname,
    required this.metres,
  });

  /// Reads one the Worker sent, or null if it is not one.
  static BoardEntry? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final rank = json['rank'];
    final nickname = json['nickname'];
    final metres = json['metres'];
    if (rank is! int || nickname is! String || metres is! int) return null;
    return BoardEntry(rank: rank, nickname: nickname, metres: metres);
  }

  /// 1 for the top of the board.
  final int rank;

  /// The name that climber chose to be shown under.
  final String nickname;

  /// How high they got.
  final int metres;

  @override
  bool operator ==(Object other) =>
      other is BoardEntry &&
      other.rank == rank &&
      other.nickname == nickname &&
      other.metres == metres;

  @override
  int get hashCode => Object.hash(rank, nickname, metres);
}

/// The board as the Worker last described it.
@immutable
class Board {
  /// Creates a board.
  const Board({required this.entries, this.updatedAt});

  /// Reads the Worker's reply, or null if it is not one.
  static Board? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final raw = json['entries'];
    if (raw is! List) return null;
    final entries = <BoardEntry>[];
    for (final item in raw) {
      final entry = BoardEntry.fromJson(item);
      if (entry == null) return null;
      entries.add(entry);
    }
    final updated = json['updatedAt'];
    return Board(
      entries: entries,
      updatedAt: updated is int
          ? DateTime.fromMillisecondsSinceEpoch(updated)
          : null,
    );
  }

  /// Highest first. At most ten.
  final List<BoardEntry> entries;

  /// When it last changed, if the Worker said.
  final DateTime? updatedAt;

  /// Whether nobody has climbed yet.
  bool get isEmpty => entries.isEmpty;
}

/// Permission to attempt one ranked climb, on a shaft the server chose.
@immutable
class RunChallenge {
  /// Creates a challenge.
  const RunChallenge({
    required this.runId,
    required this.seed,
    required this.token,
    required this.expiresAt,
  });

  /// Reads the Worker's reply, or null if it is not one.
  static RunChallenge? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final runId = json['runId'];
    final seed = json['seed'];
    final token = json['token'];
    final expires = json['expiresAt'];
    if (runId is! String || seed is! int || token is! String) return null;
    if (expires is! int) return null;
    return RunChallenge(
      runId: runId,
      seed: seed,
      token: token,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expires),
    );
  }

  /// Identifies this attempt.
  final String runId;

  /// The shaft to climb. Chosen by the server, so it cannot be shopped for.
  final int seed;

  /// The signature that proves the seed was issued rather than invented.
  final String token;

  /// After which the run can no longer be submitted.
  final DateTime expiresAt;
}

/// What the server made of a submitted climb.
@immutable
sealed class Verdict {
  const Verdict();

  /// Reads the Worker's reply, or null if it is not one.
  static Verdict? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return switch (json['status']) {
      'pending' => VerdictPending(
        ticksChecked: json['ticksChecked'] as int? ?? 0,
      ),
      'checked' => VerdictChecked(
        metres: json['metres'] as int? ?? 0,
        rank: json['rank'] as int?,
        outcome: json['outcome'] as String? ?? 'unknown',
      ),
      'rejected' => VerdictRejected(
        reason: json['reason'] as String? ?? 'unknown',
      ),
      _ => null,
    };
  }
}

/// Still being replayed.
///
/// The server checks a climb a few hundred ticks at a time, so this is the
/// ordinary state for a few seconds after a submission rather than a sign that
/// something has gone wrong.
final class VerdictPending extends Verdict {
  /// Creates a pending verdict.
  const VerdictPending({required this.ticksChecked});

  /// How far into the run the check has got.
  final int ticksChecked;
}

/// Replayed in full, and judged.
final class VerdictChecked extends Verdict {
  /// Creates a checked verdict.
  const VerdictChecked({
    required this.metres,
    required this.rank,
    required this.outcome,
  });

  /// The height the *server* reached replaying the run.
  final int metres;

  /// The place on the board, or null when the climb did not make the ten.
  final int? rank;

  /// `accepted`, `improved`, `not-an-improvement` or `not-qualified`.
  final String outcome;

  /// Whether this climb is now on the board.
  bool get isRanked => rank != null && outcome != 'not-qualified';
}

/// Not a run the server could verify.
final class VerdictRejected extends Verdict {
  /// Creates a rejected verdict.
  const VerdictRejected({required this.reason});

  /// What the server called it. Deliberately coarse.
  final String reason;
}

/// Whether this browser's owner has joined the board, and how.
@immutable
sealed class Participation {
  const Participation();

  /// Reads what was stored, or [Undecided] if there is nothing readable.
  ///
  /// A stored value that cannot be understood is treated as no value at all
  /// rather than as an error: the worst case is being asked once more, and the
  /// alternative is a visitor permanently unable to play because of a key they
  /// cannot see.
  static Participation restore(String? stored) {
    if (stored == null) return const Undecided();
    try {
      final json = jsonDecode(stored);
      if (json is! Map<String, dynamic>) return const Undecided();
      return switch (json['choice']) {
        'local' => const PlayingLocally(remembered: true),
        'joined' => Joined(
          playerKey: json['key']! as String,
          nickname: json['nickname']! as String,
          submitsAutomatically: json['auto'] as bool? ?? false,
          remembered: true,
        ),
        _ => const Undecided(),
      };
    } on Object {
      return const Undecided();
    }
  }

  /// The form to store, or null when this choice is not to be remembered.
  String? persisted();
}

/// Never asked, or asked and the answer was not kept.
final class Undecided extends Participation {
  /// Creates the undecided state.
  const Undecided();

  @override
  String? persisted() => null;
}

/// Playing, with no intention of being on the board.
final class PlayingLocally extends Participation {
  /// Creates a local-only choice.
  const PlayingLocally({required this.remembered});

  /// Whether to stop asking on this browser.
  final bool remembered;

  @override
  String? persisted() => remembered ? jsonEncode({'choice': 'local'}) : null;
}

/// On the board, under a name.
final class Joined extends Participation {
  /// Creates a joined participant.
  const Joined({
    required this.playerKey,
    required this.nickname,
    required this.submitsAutomatically,
    required this.remembered,
  });

  /// Makes a new participant with a fresh key.
  ///
  /// The key is generated here, in the visitor's own browser, and its hash is
  /// the only form the server ever sees. Nothing about it is derived from the
  /// device, the browser or the network — a value that were would be a
  /// fingerprint, which is the one thing this must not be.
  factory Joined.fresh({
    required String nickname,
    required bool submitsAutomatically,
    required bool remembered,
    math.Random? random,
  }) {
    return Joined(
      playerKey: newKey(random),
      nickname: nickname,
      submitsAutomatically: submitsAutomatically,
      remembered: remembered,
    );
  }

  /// A fresh random key: 32 hex characters, from nothing but [random].
  static String newKey([math.Random? random]) {
    final source = random ?? math.Random.secure();
    return [
      for (var i = 0; i < 16; i++)
        source.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
  }

  /// The same participant holding [key] instead.
  Joined rekeyed(String key) => Joined(
    playerKey: key,
    nickname: nickname,
    submitsAutomatically: submitsAutomatically,
    remembered: remembered,
  );

  /// The secret that proves an entry is theirs. Never sent anywhere but here.
  final String playerKey;

  /// The name shown on the board.
  final String nickname;

  /// Whether a qualifying run goes up without being asked each time.
  final bool submitsAutomatically;

  /// Whether this survives a reload.
  final bool remembered;

  /// The same participant under a different name.
  Joined renamed(String name) => Joined(
    playerKey: playerKey,
    nickname: name,
    submitsAutomatically: submitsAutomatically,
    remembered: remembered,
  );

  @override
  String? persisted() => remembered
      ? jsonEncode({
          'choice': 'joined',
          'key': playerKey,
          'nickname': nickname,
          'auto': submitsAutomatically,
        })
      : null;
}

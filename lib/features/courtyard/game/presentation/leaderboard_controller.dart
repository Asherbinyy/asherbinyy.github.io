import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'package:nocturne/core/net/relay.dart';
import 'package:nocturne/app/theme/theme_controller.dart';
import 'package:nocturne/core/platform/preference_store.dart';
import 'package:nocturne/features/courtyard/game/data/leaderboard_client.dart';
import 'package:nocturne/features/courtyard/game/domain/leaderboard.dart';

/// The leaderboard, as the game sees it.
@immutable
class LeaderboardState {
  /// Creates a state.
  const LeaderboardState({
    this.participation = const Undecided(),
    this.board,
    this.isLoadingBoard = false,
    this.boardFailed = false,
    this.challenge,
    this.pendingRunId,
    this.verdict,
  });

  /// Whether this browser's owner joined, declined, or has not been asked.
  final Participation participation;

  /// The last board fetched. Null means never successfully fetched.
  final Board? board;

  /// Whether a fetch is in flight.
  final bool isLoadingBoard;

  /// Whether the last fetch failed. Distinct from an empty board, which is a
  /// real answer: nobody has climbed yet.
  final bool boardFailed;

  /// The shaft the server issued for the current ranked run, if there is one.
  final RunChallenge? challenge;

  /// The run being checked, if one is.
  final String? pendingRunId;

  /// The last thing the server said about a submitted climb.
  final Verdict? verdict;

  /// Whether this visitor is on the board at all.
  bool get hasJoined => participation is Joined;

  /// Whether the next climb can be for the record.
  bool get canPlayRanked => participation is Joined;

  LeaderboardState _with({
    Participation? participation,
    Board? board,
    bool? isLoadingBoard,
    bool? boardFailed,
    RunChallenge? challenge,
    String? pendingRunId,
    Verdict? verdict,
    bool clearChallenge = false,
    bool clearRun = false,
  }) => LeaderboardState(
    participation: participation ?? this.participation,
    board: board ?? this.board,
    isLoadingBoard: isLoadingBoard ?? this.isLoadingBoard,
    boardFailed: boardFailed ?? this.boardFailed,
    challenge: clearChallenge ? null : (challenge ?? this.challenge),
    pendingRunId: clearRun ? null : (pendingRunId ?? this.pendingRunId),
    verdict: clearRun ? null : (verdict ?? this.verdict),
  );
}

/// Owns the board, the participant's choice, and the life of one ranked run.
///
/// Nothing here runs on its own. The board is fetched when the climb is opened,
/// after a submission, and when somebody asks for it — never on a timer. The
/// only polling is while a submitted run is being checked, and that stops the
/// moment there is an answer. A leaderboard that quietly talks to a server
/// every few seconds for as long as a tab is open is a tracker with a
/// scoreboard drawn on it.
class LeaderboardController extends StateNotifier<LeaderboardState> {
  /// Restores any remembered choice and otherwise starts undecided.
  LeaderboardController({
    required LeaderboardClient? client,
    required PreferenceStore store,
  }) : _board = client,
       _store = store,
       super(
         LeaderboardState(
           participation: Participation.restore(
             store.read(PreferenceKey.gameParticipation.storageKey),
           ),
         ),
       );

  final LeaderboardClient? _board;
  final PreferenceStore _store;
  Timer? _poll;

  /// A key for this tab only, so the very first climb can be for the record.
  ///
  /// The board is offered after a climb, with its height on the screen -- but
  /// a climb only counts if it was played on a shaft the server chose before
  /// it began. So the first climb used to be lost to anybody who joined after
  /// it, which is everybody who joins: the owner played, joined, and found
  /// nothing on the board.
  ///
  /// This is random, held in memory, never written to the device, and derived
  /// from nothing, so it identifies nothing; the Worker stores nothing when it
  /// issues a run. Somebody who joins takes this key as theirs, which is what
  /// lets the climb they have just finished go up.
  final String _tabKey = Joined.newKey();

  /// A finished climb, played for the record by somebody who had not yet
  /// said whether they want to be on the board. Sent if they join; dropped
  /// otherwise.
  ({RunChallenge challenge, String tape})? _unclaimed;

  /// A run being fetched, so two callers share one request.
  Future<RunChallenge?>? _fetching;

  /// Whether a leaderboard exists to talk to in this build at all.
  bool get isAvailable => _board != null;

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  /// Fetches the board. Safe to call when there is no leaderboard.
  Future<void> refresh() async {
    final client = _board;
    if (client == null) return;
    state = state._with(isLoadingBoard: true, boardFailed: false);
    final board = await client.board();
    if (!mounted) return;
    state = state._with(
      board: board,
      isLoadingBoard: false,
      boardFailed: board == null,
    );
  }

  /// Records the visitor's answer to the one question this feature asks.
  Future<void> choose(Participation answer) async {
    // Somebody joining now takes the key the climbs in this tab were issued
    // to, so the one they have just finished is theirs to submit.
    final choice = answer is Joined && state.participation is! Joined
        ? answer.rekeyed(_tabKey)
        : answer;
    state = state._with(participation: choice);
    final stored = choice.persisted();
    if (stored == null) {
      // Not remembered, or not a choice worth remembering. Either way nothing
      // is left on the device -- including any earlier answer, because a
      // visitor who has just said "do not remember me" should not find an old
      // decision still sitting there.
      await _store.remove(PreferenceKey.gameParticipation.storageKey);
    } else {
      await _store.write(PreferenceKey.gameParticipation.storageKey, stored);
    }
    final unclaimed = _unclaimed;
    _unclaimed = null;
    if (choice is Joined && unclaimed != null) {
      await submit(challenge: unclaimed.challenge, tape: unclaimed.tape);
    }
  }

  /// Changes the name shown, keeping the same entry.
  Future<void> rename(String nickname) async {
    final participation = state.participation;
    if (participation is! Joined) return;
    await choose(participation.renamed(nickname));
  }

  /// Leaves the board and forgets everything about this browser's participant.
  ///
  /// The order matters: the entry goes first, while the key that authorises
  /// its removal is still known. Forgetting locally first would strand a public
  /// row with a name on it and no way left to take it down.
  Future<bool> forget() async {
    final participation = state.participation;
    var removed = true;
    if (participation is Joined) {
      removed = await _board?.forget(participation.playerKey) ?? false;
    }
    await choose(const Undecided());
    await refresh();
    return removed;
  }

  /// Asks the server for a shaft, for a climb that is meant to count.
  ///
  /// Returns null when there is no leaderboard, the visitor has not joined, or
  /// the server did not answer — and the caller then starts an ordinary local
  /// run, which is the escape the contract insists stays open.
  Future<RunChallenge?> beginRankedRun() {
    final client = _board;
    final participation = state.participation;
    if (client == null) return Future.value();
    final key = switch (participation) {
      Joined(:final playerKey) => playerKey,
      // Not asked yet: the climb may still be claimed. See [_tabKey].
      Undecided() => _tabKey,
      PlayingLocally() => null,
    };
    if (key == null) return Future.value();
    return _fetching ??= () async {
      final challenge = await client.beginRun(key);
      _fetching = null;
      if (!mounted) return null;
      state = challenge == null
          ? state._with(clearChallenge: true)
          : state._with(challenge: challenge, clearRun: true);
      return challenge;
    }();
  }

  /// Whether the next climb can be played for the record, once a run is in
  /// hand: everybody but somebody who chose to play on their own.
  bool get canTryRanked =>
      _board != null && state.participation is! PlayingLocally;

  /// Sends a finished climb, or keeps it for somebody not yet asked.
  Future<void> finish({
    required RunChallenge challenge,
    required String tape,
  }) async {
    switch (state.participation) {
      case Joined():
        await submit(challenge: challenge, tape: tape);
      case Undecided():
        _unclaimed = (challenge: challenge, tape: tape);
      case PlayingLocally():
        break;
    }
  }

  /// Hands over the challenge in hand, and stops holding it.
  ///
  /// The run that is about to start owns it from here. Leaving it in this state
  /// while a climb was in progress meant the reply to that climb's submission
  /// could clear a *newer* challenge that had been fetched in the meantime,
  /// and the next run would quietly stop counting.
  RunChallenge? takeChallenge() {
    final challenge = state.challenge;
    if (challenge == null) return null;
    state = state._with(clearChallenge: true);
    return challenge;
  }

  /// Sends a finished climb to be replayed, and follows the check to its end.
  Future<void> submit({
    required RunChallenge challenge,
    required String tape,
  }) async {
    final client = _board;
    final participation = state.participation;
    if (client == null || participation is! Joined) return;

    final first = await client.submit(
      token: challenge.token,
      playerKey: participation.playerKey,
      nickname: participation.nickname,
      tape: tape,
    );
    if (!mounted) return;
    if (first == null) return;
    state = state._with(verdict: first, pendingRunId: challenge.runId);
    if (first is VerdictPending) _watch(challenge.runId);
  }

  /// The longest the first climb of a visit waits for a run from the server.
  static const Duration firstRunWait = Duration(milliseconds: 1500);

  /// How often the verdict is asked for while a run is being checked.
  ///
  /// The server replays about five hundred ticks per hop, so a long climb takes
  /// a few seconds of them. This is slow enough not to be a hammer and fast
  /// enough that the answer arrives while the player is still looking at the
  /// screen they finished on.
  static const Duration pollInterval = Duration(milliseconds: 1200);

  /// How long to keep asking before giving up and saying so.
  static const Duration pollLimit = Duration(seconds: 90);

  /// Which run the screen is currently showing a result for.
  ///
  /// A player who has just fallen often presses the button again immediately,
  /// which used to cancel the check of the climb they had just submitted. They
  /// never saw their place, and — worse — the board stopped being refreshed for
  /// the rest of the session, because the refresh is what a finished check
  /// triggers. So starting a new run stops *showing* the old verdict without
  /// stopping the check: it runs to its end, the board is refreshed either way,
  /// and the verdict is only put on screen if the screen is still the one that
  /// asked for it.
  int _generation = 0;

  void _watch(String runId) {
    _poll?.cancel();
    final client = _board;
    if (client == null) return;
    final generation = _generation;
    final deadline = DateTime.now().add(pollLimit);
    _poll = Timer.periodic(pollInterval, (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (DateTime.now().isAfter(deadline)) {
        timer.cancel();
        // Not a rejection. The climb may well be fine; this browser simply
        // stopped waiting, and saying "rejected" would be a claim nobody here
        // is in a position to make.
        if (generation == _generation) state = state._with(clearRun: true);
        return;
      }
      final verdict = await client.verdict(runId);
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (verdict == null || verdict is VerdictPending) return;
      timer.cancel();
      if (generation == _generation) state = state._with(verdict: verdict);
      // Refreshed whichever run the player is looking at now. A climb that
      // took a place while they were busy failing the next one still belongs
      // on the board in front of them.
      await refresh();
    });
  }

  /// Stops showing the last verdict, so a new run starts with a clean screen.
  ///
  /// The check itself is left running. See [_generation].
  void clearVerdict() {
    _generation++;
    state = state._with(clearRun: true);
  }
}

/// The client, or null when this build has no Worker to talk to.
final leaderboardClientProvider = Provider<LeaderboardClient?>((ref) {
  final origin = ref.watch(relayEndpointProvider);
  if (origin == null) return null;
  final client = http.Client();
  ref.onDispose(client.close);
  return LeaderboardClient(client: client, origin: origin);
});

/// The leaderboard, for the climb to read.
final leaderboardControllerProvider =
    StateNotifierProvider<LeaderboardController, LeaderboardState>(
      (ref) => LeaderboardController(
        client: ref.watch(leaderboardClientProvider),
        store: ref.watch(preferenceStoreProvider),
      ),
    );

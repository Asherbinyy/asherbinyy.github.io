import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// One sound the climb can make.
enum AscentSound {
  /// A foot finding stone.
  bounce('audio/bounce.wav'),

  /// A weathered ledge giving way.
  breaking('audio/break.wav'),

  /// A struck bar, on passing a band.
  collect('audio/collect.wav'),

  /// The floor going away.
  fall('audio/fall.wav'),

  /// The shaft opening.
  start('audio/start.wav');

  const AscentSound(this.asset);

  /// Path within the bundle, without the `assets/` prefix `audioplayers` adds.
  final String asset;
}

/// Plays the climb's sounds, or silently does not.
///
/// Every sample is synthesised rather than sourced: struck stone, filtered
/// noise, a rising fifth. That removes the licensing question the provenance
/// ledger would otherwise have to carry for five audio files, and the whole
/// set is 96KB.
///
/// Nothing plays before the player presses start, which is both the design and
/// what browser autoplay policy requires. A device that refuses to play audio
/// is not an error: the game is fully playable in silence and every failure
/// here is swallowed on purpose.
class AscentAudio {
  /// Creates a silent player. Call [prime] once a gesture has happened.
  AscentAudio();

  final Map<AscentSound, AudioPlayer> _players = {};
  bool _isMuted = false;
  bool _isReady = false;

  /// Whether sound is currently suppressed.
  bool get isMuted => _isMuted;

  /// Flips mute, and stops anything mid-flight when going quiet.
  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      for (final player in _players.values) {
        unawaited(player.stop());
      }
    }
  }

  /// Builds one player per sound, after the first gesture.
  ///
  /// One player each rather than one shared: two bounces can overlap, and a
  /// single player would cut the first off mid-strike.
  Future<void> prime() async {
    if (_isReady) return;
    _isReady = true;
    for (final sound in AscentSound.values) {
      try {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setSource(AssetSource(sound.asset));
        _players[sound] = player;
      } catch (_) {
        // A browser that will not decode this file simply has no sound for it.
      }
    }
  }

  /// Plays [sound], if it can.
  void play(AscentSound sound) {
    if (_isMuted) return;
    final player = _players[sound];
    if (player == null) return;
    unawaited(player.stop().then((_) => player.resume()).catchError((_) {}));
  }

  /// Releases every player.
  Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }
}

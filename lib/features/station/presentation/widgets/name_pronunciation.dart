import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:audioplayers/audioplayers.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';

/// Plays the owner saying his own name.
///
/// "Elsherbini" is mispronounced by almost everyone who reads it before they
/// hear it, and a phonetic respelling only moves the guess. The recording is
/// his voice, 1.4 seconds, 12KB.
///
/// It is a button rather than anything that plays on arrival: audio a visitor
/// did not ask for is the single rudest thing a page can do, and browsers
/// block it anyway.
class NamePronunciation extends StatefulWidget {
  /// Creates the control.
  const NamePronunciation({super.key});

  @override
  State<NamePronunciation> createState() => _NamePronunciationState();
}

class _NamePronunciationState extends State<NamePronunciation>
    with SingleTickerProviderStateMixin {
  AudioPlayer? _player;
  StreamSubscription<void>? _finished;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _isPlaying = false;

  @override
  void dispose() {
    unawaited(_finished?.cancel());
    unawaited(_player?.dispose());
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    // Built on first press rather than in initState: a visitor who never asks
    // to hear it should not pay for a decoder.
    final player = _player ??= AudioPlayer();
    _finished ??= player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });

    setState(() => _isPlaying = true);
    if (!ReducedMotion.of(context)) {
      unawaited(_pulse.forward(from: 0));
    }
    try {
      await player.stop();
      await player.play(AssetSource('audio/name.m4a'));
    } catch (_) {
      // A browser that will not decode it is not an error worth showing: the
      // name is written directly above.
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return Semantics(
      button: true,
      container: true,
      label: l10n.heroSayName,
      liveRegion: _isPlaying,
      value: _isPlaying ? l10n.heroSayNamePlaying : null,
      // The label is written here and the children are silenced, rather than
      // letting them merge. The caption below says the same words on screen,
      // so without this a screen reader announced the button as "Hear my name,
      // Hear my name". A tooltip repeating visible text was removed for the
      // same reason: it restated what the reader could already see.
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: _play,
          borderRadius: BorderRadius.circular(tokens.space24),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.space12,
              vertical: tokens.space8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Three rising bars, which is what a voice looks like drawn
                // small, and reads at this size where a speaker glyph does
                // not.
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) => CustomPaint(
                    size: Size(tokens.space16, tokens.space16),
                    painter: _VoicePainter(
                      colour: tokens.beacon,
                      progress: _isPlaying ? _pulse.value : 0,
                      strokeWidth: Tokens.hairlineWidth * 2,
                    ),
                  ),
                ),
                SizedBox(width: tokens.space8),
                Text(
                  l10n.heroSayName,
                  style: context.type.telemetryS.copyWith(
                    color: tokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Three bars that rise and fall while the recording plays.
class _VoicePainter extends CustomPainter {
  const _VoicePainter({
    required this.colour,
    required this.progress,
    required this.strokeWidth,
  });

  final Color colour;
  final double progress;
  final double strokeWidth;

  /// Resting heights, as a fraction of the box: short, tall, medium.
  static const List<double> _rest = [0.42, 0.86, 0.58];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colour
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final gap = size.width / (_rest.length * 2 - 1);
    for (final (index, rest) in _rest.indexed) {
      // Each bar leads the one before it, so the group reads as speech
      // travelling rather than as three things blinking together.
      final phase = (progress * 3 - index * 0.22).clamp(0.0, 3.0);
      final swing = progress == 0 ? 0.0 : 0.34 * math.sin(phase * math.pi * 2);
      final height = (rest + swing).clamp(0.18, 1.0) * size.height;
      final x = gap * index * 2 + strokeWidth / 2;
      canvas.drawLine(
        Offset(x, (size.height - height) / 2),
        Offset(x, (size.height + height) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_VoicePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.colour != colour;
}

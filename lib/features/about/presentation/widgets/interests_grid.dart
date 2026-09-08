import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/models/interests.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/painting/interest_painter.dart';

/// Off duty — what the owner does when he is not working.
///
/// The brief's second goal for milestone 4 is that there is a person here, and
/// this is where that is answered. It is one section rather than a second
/// site: a recruiter answering "can this person ship?" scrolls past it, and
/// someone deciding whether they want to work with him stops.
///
/// Every tile is legible without interacting with it. The note — the show, the
/// games — is always on screen, not hidden behind a hover, because a fact worth
/// putting on the page is worth a touch user and a screen reader getting too.
/// What interaction adds is emphasis, not information.
class InterestsGrid extends ConsumerWidget {
  /// Reads `interests.json`.
  const InterestsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interests = switch (ref.watch(interestsProvider).valueOrNull) {
      ContentReady<Interests>(:final data) => data.interests,
      _ => const <Interest>[],
    };

    // The section removes itself rather than heading an empty grid.
    if (interests.isEmpty) return const SizedBox.shrink();

    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.aboutOffDuty, style: context.type.heading),
        SizedBox(height: tokens.space16),
        Wrap(
          spacing: tokens.space16,
          runSpacing: tokens.space16,
          children: [
            for (final interest in interests) _Tile(interest: interest),
          ],
        ),
      ],
    );
  }
}

/// One interest: its scene, its name, and the specific he named.
///
/// The first version of this was a word in a box, and the owner's objection
/// was exactly right: "gym" told nobody anything. Each tile now plays a small
/// scene that carries the meaning, and the label confirms it rather than
/// carrying it alone.
///
/// Unlike the first version, these **are** focusable. There was nothing to do
/// then, so being in the tab order was six stops for nothing; now the tile is
/// the interaction, and a keyboard has to be able to reach it. Everything is
/// still legible without touching anything: the scene rests in a readable
/// state and the words are always on screen.
class _Tile extends StatefulWidget {
  const _Tile({required this.interest});

  final Interest interest;

  /// Declared, never inferred.
  static const double width = 168;

  /// The scene's height.
  static const double artHeight = 116;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> with SingleTickerProviderStateMixin {
  late final AnimationController _play = AnimationController(
    vsync: this,
    duration: Motion.considered,
  );
  bool _isActive = false;

  @override
  void dispose() {
    _play.dispose();
    super.dispose();
  }

  void _setActive({required bool active}) {
    if (_isActive == active) return;
    setState(() => _isActive = active);
    if (!mounted) return;
    // Under reduced motion the scene jumps to its played state rather than
    // animating: the information is the position, not the travel.
    if (ReducedMotion.of(context)) {
      _play.value = active ? 1 : 0;
      return;
    }
    if (active) {
      _play.forward();
    } else {
      _play.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final locale = context.channel;
    final note = widget.interest.note?.resolve(locale);
    final label = widget.interest.label.resolve(locale);

    return Semantics(
      // One node for the pair. Read apart, "Television" and "Better Call Saul"
      // are two unrelated announcements.
      container: true,
      label: note == null ? label : '$label. $note',
      child: FocusableActionDetector(
        onShowHoverHighlight: (value) => _setActive(active: value),
        onShowFocusHighlight: (value) => _setActive(active: value),
        mouseCursor: SystemMouseCursors.basic,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _play
                ..reset()
                ..forward();
              return null;
            },
          ),
        },
        child: GestureDetector(
          // Touch has no hover, so a tap plays the scene once.
          onTap: () => _play
            ..reset()
            ..forward(),
          child: ExcludeSemantics(
            child: SizedBox(
              width: _Tile.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Plate(
                    interest: widget.interest,
                    play: _play,
                    isActive: _isActive,
                  ),
                  SizedBox(height: tokens.space8),
                  Text(
                    label,
                    style: type.body.copyWith(
                      color: _isActive ? tokens.beacon : tokens.textPrimary,
                    ),
                  ),
                  if (note != null)
                    Text(
                      note,
                      style: type.telemetryS.copyWith(color: tokens.textMuted),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The scene, with an edge that answers a pointer.
class _Plate extends StatelessWidget {
  const _Plate({
    required this.interest,
    required this.play,
    required this.isActive,
  });

  final Interest interest;
  final Animation<double> play;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return AnimatedContainer(
      duration: ReducedMotion.duration(context, Motion.quick),
      curve: MotionCurves.emphasized,
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(
          color: isActive ? tokens.beacon : tokens.hairline,
          width: tokens.hairlineWidth,
        ),
      ),
      child: SizedBox(
        width: _Tile.width,
        height: _Tile.artHeight,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: play,
            builder: (context, _) => CustomPaint(
              painter: InterestPainter(
                scene: InterestScene.of(interest.id),
                progress: MotionCurves.emphasized.transform(play.value),
                ink: tokens.instrumentMid,
                gold: tokens.beacon,
                strokeWidth: tokens.hairlineWidth * 1.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

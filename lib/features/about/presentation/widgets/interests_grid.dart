import 'package:nocturne/core/painting/football_scene.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/widgets/even_grid.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/models/interests.dart';
import 'package:nocturne/content/models/localized_text.dart';
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
        // A grid, so a single column on a phone fills the width instead of
        // leaving a 168px tile against the left edge of a 350px page.
        EvenGrid(
          minTileWidth: _Tile.width,
          spacing: tokens.space16,
          stretch: true,
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
    duration: _isFootball ? Tokens.footballAction : Motion.considered,
  );
  bool _isActive = false;
  bool get _isFootball =>
      InterestScene.of(widget.interest.id) == InterestScene.football;

  void _replay() {
    if (ReducedMotion.of(context)) {
      _play.value = 1;
    } else {
      _play.forward(from: 0);
    }
  }

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
    if (_isFootball) {
      if (active) _replay();
      return;
    }
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
    final picks = widget.interest.picks;
    final label = widget.interest.label.resolve(locale);

    return Semantics(
      // One node for the pair. Read apart, "Television" and "Better Call Saul"
      // are two unrelated announcements.
      container: true,
      button: true,
      label: [
        label,
        if (note != null) note,
        // Read aloud as a sentence, so "The Alchemist by Paulo Coelho" rather
        // than two disconnected stops.
        for (final pick in picks)
          if (pick.by case final LocalizedText by)
            '${pick.name.resolve(locale)} '
                '${context.l10n.offDutyBy(by.resolve(locale))}'
          else
            pick.name.resolve(locale),
      ].join('. '),
      child: FocusableActionDetector(
        onShowHoverHighlight: (value) => _setActive(active: value),
        onShowFocusHighlight: (value) => _setActive(active: value),
        mouseCursor: SystemMouseCursors.click,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _replay();
              return null;
            },
          ),
        },
        child: GestureDetector(
          // Touch has no hover, so a tap plays the scene once.
          onTap: _replay,
          child: ExcludeSemantics(
            child: SizedBox(
              width: double.infinity,
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
                  if (picks.isNotEmpty) ...[
                    SizedBox(height: tokens.space8),
                    _Picks(picks: picks, locale: locale),
                  ],
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
        width: double.infinity,
        height: _Tile.artHeight,
        child: RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedBuilder(
                animation: play,
                builder: (context, _) => CustomPaint(
                  painter: InterestPainter(
                    scene: InterestScene.of(interest.id),
                    progress:
                        InterestScene.of(interest.id) == InterestScene.football
                        ? play.value
                        : MotionCurves.emphasized.transform(play.value),
                    ink: tokens.instrumentMid,
                    gold: tokens.beacon,
                    strokeWidth: tokens.hairlineWidth * 1.6,
                  ),
                ),
              ),
              if (InterestScene.of(interest.id) == InterestScene.football)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: tokens.space4),
                    child: AnimatedBuilder(
                      animation: play,
                      builder: (context, _) => Opacity(
                        opacity:
                            ((play.value - FootballScene.impact) /
                                    (1 - FootballScene.impact))
                                .clamp(0.0, 1.0),
                        child: Text(
                          context.l10n.footballGoal,
                          style: context.type.telemetry.copyWith(
                            color: tokens.beacon,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // The real mark for a named specific, where the owner has
              // supplied one. A crest is a trademark and drawing an
              // approximation of it would be worse than not having it, so the
              // file is his to add and the drawing carries on underneath
              // until he does: `errorBuilder` turns a missing asset into the
              // scene rather than into a broken-image box.
              if (interest.logo case final String path)
                Align(
                  alignment: AlignmentDirectional.bottomEnd,
                  child: Padding(
                    padding: EdgeInsets.all(tokens.space8),
                    child: Image.asset(
                      path,
                      height: tokens.space32,
                      errorBuilder: (context, error, stack) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The specific things an interest is made of, set as a short list.
///
/// A comma-joined line ran them together and read as an afterthought -- the
/// owner's word for it was random. Each pick gets its own row, the title in the
/// reading face and the person behind it quieter and beside it, so a glance
/// separates "Animal Farm" from "George Orwell" without having to parse a
/// sentence.
class _Picks extends StatelessWidget {
  const _Picks({required this.picks, required this.locale});

  final List<InterestPick> picks;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final pick in picks)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.space8),
            // No baseline alignment here. The gold tick is a ColoredBox with
            // no text baseline, and the grid asks every row for a dry layout
            // so each card in it can share a height -- which turns "no
            // baseline" into an assertion rather than a shrug.
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // A small gold tick, so the list reads as things chosen rather
                // than things listed. Nudged down to meet the title's line.
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: tokens.space8,
                    top: tokens.space8,
                  ),
                  child: SizedBox(
                    width: tokens.space8,
                    height: tokens.hairlineWidth * 2,
                    child: ColoredBox(color: tokens.beaconDim),
                  ),
                ),
                // Title above, the person beneath it. Side by side they shared
                // one narrow tile and both ended in an ellipsis: "The Alche…"
                // by "George Orwe…" tells a reader less than either alone
                // would have.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pick.name.resolve(locale),
                        style: type.bodyS.copyWith(color: tokens.textSecondary),
                      ),
                      if (pick.by case final LocalizedText by)
                        Text(
                          by.resolve(locale),
                          style: type.telemetryS.copyWith(
                            color: tokens.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

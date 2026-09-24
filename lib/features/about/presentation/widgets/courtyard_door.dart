import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/models/interests.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/painting/ascent_painter.dart';
import 'package:nocturne/core/painting/interest_painter.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_world.dart';

/// The way through to `/courtyard` from the foot of the credentials.
///
/// It was a heading, a sentence and a button on a panel the width of the page,
/// and the owner called it too wide and boring: most of it was empty. It keeps
/// the page's width -- every section lines up, which he also asked for -- and
/// fills it with what is through the door: a still of the climb and the
/// scenes of four of his interests. Under the pointer the scenes play, the way
/// they do in the courtyard itself. The button is the way in for a keyboard;
/// the pictures are the same door for a pointer.
class CourtyardDoor extends ConsumerStatefulWidget {
  /// Draws the door.
  const CourtyardDoor({super.key});

  @override
  ConsumerState<CourtyardDoor> createState() => _CourtyardDoorState();
}

class _CourtyardDoorState extends ConsumerState<CourtyardDoor>
    with SingleTickerProviderStateMixin {
  // At rest the scenes are whole; the pointer replays them.
  late final AnimationController _play = AnimationController(
    vsync: this,
    duration: Tokens.doorPlay,
    value: 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ReducedMotion.of(context)) _play.value = 1;
  }

  @override
  void dispose() {
    _play.dispose();
    super.dispose();
  }

  void _hover(bool inside) {
    if (!inside || ReducedMotion.of(context)) return;
    _play.forward(from: 0);
  }

  void _enter() => context.goNamed(AppRoute.courtyard.name);

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;
    final interests = switch (ref.watch(interestsProvider).valueOrNull) {
      ContentReady<Interests>(:final data) => data.interests,
      _ => const <Interest>[],
    };

    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.courtyardHeading, style: type.heading),
        SizedBox(height: tokens.space8),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
          child: Text(
            l10n.courtyardIntro,
            style: type.body.copyWith(color: tokens.textSecondary),
          ),
        ),
        SizedBox(height: tokens.space8),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
          child: Text(
            l10n.aboutCourtyardInside,
            style: type.bodyS.copyWith(color: tokens.textMuted),
          ),
        ),
        SizedBox(height: tokens.space24),
        BeaconButton(label: l10n.aboutOffDuty, onPressed: _enter),
      ],
    );

    final view = ExcludeSemantics(
      child: MouseRegion(
        cursor: context.platform.isPointer
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        child: GestureDetector(
          onTap: _enter,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Climb(),
              SizedBox(width: tokens.space12),
              // Two by two, the height of the climb beside them.
              SizedBox(
                width: Tokens.doorSceneSize * 2 + tokens.space12,
                child: Wrap(
                  spacing: tokens.space12,
                  runSpacing: tokens.space12,
                  children: [
                    for (final interest in interests.take(4))
                      _Scene(interest: interest, play: _play),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => _hover(true),
      onExit: (_) => _hover(false),
      child: SizedBox(
        width: double.infinity,
        child: InstrumentPanel(
          fill: tokens.surface,
          padding: EdgeInsets.all(tokens.space24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < Tokens.doorSplitWidth) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    words,
                    SizedBox(height: tokens.space24),
                    // The pictures keep their proportions and shrink to fit
                    // a phone's column rather than running off its edge.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: view,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: words),
                  SizedBox(width: tokens.space32),
                  view,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The first moment of a climb, drawn by the game's own painter.
class _Climb extends StatelessWidget {
  const _Climb();

  /// A fixed seed, so the still is the same climb on every visit.
  static final AscentWorld _world = AscentWorld.seeded(
    best: 0,
    isPractice: true,
    seed: Tokens.courtyardStillSeed,
  );

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: tokens.hairline, width: tokens.hairlineWidth),
      ),
      child: SizedBox(
        width: Tokens.doorClimbWidth,
        height:
            Tokens.doorSceneSize * 2 + tokens.space12 + Tokens.doorLabel * 2,
        child: ClipRect(
          child: CustomPaint(
            painter: AscentPainter(
              world: _world,
              entrance: 1,
              stone: tokens.instrument,
              cracked: tokens.instrumentDim,
              gold: tokens.beacon,
              glow: tokens.beaconGlow,
              wall: tokens.hairline,
              chamber: tokens.surfaceRaised,
              pier: tokens.void_,
              strokeWidth: tokens.hairlineWidth,
              isReducedMotion: true,
            ),
          ),
        ),
      ),
    );
  }
}

/// One interest's scene, small, with its name under it.
class _Scene extends StatelessWidget {
  const _Scene({required this.interest, required this.play});

  final Interest interest;
  final Animation<double> play;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scene = InterestScene.of(interest.id);
    return SizedBox(
      width: Tokens.doorSceneSize,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.surfaceRaised,
              border: Border.all(
                color: tokens.hairline,
                width: tokens.hairlineWidth,
              ),
            ),
            child: SizedBox.square(
              dimension: Tokens.doorSceneSize,
              child: AnimatedBuilder(
                animation: play,
                builder: (context, _) => CustomPaint(
                  painter: InterestPainter(
                    scene: scene,
                    progress: scene == InterestScene.football
                        ? play.value
                        : MotionCurves.emphasized.transform(play.value),
                    ink: tokens.instrumentMid,
                    gold: tokens.beacon,
                    strokeWidth: tokens.hairlineWidth * 1.4,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: Tokens.doorLabel,
            child: Center(
              child: Text(
                interest.label.resolve(context.channel),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.type.meta.copyWith(color: tokens.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

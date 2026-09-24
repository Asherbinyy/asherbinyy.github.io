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
import 'package:nocturne/core/painting/interest_painter.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';
import 'package:nocturne/features/about/presentation/widgets/live_climb.dart';

/// The way through to `/courtyard` from the foot of the credentials.
///
/// The owner found the first two versions of this less appealing than
/// everything around them: a sentence and a button, then a grid of small
/// stills. So the door now shows what is through it, moving: the game itself,
/// climbing on its own, beside the words and his interests as small scenes
/// that play under the pointer. The button is the way in for a keyboard.
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
            l10n.aboutCourtyardInside,
            style: type.body.copyWith(color: tokens.textSecondary),
          ),
        ),
        SizedBox(height: tokens.space24),
        ExcludeSemantics(
          child: Wrap(
            spacing: tokens.space12,
            runSpacing: tokens.space12,
            children: [
              for (final interest in interests.take(4))
                _Scene(interest: interest, play: _play),
            ],
          ),
        ),
        SizedBox(height: tokens.space24),
        BeaconButton(
          label: l10n.aboutOffDuty,
          emphasis: ButtonEmphasis.primary,
          onPressed: _enter,
        ),
      ],
    );

    Widget climb(double height) => MouseRegion(
      cursor: context.platform.isPointer
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      child: GestureDetector(
        onTap: _enter,
        child: LiveClimb(height: height),
      ),
    );

    return MouseRegion(
      onEnter: (_) => _hover(true),
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
                    climb(Tokens.doorClimbCompact),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: words),
                  SizedBox(width: tokens.space32),
                  SizedBox(
                    width: Tokens.doorClimbWidth,
                    child: climb(Tokens.doorClimbHeight),
                  ),
                ],
              );
            },
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

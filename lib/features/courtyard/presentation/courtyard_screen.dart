import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';
import 'package:nocturne/features/about/presentation/widgets/interests_grid.dart';
import 'package:nocturne/features/about/presentation/widgets/live_climb.dart';
import 'package:nocturne/core/widgets/gold_edge.dart';
import 'package:nocturne/features/courtyard/game/presentation/ascent_stage.dart';
import 'package:nocturne/features/courtyard/game/presentation/leaderboard_controller.dart';
import 'package:nocturne/features/courtyard/game/presentation/widgets/leaderboard_panel.dart';

/// `/courtyard` — everything that is not work.
///
/// Egyptian houses and temples were built around a courtyard, and tomb walls
/// gave as much space to the life lived in one — fowling, music, senet, the
/// garden — as to the titles of the person buried there. That is exactly the
/// job this page does, and it is why it is a room rather than a list at the
/// bottom of `/about`.
///
/// The climb sits behind a press. A game that starts itself on arrival is a
/// game in the way, and most visitors here are reading rather than playing.
class CourtyardScreen extends ConsumerStatefulWidget {
  /// Creates the courtyard.
  const CourtyardScreen({super.key});

  @override
  ConsumerState<CourtyardScreen> createState() => _CourtyardScreenState();
}

class _CourtyardScreenState extends ConsumerState<CourtyardScreen> {
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final type = context.type;

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: context.platform.gutter,
        end: context.platform.gutter,
        top: tokens.space48,
        bottom: tokens.space64,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.courtyardHeading, style: type.displayM),
          SizedBox(height: tokens.space8),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: type.measureFor(type.bodyL)),
            child: Text(
              l10n.courtyardIntro,
              style: type.bodyL.copyWith(color: tokens.textSecondary),
            ),
          ),
          SizedBox(height: tokens.space32),
          // The climb opens full screen rather than unfolding inside the page.
          // A game embedded in a document competes with it for the keyboard,
          // for the width, and for the reader's attention, and loses all three.
          //
          // The whole width, like the section under it. It used to share a
          // row with a panel announcing a second game nobody had decided on;
          // the owner asked for that to go, and a half-width panel beside
          // nothing is the ragged edge he asked every page to lose.
          _GameInvitation(onPlay: () => AscentStage.open(context)),
          SizedBox(height: tokens.space48),
          const InterestsGrid(),
        ],
      ),
    );
  }
}

/// The panel that offers the climb, before anyone has asked for it.
class _GameInvitation extends ConsumerWidget {
  const _GameInvitation({required this.onPlay});

  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;
    // No board in this build, no button for one: it opened an empty box.
    final hasBoard = ref.watch(leaderboardClientProvider) != null;

    final invitation = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: tokens.space48,
          height: tokens.hairlineWidth * 2,
          child: ColoredBox(color: tokens.beacon),
        ),
        SizedBox(height: tokens.space12),
        Text(l10n.ascentHeading, style: type.heading),
        SizedBox(height: tokens.space8),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
          child: Text(
            l10n.courtyardGamePitch,
            style: type.body.copyWith(color: tokens.textSecondary),
          ),
        ),
        SizedBox(height: tokens.space8),
        // Where the climb comes from, in one sentence: the owner cut the
        // three it used to take.
        Text(
          l10n.courtyardGameInspiration,
          style: type.bodyS.copyWith(color: tokens.textMuted),
        ),
        SizedBox(height: tokens.space24),
        Wrap(
          spacing: tokens.space8,
          runSpacing: tokens.space8,
          children: [
            BeaconButton(
              label: l10n.courtyardPlay,
              emphasis: ButtonEmphasis.primary,
              onPressed: onPlay,
            ),
            if (hasBoard)
              BeaconButton(
                label: l10n.courtyardScoreboard,
                onPressed: () => _showBoard(context, ref),
              ),
          ],
        ),
      ],
    );

    return GoldEdge(
      child: InstrumentPanel(
        fill: tokens.surface,
        padding: EdgeInsets.all(tokens.space24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Below this the climb would squeeze the copy into a column too
            // narrow for a sentence, so on a phone it goes under the words.
            if (constraints.maxWidth < Tokens.mediumBreakpoint) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  invitation,
                  SizedBox(height: tokens.space24),
                  const LiveClimb(height: Tokens.doorClimbCompact),
                ],
              );
            }
            return Row(
              children: [
                Expanded(flex: 3, child: invitation),
                SizedBox(width: tokens.space32),
                // The game itself, climbing, rather than one still frame of it.
                const Expanded(
                  flex: 2,
                  child: LiveClimb(height: Tokens.courtyardStillHeight),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The board, without having to play first.
  ///
  /// The owner asked for a way to see where things stand from the courtyard.
  /// It is the same panel the climb's results screen uses, so there is one
  /// place that knows how to say "nobody has climbed yet" and one place that
  /// knows how to say the board is unreachable.
  ///
  /// It asks for the board as it opens. It used to open without asking, and
  /// a board nobody had fetched is indistinguishable from one that could not
  /// be reached -- so the button said the board was away, every time.
  void _showBoard(BuildContext context, WidgetRef ref) {
    unawaited(ref.read(leaderboardControllerProvider.notifier).refresh());
    unawaited(
      showDialog<void>(
        context: context,
        barrierColor: context.tokens.void_.withValues(
          alpha: Tokens.boardBarrierAlpha,
        ),
        // The climb opens from the page, not from the dialog, which is gone
        // by the time it does.
        builder: (context) => _BoardDialog(onPlay: onPlay),
      ),
    );
  }
}

/// The scoreboard on its own: a title, a way out, the board, and a way in to
/// the climb.
class _BoardDialog extends StatelessWidget {
  const _BoardDialog({required this.onPlay});

  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(tokens.space24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Tokens.boardDialogWidth),
        child: InstrumentPanel(
          fill: tokens.surface,
          padding: EdgeInsets.all(tokens.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.courtyardScoreboard,
                      style: context.type.heading,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.courtyardBoardClose,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: tokens.instrumentMid,
                    ),
                  ),
                ],
              ),
              SizedBox(height: tokens.space16),
              const LeaderboardPanel(),
              SizedBox(height: tokens.space24),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: BeaconButton(
                  label: l10n.courtyardPlay,
                  emphasis: ButtonEmphasis.primary,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onPlay();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

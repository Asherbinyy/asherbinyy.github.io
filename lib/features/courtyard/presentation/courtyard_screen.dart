import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';
import 'package:nocturne/core/widgets/even_grid.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';
import 'package:nocturne/features/about/presentation/widgets/interests_grid.dart';
import 'package:nocturne/features/courtyard/game/presentation/ascent_stage.dart';
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
          // Two halves. The climb had the page to itself and used about half
          // of it, which left a large empty right-hand side the owner asked to
          // fill; the second panel is honest about being empty rather than
          // pretending the shelf is full.
          EvenGrid(
            minTileWidth: Tokens.courtyardPanelWidth,
            spacing: tokens.space24,
            children: [
              _GameInvitation(onPlay: () => AscentStage.open(context)),
              const _ComingSoon(),
            ],
          ),
          SizedBox(height: tokens.space48),
          const InterestsGrid(),
        ],
      ),
    );
  }
}

/// The panel that offers the climb, before anyone has asked for it.
class _GameInvitation extends StatelessWidget {
  const _GameInvitation({required this.onPlay});

  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;

    return InstrumentPanel(
      fill: tokens.surface,
      padding: EdgeInsets.all(tokens.space24),
      child: Column(
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
          // Pushes the two controls to the bottom of whichever panel is
          // taller, so they sit on one line across the pair instead of
          // wherever each panel's prose happens to end.
          const Spacer(),
          SizedBox(height: tokens.space16),
          Wrap(
            spacing: tokens.space8,
            runSpacing: tokens.space8,
            children: [
              BeaconButton(
                label: l10n.courtyardPlay,
                emphasis: ButtonEmphasis.primary,
                onPressed: onPlay,
              ),
              BeaconButton(
                label: l10n.courtyardScoreboard,
                onPressed: () => _showBoard(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The board, without having to play first.
  ///
  /// The owner asked for a way to see where things stand from the courtyard.
  /// It is the same panel the climb's results screen uses, so there is one
  /// place that knows how to say "nobody has climbed yet" and one place that
  /// knows how to say the board is unreachable.
  void _showBoard(BuildContext context) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(context.tokens.space24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: DecoratedBox(
              decoration: BoxDecoration(color: context.tokens.surface),
              child: Padding(
                padding: EdgeInsets.all(context.tokens.space16),
                child: const LeaderboardPanel(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The shelf beside the climb, kept honestly empty.
///
/// The owner wants a second game and has not decided what it is. A panel that
/// says so is better than a gap, and much better than inventing a placeholder
/// game to fill it: the courtyard is the one page on this site that is allowed
/// to be unfinished out loud.
class _ComingSoon extends StatelessWidget {
  const _ComingSoon();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;

    return InstrumentPanel(
      padding: EdgeInsets.all(tokens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: tokens.space48,
            height: tokens.hairlineWidth * 2,
            child: ColoredBox(color: tokens.instrumentDim),
          ),
          SizedBox(height: tokens.space12),
          Text(
            l10n.courtyardNextHeading,
            style: type.heading.copyWith(color: tokens.textMuted),
          ),
          SizedBox(height: tokens.space8),
          Text(
            l10n.courtyardNextBody,
            style: type.body.copyWith(color: tokens.textMuted),
          ),
        ],
      ),
    );
  }
}

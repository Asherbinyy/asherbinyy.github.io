import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';
import 'package:nocturne/features/about/presentation/widgets/interests_grid.dart';
import 'package:nocturne/features/courtyard/game/presentation/ascent_stage.dart';

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
          _GameInvitation(onPlay: () => AscentStage.open(context)),
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
          SizedBox(height: tokens.space16),
          BeaconButton(
            label: l10n.courtyardPlay,
            emphasis: ButtonEmphasis.primary,
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}

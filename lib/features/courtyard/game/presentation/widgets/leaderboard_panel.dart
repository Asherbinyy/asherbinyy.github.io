import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_world.dart';
import 'package:nocturne/features/courtyard/game/domain/leaderboard.dart';
import 'package:nocturne/features/courtyard/game/presentation/game_control.dart';
import 'package:nocturne/features/courtyard/game/presentation/leaderboard_controller.dart';

/// The top of the board.
///
/// Four states, and they are not the same state wearing different words.
/// Loading is not empty; an empty board is a real answer meaning nobody has
/// climbed yet; a board that cannot be reached is neither of those and says so
/// with a way to try again; and a board with entries is the only one that shows
/// a number. Collapsing the middle two — the usual shortcut — tells a visitor
/// whose network dropped that they are the first person ever to play.
class LeaderboardPanel extends ConsumerWidget {
  /// Shows at most [limit] places.
  const LeaderboardPanel({this.limit = 5, this.isQuiet = false, super.key});

  /// How many rows to draw.
  ///
  /// Five. The owner asked for five and five is also what a board beside a game
  /// can be: a rail long enough to place yourself in and short enough to read
  /// between two jumps. Ten was a table.
  final int limit;

  /// Whether this is the rail beside the climb rather than a panel in a page.
  ///
  /// The rail sits over the playfield, so it drops the border, the fill and the
  /// footnote about verification and keeps only the names. The same widget
  /// either way, because the four states above have to be got right once.
  final bool isQuiet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;
    final state = ref.watch(leaderboardControllerProvider);
    final controller = ref.read(leaderboardControllerProvider.notifier);

    if (!controller.isAvailable) return const SizedBox.shrink();

    final board = state.board;
    final Widget body;
    if (board == null && state.isLoadingBoard) {
      body = _Note(l10n.ascentChecking);
    } else if (board == null) {
      // The rail says nothing when the board is away. A retry button floating
      // over a game somebody is playing is an errand, and the results screen
      // behind it offers the same button at the moment it is worth pressing.
      if (isQuiet) return const SizedBox.shrink();
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Note(l10n.ascentBoardAway),
          SizedBox(height: tokens.space8),
          GameControl(
            label: l10n.ascentBoardRetry,
            onPressed: controller.refresh,
          ),
        ],
      );
    } else if (board.isEmpty) {
      body = _Note(l10n.ascentBoardEmpty);
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in board.entries.take(limit)) _Row(entry: entry),
        ],
      );
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.ascentBoardTitle,
          style: (isQuiet ? type.telemetry : type.telemetryS).copyWith(
            color: isQuiet ? tokens.beacon : tokens.textMuted,
          ),
        ),
        SizedBox(height: tokens.space12),
        body,
        if (!isQuiet) ...[
          SizedBox(height: tokens.space12),
          // Said on the board itself rather than in a tooltip or a help page.
          // A visitor has no way to know a score was checked unless the page
          // that shows it tells them, and a leaderboard that does not say how
          // its numbers were arrived at is asking to be believed.
          Text(
            l10n.ascentBoardVerified,
            style: type.telemetryS.copyWith(color: tokens.textMuted),
          ),
        ],
      ],
    );

    if (isQuiet) return content;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: tokens.hairline, width: tokens.hairlineWidth),
      ),
      child: Padding(padding: EdgeInsets.all(tokens.space16), child: content),
    );
  }
}

/// One place on the board.
class _Row extends StatelessWidget {
  const _Row({required this.entry});

  final BoardEntry entry;

  /// What the first three places are marked with.
  ///
  /// The owner asked for an emoji on the top three and the medals are the
  /// obvious ones, but they are doing a job beyond decoration: the rail is read
  /// in the corner of an eye during a climb, and three coloured discs are
  /// findable at a glance in a way that "1", "2", "3" in the site's telemetry
  /// face are not. Everything below third gets its number, because a board of
  /// eight identical medals marks nothing.
  static const List<String> _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final isTop = entry.rank <= _medals.length;
    final medal = isTop ? _medals[entry.rank - 1] : null;
    final isKing = entry.metres >= AscentWorld.summit;

    // One string for the whole row. A screen reader reading "3", "Nour", "140"
    // as three unrelated stops is a table read aloud as a pile of numbers. The
    // medal is not announced: it says the same thing the rank already did.
    return Semantics(
      label:
          '${entry.rank}. ${entry.nickname}, ${entry.metres} m'
          '${isKing ? ', ${context.l10n.ascentKing}' : ''}',
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.space4),
        child: Row(
          children: [
            SizedBox(
              width: tokens.space24,
              child: Text(
                medal ?? '${entry.rank}',
                style: type.telemetryS.copyWith(
                  color: entry.rank == 1 ? tokens.beacon : tokens.textMuted,
                ),
              ),
            ),
            Expanded(
              child: Text(
                entry.nickname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: type.body.copyWith(
                  color: isTop ? tokens.beacon : tokens.textPrimary,
                ),
              ),
            ),
            // A climber who reached the summit is crowned on the board. The
            // height says it already; the title is the reward the owner asked
            // for, and it is earned from the verified height, not claimed.
            if (isKing) ...[
              SizedBox(width: tokens.space8),
              Text(
                '👑 ${context.l10n.ascentKing}',
                style: type.telemetryS.copyWith(color: tokens.beacon),
              ),
            ],
            SizedBox(width: tokens.space8),
            Text(
              '${entry.metres} m',
              style: type.telemetryS.copyWith(
                color: isTop ? tokens.beacon : tokens.instrument,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: context.type.body.copyWith(color: context.tokens.textMuted),
  );
}

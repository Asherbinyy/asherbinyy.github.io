import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
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
  const LeaderboardPanel({this.limit = 10, super.key});

  /// How many rows to draw. Five beside the climb, ten where there is room.
  final int limit;

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
          for (final entry in board.entries.take(limit))
            _Row(entry: entry, isTop: entry.rank == 1),
        ],
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: tokens.hairline, width: tokens.hairlineWidth),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.ascentBoardTitle,
              style: type.telemetryS.copyWith(color: tokens.textMuted),
            ),
            SizedBox(height: tokens.space12),
            body,
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
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.entry, required this.isTop});

  final BoardEntry entry;
  final bool isTop;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    // One string for the whole row. A screen reader reading "3", "Nour", "140"
    // as three unrelated stops is a table read aloud as a pile of numbers.
    return Semantics(
      label: '${entry.rank}. ${entry.nickname}, ${entry.metres} m',
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.space4),
        child: Row(
          children: [
            SizedBox(
              width: tokens.space24,
              child: Text(
                '${entry.rank}',
                style: type.telemetryS.copyWith(
                  color: isTop ? tokens.beacon : tokens.textMuted,
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

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
import 'package:nocturne/core/widgets/loading/station_card.dart';

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

/// One interest: its procedural mark, its name, and the specific he named.
///
/// Deliberately not focusable and not tappable. There is nowhere for a tile to
/// go, so putting it in the tab order would add six stops a keyboard user has
/// to pass through to reach the contact links, in exchange for an emphasis
/// they cannot see the point of. Hover is decoration for pointer users; every
/// word is on screen without it.
class _Tile extends StatefulWidget {
  const _Tile({required this.interest});

  final Interest interest;

  /// Declared, never inferred. Narrower than a work card: these are labels,
  /// not case studies, and four fit a desktop row where three cards would.
  static const double width = 168;

  /// The mark's height. Square would read as an avatar; this reads as a plate.
  static const double artHeight = 104;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _isHovered = false;

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
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: ExcludeSemantics(
          child: SizedBox(
            width: _Tile.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _Plate(interest: widget.interest, isActive: _isHovered),
                SizedBox(height: tokens.space8),
                Text(
                  label,
                  style: type.body.copyWith(
                    color: _isHovered ? tokens.beacon : tokens.textPrimary,
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
    );
  }
}

/// The mark, with an edge that answers a pointer.
///
/// The art is the same deterministic constellation the work grid and the
/// writing index draw, seeded from the interest's own id — so each is distinct,
/// stable across builds, drawn in the site's own vocabulary, and costs no
/// image asset. Reusing it here is what keeps this section part of the site
/// rather than a scrapbook pasted into it.
class _Plate extends StatelessWidget {
  const _Plate({required this.interest, required this.isActive});

  final Interest interest;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return AnimatedContainer(
      // The one thing motion does here is confirm the pointer found the tile.
      duration: ReducedMotion.duration(context, Motion.quick),
      curve: MotionCurves.emphasized,
      decoration: BoxDecoration(
        border: Border.all(
          color: isActive ? tokens.beacon : tokens.hairline,
          width: tokens.hairlineWidth,
        ),
      ),
      child: StationCard(
        seedId: interest.id,
        name: interest.label.en,
        width: _Tile.width,
        height: _Tile.artHeight,
      ),
    );
  }
}

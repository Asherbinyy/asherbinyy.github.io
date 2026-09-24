import 'package:material_ui/material_ui.dart';

import 'package:go_router/go_router.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';
import 'package:nocturne/features/about/presentation/widgets/live_climb.dart';

/// The way through to `/courtyard` from the foot of the credentials.
///
/// The owner found the first two versions of this less appealing than
/// everything around them: a sentence and a button, then a grid of small
/// stills. So the door shows what is through it, moving: the game itself,
/// climbing on its own, beside the words. The interest scenes that sat under
/// the words went at the owner's next review; the card is smaller for it. The
/// button is the way in for a keyboard.
class CourtyardDoor extends StatelessWidget {
  /// Draws the door.
  const CourtyardDoor({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;
    void enter() => context.goNamed(AppRoute.courtyard.name);

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
        BeaconButton(
          label: l10n.aboutOffDuty,
          emphasis: ButtonEmphasis.primary,
          onPressed: enter,
        ),
      ],
    );

    Widget climb(double height) => MouseRegion(
      cursor: context.platform.isPointer
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      child: GestureDetector(
        onTap: enter,
        child: LiveClimb(height: height),
      ),
    );

    return SizedBox(
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
            // The climb held in from the edge rather than flush against it.
            return Row(
              children: [
                Expanded(child: words),
                SizedBox(width: tokens.space32),
                SizedBox(
                  width: Tokens.doorClimbWidth,
                  child: climb(Tokens.doorClimbHeight),
                ),
                const SizedBox(width: Tokens.doorClimbInset),
              ],
            );
          },
        ),
      ),
    );
  }
}

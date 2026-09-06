import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';

/// The 4:5 portrait slot from the screen spec.
///
/// **`profile.portrait` is null and no image file exists in the repository.**
/// The brief for the shot is in `01-DESIGN-SYSTEM.md` §10 and taking it is the
/// owner's job, so this reserves the exact geometry and says plainly that the
/// frame is empty — rather than shipping a stock face, an avatar initial, or a
/// silhouette a viewer might mistake for the person.
///
/// When the portrait arrives this becomes a `ThreeStageImage` at these same
/// dimensions, so nothing around it moves. It is a `StatelessWidget` with no
/// provider read on purpose: there is exactly one state to render today, and a
/// branch on a field that is always null would be dead code pretending to be
/// a feature.
class PortraitFrame extends StatelessWidget {
  /// Reserves the portrait's slot.
  const PortraitFrame({super.key});

  /// Declared, never inferred — the 4:5 ratio the spec asks for.
  static const double width = 280;

  /// Height at 4:5.
  static const double height = 350;

  @override
  Widget build(BuildContext context) => InstrumentPanel(
    child: SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(context.tokens.space16),
          child: Text(
            context.l10n.aboutPortraitPending,
            textAlign: TextAlign.center,
            style: context.type.telemetryS.copyWith(
              color: context.tokens.textMuted,
            ),
          ),
        ),
      ),
    ),
  );
}

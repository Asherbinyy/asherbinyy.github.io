import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/platform/platform_service.dart';

/// The 48px footer, carrying the coordinate readout.
///
/// Screen spec: the viewer's resolved coarse location if consented, otherwise
/// Manchester. Consent does not exist until task 1.10, so this always shows
/// the fallback — which is the truthful reading, not a placeholder.
class AppFooter extends StatelessWidget {
  /// [coordinate] is the already-formatted readout, or null until the content
  /// layer is wired into the app in task 1.6.
  const AppFooter({this.coordinate, super.key});

  /// The monospace coordinate string shown at the trailing edge.
  final String? coordinate;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final readout = coordinate;

    final hasRoomForReadout =
        context.platform.viewport.index >= ViewportClass.medium.index;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.void_,
        border: Border(
          top: BorderSide(color: tokens.hairline, width: tokens.hairlineWidth),
        ),
      ),
      child: SizedBox(
        height: tokens.footerHeight,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: context.platform.gutter,
          ),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  l10n.footerLocation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.meta,
                ),
              ),

              // Only pushes the readout to the far edge. Without one there is
              // nothing to push, and an expanding Spacer would compete with
              // the location text for the space it needs to ellipsize into.
              if (readout != null && hasRoomForReadout) const Spacer(),
              // The one place the concept winks. Quiet, muted, monospace.
              // Omitted rather than faked while the reading is unavailable,
              // and dropped entirely on a phone: the footer is one 48px row,
              // and when it runs out of room a decorative flourish yields
              // before a navigational link does.
              if (readout != null && hasRoomForReadout)
                Text(
                  readout,
                  maxLines: 1,
                  style: context.type.telemetryS.copyWith(
                    color: tokens.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

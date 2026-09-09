import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/app_origin.dart';
import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/core/widgets/loading/station_card.dart';
import 'package:nocturne/features/work/presentation/widgets/store_links.dart';

/// One shipped application, as a visual card.
///
/// The screen spec argued for a ledger over a card grid, and its reason was
/// specific: cards would put "twelve identical rounded rectangles on screen"
/// and lose the fact that these are shipped products with store links.
///
/// Both halves of that objection are answered here rather than ignored. The
/// artwork is `StationCard`, which is seeded from the application id and draws
/// the propagation map's own node vocabulary — so no two cards are alike, and
/// an application with a recorded country places its node where the country
/// is. And the store links stay as their own explicit, separately focusable
/// controls rather than being folded into the card's tap target, so what the
/// page is *for* is still the most actionable thing on it.
///
/// There is deliberately no decorative hover on the card body. The design
/// system says motion answers actions, and a card that lights up without
/// offering anything to press is motion answering nothing. The interaction
/// lives where the actions are: each store link hovers, takes focus and shows
/// a focus ring.
class WorkCard extends StatelessWidget {
  /// [origin] carries the country and coordinates when the content records one.
  const WorkCard({
    required this.app,
    required this.domainLabel,
    required this.origin,
    super.key,
  });

  /// The application this card stands for.
  final ShippedApp app;

  /// Localised domain name.
  final String domainLabel;

  /// Where the work happened, when the content records it.
  final AppOrigin? origin;

  /// Declared, never inferred. Wide enough for the name at display-m.
  static const double width = 280;

  /// The artwork's height. Above `StationCard`'s derived labelling threshold,
  /// so the card carries the application's name itself at display-m rather
  /// than repeating it underneath.
  static const double artHeight = 160;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final metric = app.metric;
    final role = app.role?.resolve(context.channel);

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // Fills the height its row was given, so the store links below can be
        // pushed to a common baseline instead of floating wherever the role
        // text happens to end.
        children: [
          StationCard(
            seedId: app.id,
            name: app.name,
            width: width,
            height: artHeight,
            domainLabel: domainLabel,
            country: origin?.country,
            latitude: origin?.latitude,
            longitude: origin?.longitude,
          ),
          if (role != null) ...[
            SizedBox(height: tokens.space12),
            Text(role, style: type.bodyS.copyWith(color: tokens.textSecondary)),
          ],
          if (metric != null) ...[
            SizedBox(height: tokens.space8),
            // The strongest single string a card can carry, so it gets the
            // instrument treatment rather than being another line of prose.
            Text(
              metric,
              style: type.telemetry.copyWith(color: tokens.instrument),
            ),
          ],
          // Whatever height is left over goes here, above the links, so the
          // one actionable row on the card is level across the whole grid.
          const Spacer(),
          SizedBox(height: tokens.space12),
          StoreLinks(app: app),
        ],
      ),
    );
  }
}

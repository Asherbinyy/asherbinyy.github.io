import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/painting/station_card_painter.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';

/// A procedural card for an application that has no screenshot yet.
///
/// Section 11: the wrong answer is a grey box with a mountain icon, which looks
/// like a bug and reads as an incomplete portfolio. This draws the propagation
/// map's own node vocabulary at card scale, seeded from the application id so
/// a given application always renders the same card.
///
/// Presentation only — it takes resolved strings rather than content models, so
/// the work grid decides what a domain or a country is called and this widget
/// never has to change when the content does.
class StationCard extends StatelessWidget {
  /// [seedId] must be the application id; [country] and the coordinates are
  /// absent whenever the content does not record where the work happened.
  const StationCard({
    required this.seedId,
    required this.name,
    required this.width,
    required this.height,
    this.domainLabel,
    this.country,
    this.latitude,
    this.longitude,
    super.key,
  });

  /// Stable identifier driving the deterministic layout.
  final String seedId;

  /// Application name, rendered at display-m.
  final String name;

  /// Exact card width.
  final double width;

  /// Exact card height.
  final double height;

  /// Localised domain label, omitted when unknown.
  final String? domainLabel;

  /// Country code, omitted when the content does not record one.
  final String? country;

  /// Latitude of the country, when recorded.
  final double? latitude;

  /// Longitude of the country, when recorded.
  final double? longitude;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    // Locals so the null checks promote; the standards ban the bang operator.
    final domain = domainLabel;
    final origin = country;
    final telemetry = [if (domain != null) domain, if (origin != null) origin];

    return SizedBox(
      width: width,
      height: height,
      child: InstrumentPanel(
        fill: tokens.surface,
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: CustomPaint(
                painter: StationCardPainter(
                  seedId: seedId,
                  nodeColour: tokens.instrumentDim,
                  beaconColour: tokens.beacon,
                  linkColour: tokens.hairlineStrong,
                  hairlineWidth: tokens.hairlineWidth,
                  latitude: latitude,
                  longitude: longitude,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(tokens.space16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: type.displayM,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (telemetry.isNotEmpty)
                    Wrap(
                      spacing: tokens.space8,
                      children: [
                        for (final value in telemetry)
                          Text(value, style: type.telemetryS),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

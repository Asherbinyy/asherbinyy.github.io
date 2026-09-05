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

  /// The smallest card that can carry its own label.
  ///
  /// One line of display-m plus one of telemetry-s, plus the padding either
  /// side. Derived rather than guessed, so a change to the type scale cannot
  /// leave a card overflowing.
  static double _minimumLabelledHeight(NocturneTypography type) =>
      (type.displayM.fontSize ?? Tokens.displayMMin) *
          (type.displayM.height ?? Tokens.displayMHeight) +
      (type.telemetryS.fontSize ?? Tokens.telemetrySSize) *
          (type.telemetryS.height ?? Tokens.telemetryHeight) +
      Tokens.space16 * 2;

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
            // A thumbnail is too small for display-m to be legible, let alone
            // to fit. Below that the constellation stands alone — the name is
            // already beside it wherever a card this size is used.
            if (height >= _minimumLabelledHeight(type))
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

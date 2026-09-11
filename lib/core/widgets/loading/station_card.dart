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

  /// How many lines of the name the label will draw.
  ///
  /// Must agree with the `maxLines` on that `Text`, which is the whole point:
  /// they disagreed until milestone 4. The threshold below reserved one line
  /// while the label permitted two, so any card tall enough to be labelled but
  /// shorter than two lines overflowed the moment a name wrapped. The interests
  /// grid found it at 104px, overflowing by exactly the missing line.
  static const int _maximumLabelLines = 2;

  /// The smallest card that can carry its own label.
  ///
  /// Every line of display-m the label may draw, plus one of telemetry-s, plus
  /// the padding either side. Derived rather than guessed, so a change to the
  /// type scale cannot leave a card overflowing.
  static double _minimumLabelledHeight(NocturneTypography type) =>
      (type.displayM.fontSize ?? Tokens.displayMMin) *
          (type.displayM.height ?? Tokens.displayMHeight) *
          _maximumLabelLines +
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
    // The sector moved to a badge over the artwork, so it is no longer
    // repeated in the line underneath.
    final telemetry = [if (origin != null) origin];

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
            // The sector, as a badge in the corner of the artwork.
            //
            // It used to be small text on the same line as the country at the
            // bottom of the card, where it read as metadata about the picture
            // rather than as a label on the thing. A recruiter scanning a grid
            // of fourteen wants to know what each one *is* before anything
            // else, so it sits on the image.
            if (domain != null && height >= _minimumLabelledHeight(type))
              PositionedDirectional(
                top: tokens.space12,
                start: tokens.space12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    // Over the page colour rather than the artwork's, so the
                    // badge stays legible wherever the constellation happens
                    // to fall behind it.
                    color: tokens.surface.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(tokens.tagRadius),
                    border: Border.all(
                      color: tokens.hairlineStrong,
                      width: tokens.hairlineWidth,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.space8,
                      vertical: tokens.space4,
                    ),
                    child: Text(
                      domain,
                      style: type.meta.copyWith(color: tokens.beacon),
                    ),
                  ),
                ),
              ),
            // A thumbnail is too small for display-m to be legible, let alone
            // to fit. Below that the constellation stands alone, and the name
            // is already beside it wherever a card this size is used.
            //
            // An empty name is also a caller saying it prints the name itself,
            // which the article card does: drawing it here as well put the
            // headline on the card twice.
            if (name.isNotEmpty && height >= _minimumLabelledHeight(type))
              Padding(
                padding: EdgeInsets.all(tokens.space16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: type.displayM,
                      maxLines: _maximumLabelLines,
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

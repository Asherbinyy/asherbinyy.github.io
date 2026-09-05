import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';

/// A measured value in the monospace face.
///
/// Design-system section 3 reserves Plex Mono for numerals, coordinates,
/// timestamps and live values, and warns it must not leak into general small
/// labels. Routing every such value through one widget is what keeps that
/// boundary visible.
class TelemetryValue extends StatelessWidget {
  /// [isLarge] picks the 13px scale over the 11px one.
  const TelemetryValue({
    required this.value,
    this.colour,
    this.isLarge = true,
    super.key,
  });

  /// The reading itself.
  final String value;

  /// Overrides the instrument colour where a state calls for it.
  final Color? colour;

  /// Whether to use the larger telemetry scale.
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final style = isLarge ? type.telemetry : type.telemetryS;
    return Text(
      value,
      maxLines: 1,
      style: colour == null ? style : style.copyWith(color: colour),
    );
  }
}

/// A large numeral for the hero's instrument panels.
///
/// The screen spec puts mono numerals in the stat panels and calls them the
/// fastest thing on the page to read, so they take the display scale rather
/// than the telemetry one while keeping the monospace face and tabular figures.
class TelemetryNumeral extends StatelessWidget {
  /// [value] is a string so "25+" is as expressible as "25".
  const TelemetryNumeral({required this.value, super.key});

  /// The numeral.
  final String value;

  @override
  Widget build(BuildContext context) => Text(
    value,
    maxLines: 1,
    style: context.type.displayM.copyWith(
      fontFamily: Tokens.telemetryFamily,
      color: context.tokens.instrument,
    ),
  );
}

import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';

/// The complete type scale, calculated from available viewport width.
class NocturneTypography {
  /// Keeps Arabic metrics independent of widget directionality.
  const NocturneTypography({
    required this.tokens,
    required this.viewportWidth,
    this.isArabic = false,
  });

  /// Active theme palette.
  final ThemeTokens tokens;

  /// Width supplied by the app's LayoutBuilder, in logical pixels.
  final double viewportWidth;

  /// Whether Arabic ascenders and descenders need extra line height.
  final bool isArabic;

  TextStyle _style(
    double size,
    double height, {
    String? family,
    FontWeight weight = Tokens.weightRegular,
    double tracking = Tokens.zero,
    Color? color,
  }) => TextStyle(
    fontFamily: family ?? (isArabic ? Tokens.arabicFamily : Tokens.bodyFamily),
    fontFamilyFallback: const [Tokens.arabicFamily],
    fontSize: size,
    height: height + (isArabic ? Tokens.arabicHeightIncrease : Tokens.zero),
    letterSpacing: size * tracking,
    fontWeight: weight,
    color: color ?? tokens.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Largest display style, matching clamp(48px, 9vw, 112px).
  TextStyle get displayXl => _style(
    (viewportWidth * Tokens.displayXlViewportFactor).clamp(
      Tokens.displayXlMin,
      Tokens.displayXlMax,
    ),
    Tokens.displayXlHeight,
    family: Tokens.displayFamily,
    weight: Tokens.weightBold,
    tracking: Tokens.displayXlTracking,
  );

  /// Large display style.
  TextStyle get displayL => _style(
    (viewportWidth * Tokens.displayLViewportFactor).clamp(
      Tokens.displayLMin,
      Tokens.displayLMax,
    ),
    Tokens.displayLHeight,
    family: Tokens.displayFamily,
    weight: Tokens.weightBold,
    tracking: Tokens.displayLTracking,
  );

  /// Medium display style.
  TextStyle get displayM => _style(
    (viewportWidth * Tokens.displayMViewportFactor).clamp(
      Tokens.displayMMin,
      Tokens.displayMMax,
    ),
    Tokens.displayMHeight,
    family: Tokens.displayFamily,
    weight: Tokens.weightMedium,
    tracking: Tokens.displayMTracking,
  );

  /// Section heading.
  TextStyle get heading => _style(
    Tokens.headingSize,
    Tokens.headingHeight,
    family: Tokens.displayFamily,
    weight: Tokens.weightMedium,
  );

  /// Large body text.
  TextStyle get bodyL => _style(Tokens.bodyLSize, Tokens.bodyHeight);

  /// Standard body text.
  TextStyle get body => _style(Tokens.bodySize, Tokens.bodyHeight);

  /// Small body text.
  TextStyle get bodyS => _style(Tokens.bodySSize, Tokens.bodySHeight);

  /// Metadata is deliberately proportional, never monospace.
  TextStyle get meta => _style(
    Tokens.metaSize,
    Tokens.metaHeight,
    weight: Tokens.weightMedium,
    color: tokens.textMuted,
  );

  /// Changing numeric readouts.
  TextStyle get telemetry => _style(
    Tokens.telemetrySize,
    Tokens.telemetryHeight,
    family: Tokens.telemetryFamily,
    color: tokens.instrument,
  );

  /// Small numeric readouts.
  TextStyle get telemetryS => _style(
    Tokens.telemetrySSize,
    Tokens.telemetryHeight,
    family: Tokens.telemetryFamily,
    color: tokens.instrument,
  );

  /// Maps Material semantic slots onto the existing scale only.
  TextTheme get textTheme => TextTheme(
    displayLarge: displayXl,
    displayMedium: displayL,
    displaySmall: displayM,
    headlineLarge: heading,
    headlineMedium: heading,
    headlineSmall: heading,
    titleLarge: heading,
    titleMedium: bodyL,
    titleSmall: body,
    bodyLarge: bodyL,
    bodyMedium: body,
    bodySmall: bodyS,
    labelLarge: body,
    labelMedium: meta,
    labelSmall: meta,
  );
}

import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';

/// Constructs both artifacts from explicit palette roles, without seed colors.
abstract final class ThemeFactory {
  /// All Material slots resolve to existing design-system colors.
  static ThemeData create({
    required ThemeTokens tokens,
    required Brightness brightness,
    required double viewportWidth,
    bool isArabic = false,
  }) {
    final typography = NocturneTypography(
      tokens: tokens,
      viewportWidth: viewportWidth,
      isArabic: isArabic,
    );
    final scheme = ColorScheme(
      brightness: brightness,
      primary: tokens.beacon,
      onPrimary: tokens.void_,
      primaryContainer: tokens.surfaceRaised,
      onPrimaryContainer: tokens.beacon,
      primaryFixed: tokens.beacon,
      primaryFixedDim: tokens.beaconDim,
      onPrimaryFixed: tokens.void_,
      onPrimaryFixedVariant: tokens.textPrimary,
      secondary: tokens.instrument,
      onSecondary: tokens.void_,
      secondaryContainer: tokens.surfaceRaised,
      onSecondaryContainer: tokens.instrument,
      secondaryFixed: tokens.instrument,
      secondaryFixedDim: tokens.instrumentMid,
      onSecondaryFixed: tokens.void_,
      onSecondaryFixedVariant: tokens.textPrimary,
      tertiary: tokens.instrumentMid,
      onTertiary: tokens.void_,
      tertiaryContainer: tokens.surfaceRaised,
      onTertiaryContainer: tokens.instrumentMid,
      tertiaryFixed: tokens.instrument,
      tertiaryFixedDim: tokens.instrumentDim,
      onTertiaryFixed: tokens.void_,
      onTertiaryFixedVariant: tokens.textPrimary,
      error: tokens.alert,
      onError: tokens.void_,
      errorContainer: tokens.surfaceRaised,
      onErrorContainer: tokens.alert,
      surface: tokens.surface,
      onSurface: tokens.textPrimary,
      surfaceDim: tokens.void_,
      surfaceBright: tokens.surfaceRaised,
      surfaceContainerLowest: tokens.void_,
      surfaceContainerLow: tokens.surface,
      surfaceContainer: tokens.surface,
      surfaceContainerHigh: tokens.surfaceRaised,
      surfaceContainerHighest: tokens.surfaceRaised,
      onSurfaceVariant: tokens.textSecondary,
      outline: tokens.hairline,
      outlineVariant: tokens.hairlineStrong,
      shadow: tokens.void_,
      scrim: tokens.void_,
      inverseSurface: tokens.textPrimary,
      onInverseSurface: tokens.void_,
      inversePrimary: tokens.beacon,
      surfaceTint: tokens.surface,
    );
    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.void_,
      canvasColor: tokens.void_,
      cardColor: tokens.surface,
      dividerColor: tokens.hairline,
      disabledColor: tokens.textMuted,
      focusColor: tokens.beacon,
      hoverColor: tokens.surfaceRaised,
      highlightColor: tokens.surfaceRaised,
      splashFactory: NoSplash.splashFactory,
      textTheme: typography.textTheme,
      primaryTextTheme: typography.textTheme,
      fontFamily: isArabic ? Tokens.arabicFamily : Tokens.bodyFamily,
      extensions: [tokens],
      tooltipTheme: const TooltipThemeData(waitDuration: Tokens.tooltipDelay),
    );
  }
}

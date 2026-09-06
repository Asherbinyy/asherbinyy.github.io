import 'dart:ui' show FontFeature;

import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';

void main() {
  test('fluid display styles clamp at the documented limits', () {
    const narrow = NocturneTypography(
      tokens: nocturneTokens,
      viewportWidth: Tokens.compactGutter,
    );
    const wide = NocturneTypography(
      tokens: nocturneTokens,
      viewportWidth: Tokens.largeContentWidth * 2,
    );

    expect(narrow.displayXl.fontSize, Tokens.displayXlMin);
    expect(narrow.displayL.fontSize, Tokens.displayLMin);
    expect(narrow.displayM.fontSize, Tokens.displayMMin);
    expect(wide.displayXl.fontSize, Tokens.displayXlMax);
    expect(wide.displayL.fontSize, Tokens.displayLMax);
    expect(wide.displayM.fontSize, Tokens.displayMMax);
  });

  test('fluid size and em tracking are computed from viewport width', () {
    const type = NocturneTypography(
      tokens: nocturneTokens,
      viewportWidth: Tokens.expandedBreakpoint,
    );

    expect(
      type.displayXl.fontSize,
      Tokens.expandedBreakpoint * Tokens.displayXlViewportFactor,
    );
    expect(
      type.displayXl.letterSpacing,
      Tokens.expandedBreakpoint *
          Tokens.displayXlViewportFactor *
          Tokens.displayXlTracking,
    );
  });

  test(
    'all ten Arabic styles add line height and preserve tabular figures',
    () {
      const latin = NocturneTypography(
        tokens: nocturneTokens,
        viewportWidth: Tokens.expandedBreakpoint,
      );
      const arabic = NocturneTypography(
        tokens: nocturneTokens,
        viewportWidth: Tokens.expandedBreakpoint,
        isArabic: true,
      );
      final latinStyles = [
        latin.displayXl,
        latin.displayL,
        latin.displayM,
        latin.heading,
        latin.bodyL,
        latin.body,
        latin.bodyS,
        latin.meta,
        latin.telemetry,
        latin.telemetryS,
      ];
      final arabicStyles = [
        arabic.displayXl,
        arabic.displayL,
        arabic.displayM,
        arabic.heading,
        arabic.bodyL,
        arabic.body,
        arabic.bodyS,
        arabic.meta,
        arabic.telemetry,
        arabic.telemetryS,
      ];

      for (var index = 0; index < latinStyles.length; index++) {
        final height = latinStyles[index].height;
        if (height == null) {
          fail('Every specified text style requires line height.');
        }
        expect(
          arabicStyles[index].height,
          height + Tokens.arabicHeightIncrease,
        );
        expect(arabicStyles[index].fontSize, latinStyles[index].fontSize);
        expect(
          arabicStyles[index].fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
        expect(
          latinStyles[index].fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
      }
      expect(arabic.body.fontFamily, Tokens.arabicFamily);
      expect(latin.meta.fontFamily, Tokens.bodyFamily);
      expect(latin.telemetry.fontFamily, Tokens.telemetryFamily);
    },
  );
}

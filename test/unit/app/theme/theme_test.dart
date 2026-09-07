import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nocturne/app/theme/daybreak_theme.dart';
import 'package:nocturne/app/theme/nocturne_theme.dart';
import 'package:nocturne/app/theme/tokens.dart';

void main() {
  group('ThemeTokens', () {
    test(
      'nocturneTokens exposes valid non-null semantic colors and weights',
      () {
        expect(nocturneTokens.void_, const Color(0xFF121826));
        expect(nocturneTokens.surface, const Color(0xFF1A2233));
        expect(nocturneTokens.surfaceRaised, const Color(0xFF232D40));
        expect(nocturneTokens.hairline, const Color(0xFF2E3A50));
        expect(nocturneTokens.hairlineStrong, const Color(0xFF3F4D66));
        expect(nocturneTokens.beacon, const Color(0xFFE3A93F));
        expect(nocturneTokens.beaconDim, const Color(0xFF92702E));
        expect(nocturneTokens.beaconGlow, const Color(0xFFFFD98A));
        expect(nocturneTokens.faience, const Color(0xFF45B8B2));
        expect(nocturneTokens.faienceDim, const Color(0xFF2D827D));
        expect(nocturneTokens.instrument, const Color(0xFFCBD6E6));
        expect(nocturneTokens.instrumentMid, const Color(0xFF93A2B8));
        expect(nocturneTokens.instrumentDim, const Color(0xFF69788F));
        expect(nocturneTokens.alert, const Color(0xFFE3716C));
        expect(nocturneTokens.verified, const Color(0xFFCBD6E6));
        expect(nocturneTokens.textPrimary, const Color(0xFFEDF1F8));
        expect(nocturneTokens.textSecondary, const Color(0xFFA8B4C6));
        expect(nocturneTokens.textMuted, const Color(0xFF8895A8));

        expect(nocturneTokens.weightRegular, Tokens.weightRegular);
        expect(nocturneTokens.weightMedium, Tokens.weightMedium);
        expect(nocturneTokens.weightSemibold, Tokens.weightSemibold);
        expect(nocturneTokens.weightBold, Tokens.weightBold);
      },
    );

    test('daybreakTokens exposes valid non-null semantic colors', () {
      expect(daybreakTokens.void_, const Color(0xFFF2E9D8));
      expect(daybreakTokens.surface, const Color(0xFFE9DEC8));
      expect(daybreakTokens.surfaceRaised, const Color(0xFFFCF7EC));
      expect(daybreakTokens.hairline, const Color(0xFFD6C8AC));
      expect(daybreakTokens.hairlineStrong, const Color(0xFFAD9C7C));
      expect(daybreakTokens.beacon, const Color(0xFF885912));
      expect(daybreakTokens.beaconDim, const Color(0xFF9C7534));
      expect(daybreakTokens.beaconGlow, const Color(0xFF6F4409));
      expect(daybreakTokens.faience, const Color(0xFF1C6B68));
      expect(daybreakTokens.faienceDim, const Color(0xFF2E8481));
      expect(daybreakTokens.instrument, const Color(0xFF37424F));
      expect(daybreakTokens.instrumentMid, const Color(0xFF586472));
      expect(daybreakTokens.instrumentDim, const Color(0xFF8A7C63));
      expect(daybreakTokens.alert, const Color(0xFF9C2E26));
      expect(daybreakTokens.verified, const Color(0xFF37424F));
      expect(daybreakTokens.textPrimary, const Color(0xFF13181F));
      expect(daybreakTokens.textSecondary, const Color(0xFF48545F));
      expect(daybreakTokens.textMuted, const Color(0xFF5A6470));
    });

    test('copyWith retains original values when fields are null', () {
      final copied = nocturneTokens.copyWith();
      expect(copied.void_, nocturneTokens.void_);
      expect(copied.surface, nocturneTokens.surface);
      expect(copied.beacon, nocturneTokens.beacon);
      expect(copied.textPrimary, nocturneTokens.textPrimary);
    });

    test('copyWith updates specified color values', () {
      final updated = nocturneTokens.copyWith(
        void_: daybreakTokens.void_,
        beacon: daybreakTokens.beacon,
      );
      expect(updated.void_, daybreakTokens.void_);
      expect(updated.beacon, daybreakTokens.beacon);
      expect(updated.surface, nocturneTokens.surface);
    });

    test('lerp interpolates between two ThemeTokens', () {
      final midway = nocturneTokens.lerp(daybreakTokens, 0.5);
      expect(midway.void_, isNot(nocturneTokens.void_));
      expect(midway.void_, isNot(daybreakTokens.void_));

      final start = nocturneTokens.lerp(null, 0.5);
      expect(start.void_, nocturneTokens.void_);
    });

    test(
      'shared measurements through ThemeTokenValues match static Tokens',
      () {
        expect(nocturneTokens.noMotion, Tokens.noMotion);
        expect(nocturneTokens.zero, Tokens.zero);
        expect(nocturneTokens.grainOpacity, Tokens.grainOpacity);
        expect(nocturneTokens.amberCoverageLimit, Tokens.amberCoverageLimit);
        expect(nocturneTokens.space4, Tokens.space4);
        expect(nocturneTokens.space8, Tokens.space8);
        expect(nocturneTokens.space12, Tokens.space12);
        expect(nocturneTokens.space16, Tokens.space16);
        expect(nocturneTokens.space24, Tokens.space24);
        expect(nocturneTokens.space32, Tokens.space32);
        expect(nocturneTokens.space48, Tokens.space48);
        expect(nocturneTokens.space64, Tokens.space64);
        expect(nocturneTokens.space96, Tokens.space96);
        expect(nocturneTokens.space128, Tokens.space128);
        expect(nocturneTokens.gridUnit, Tokens.gridUnit);
        expect(nocturneTokens.mediumBreakpoint, Tokens.mediumBreakpoint);
        expect(nocturneTokens.expandedBreakpoint, Tokens.expandedBreakpoint);
        expect(nocturneTokens.largeBreakpoint, Tokens.largeBreakpoint);
        expect(nocturneTokens.compactGutter, Tokens.compactGutter);
        expect(nocturneTokens.mediumGutter, Tokens.mediumGutter);
        expect(nocturneTokens.expandedGutter, Tokens.expandedGutter);
        expect(nocturneTokens.largeGutter, Tokens.largeGutter);
        expect(
          nocturneTokens.expandedContentWidth,
          Tokens.expandedContentWidth,
        );
        expect(nocturneTokens.largeContentWidth, Tokens.largeContentWidth);
        expect(nocturneTokens.expandedColumns, Tokens.expandedColumns);
        expect(nocturneTokens.panelRadius, Tokens.panelRadius);
        expect(nocturneTokens.tagRadius, Tokens.tagRadius);
        expect(nocturneTokens.controlRadius, Tokens.controlRadius);
        expect(nocturneTokens.modalRadius, Tokens.modalRadius);
        expect(nocturneTokens.hairlineWidth, Tokens.hairlineWidth);
        expect(nocturneTokens.cornerTickLength, Tokens.cornerTickLength);
        expect(nocturneTokens.cornerTickOffset, Tokens.cornerTickOffset);
        expect(nocturneTokens.instant, Tokens.instant);
        expect(nocturneTokens.quick, Tokens.quick);
        expect(nocturneTokens.standard, Tokens.standard);
        expect(nocturneTokens.considered, Tokens.considered);
        expect(nocturneTokens.sequence, Tokens.sequence);
        expect(nocturneTokens.reducedAcquisition, Tokens.reducedAcquisition);
        expect(nocturneTokens.emphasized, Tokens.emphasized);
        expect(nocturneTokens.exit, Tokens.exit);
        expect(nocturneTokens.linear, Tokens.linear);
        expect(nocturneTokens.spring, Tokens.spring);
        expect(nocturneTokens.touchTarget, Tokens.touchTarget);
        expect(nocturneTokens.pointerTarget, Tokens.pointerTarget);
        expect(nocturneTokens.messageLifetime, Tokens.messageLifetime);
        expect(nocturneTokens.tooltipDelay, Tokens.tooltipDelay);
        expect(nocturneTokens.sweep, Tokens.sweep);
        expect(nocturneTokens.imageResolve, Tokens.imageResolve);
      },
    );

    test('NocturneTheme and DaybreakTheme construct valid ThemeData', () {
      final nocturne = NocturneTheme.create(viewportWidth: 1024);
      final daybreak = DaybreakTheme.create(viewportWidth: 1024);
      expect(nocturne.extension<ThemeTokens>(), isNotNull);
      expect(daybreak.extension<ThemeTokens>(), isNotNull);
      expect(nocturne.scaffoldBackgroundColor, nocturneTokens.void_);
      expect(daybreak.scaffoldBackgroundColor, daybreakTokens.void_);
    });
  });
}

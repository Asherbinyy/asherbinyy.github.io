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
        expect(nocturneTokens.void_, const Color(0xFF05070A));
        expect(nocturneTokens.surface, const Color(0xFF0B0F16));
        expect(nocturneTokens.surfaceRaised, const Color(0xFF131A24));
        expect(nocturneTokens.hairline, const Color(0xFF1C2530));
        expect(nocturneTokens.hairlineStrong, const Color(0xFF2C3846));
        expect(nocturneTokens.beacon, const Color(0xFFF2A83B));
        expect(nocturneTokens.beaconDim, const Color(0xFF7E5720));
        expect(nocturneTokens.beaconGlow, const Color(0xFFFFD48A));
        expect(nocturneTokens.instrument, const Color(0xFFC6D2E0));
        expect(nocturneTokens.instrumentMid, const Color(0xFF8A99AB));
        expect(nocturneTokens.instrumentDim, const Color(0xFF5A6878));
        expect(nocturneTokens.alert, const Color(0xFFE4574E));
        expect(nocturneTokens.verified, const Color(0xFFC6D2E0));
        expect(nocturneTokens.textPrimary, const Color(0xFFE9EEF5));
        expect(nocturneTokens.textSecondary, const Color(0xFF93A3B5));
        expect(nocturneTokens.textMuted, const Color(0xFF57687B));

        expect(nocturneTokens.weightRegular, Tokens.weightRegular);
        expect(nocturneTokens.weightMedium, Tokens.weightMedium);
        expect(nocturneTokens.weightSemibold, Tokens.weightSemibold);
        expect(nocturneTokens.weightBold, Tokens.weightBold);
      },
    );

    test('daybreakTokens exposes valid non-null semantic colors', () {
      expect(daybreakTokens.void_, const Color(0xFFF1EDE4));
      expect(daybreakTokens.surface, const Color(0xFFE8E3D8));
      expect(daybreakTokens.surfaceRaised, const Color(0xFFFFFFFF));
      expect(daybreakTokens.hairline, const Color(0xFFCFC7B8));
      expect(daybreakTokens.hairlineStrong, const Color(0xFFA79C89));
      expect(daybreakTokens.beacon, const Color(0xFFA8620C));
      expect(daybreakTokens.beaconDim, const Color(0xFFC9A878));
      expect(daybreakTokens.beaconGlow, const Color(0xFF7A4506));
      expect(daybreakTokens.instrument, const Color(0xFF3A4654));
      expect(daybreakTokens.instrumentMid, const Color(0xFF6B7887));
      expect(daybreakTokens.instrumentDim, const Color(0xFFA79C89));
      expect(daybreakTokens.alert, const Color(0xFFA32A22));
      expect(daybreakTokens.verified, const Color(0xFF3A4654));
      expect(daybreakTokens.textPrimary, const Color(0xFF12171E));
      expect(daybreakTokens.textSecondary, const Color(0xFF4A5766));
      expect(daybreakTokens.textMuted, const Color(0xFF778395));
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

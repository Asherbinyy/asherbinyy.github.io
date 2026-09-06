import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/platform/app_messenger.dart';
import 'package:nocturne/core/platform/platform_service.dart';
import 'package:nocturne/core/platform/pointer_capabilities.dart';

void main() {
  const pointer = PointerCapabilities(canHover: true, hasFinePointer: true);
  const touch = PointerCapabilities(hasCoarsePointer: true);
  const hybrid = PointerCapabilities(
    canHover: true,
    hasFinePointer: true,
    hasCoarsePointer: true,
  );

  for (final width in [
    Tokens.compactGutter,
    Tokens.expandedBreakpoint,
    Tokens.largeBreakpoint,
  ]) {
    test('fine hovering pointer wins at width $width', () {
      final service = PlatformService(
        capabilities: pointer,
        viewportWidth: width,
      );

      expect(service.inputMode, InputMode.pointer);
      expect(service.minimumTarget, Tokens.pointerTarget);
      expect(AppMessenger.resolve(service), MessagePresentation.toast);
    });

    test('coarse pointer keeps touch behavior at width $width', () {
      final service = PlatformService(
        capabilities: touch,
        viewportWidth: width,
      );

      expect(service.isTouch, isTrue);
      expect(service.minimumTarget, Tokens.touchTarget);
      expect(AppMessenger.resolve(service), MessagePresentation.snackbar);
    });

    test(
      'hover and fine pointer take precedence over coarse at width $width',
      () {
        final service = PlatformService(
          capabilities: hybrid,
          viewportWidth: width,
        );

        expect(service.isPointer, isTrue);
      },
    );
  }

  for (final capabilities in [
    const PointerCapabilities(),
    const PointerCapabilities(canHover: true),
    const PointerCapabilities(hasFinePointer: true),
  ]) {
    test('inconclusive capabilities fall back at the expanded boundary', () {
      final below = PlatformService(
        capabilities: capabilities,
        viewportWidth: Tokens.expandedBreakpoint - Tokens.hairlineWidth,
      );
      final at = PlatformService(
        capabilities: capabilities,
        viewportWidth: Tokens.expandedBreakpoint,
      );

      expect(below.inputMode, InputMode.touch);
      expect(at.inputMode, InputMode.pointer);
    });
  }

  for (final (width, category, gutter) in [
    (
      Tokens.mediumBreakpoint - Tokens.hairlineWidth,
      ViewportClass.compact,
      Tokens.compactGutter,
    ),
    (Tokens.mediumBreakpoint, ViewportClass.medium, Tokens.mediumGutter),
    (
      Tokens.expandedBreakpoint - Tokens.hairlineWidth,
      ViewportClass.medium,
      Tokens.mediumGutter,
    ),
    (Tokens.expandedBreakpoint, ViewportClass.expanded, Tokens.expandedGutter),
    (
      Tokens.largeBreakpoint - Tokens.hairlineWidth,
      ViewportClass.expanded,
      Tokens.expandedGutter,
    ),
    (Tokens.largeBreakpoint, ViewportClass.large, Tokens.largeGutter),
  ]) {
    test('resolves layout category and gutter at $width', () {
      final service = PlatformService(
        capabilities: touch,
        viewportWidth: width,
      );

      expect(service.viewport, category);
      expect(service.gutter, gutter);
    });
  }
}

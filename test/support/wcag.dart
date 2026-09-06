import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// WCAG 2.1 contrast thresholds, as ratios.
///
/// `05-TESTING.md` requires `meetsGuideline(textContrastGuideline)` in both
/// themes. That guideline only inspects what a widget actually rendered, so it
/// cannot say anything about a colour pair no test happens to put on screen.
/// These constants let the palette itself be checked exhaustively, which is
/// what "contrast verified in both" in roadmap 2.2 asks for.
abstract final class Wcag {
  /// Normal-scale text, level AA. Anything below 18.66px bold or 24px regular.
  static const double aaNormalText = 4.5;

  /// Large-scale text, level AA — 18.66px bold or 24px and up.
  ///
  /// Nothing in this type scale qualifies: the largest role that carries a
  /// non-primary colour is `heading` at 22px, and 22px is not large text.
  static const double aaLargeText = 3;

  /// Non-text: UI component boundaries and meaningful graphics, level AA.
  static const double aaNonText = 3;
}

/// The WCAG 2.1 contrast ratio between two opaque colours.
///
/// Flutter's `computeLuminance` is the same relative-luminance formula the
/// guideline specifies — sRGB linearised, then weighted 0.2126 / 0.7152 /
/// 0.0722 — so this only has to apply the ratio around it.
double contrastRatio(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

/// Asserts [foreground] on [background] reaches [target], naming the pair.
///
/// The failure message carries the measured ratio and the shortfall, because
/// "expected true, got false" on a colour pair tells the reader nothing about
/// how far off it is or which way to move it.
void expectContrast(
  Color foreground,
  Color background, {
  required double target,
  required String role,
}) {
  final measured = contrastRatio(foreground, background);
  if (measured >= target) return;

  throw TestFailure(
    '$role: contrast ${measured.toStringAsFixed(2)}:1 is below the '
    '${target.toStringAsFixed(1)}:1 this content needs.\n'
    '  foreground #${_hex(foreground)} on background #${_hex(background)}\n'
    '  short by ${(target - measured).toStringAsFixed(2)}.',
  );
}

String _hex(Color colour) {
  final value =
      (((colour.a * 255).round() & 0xff) << 24) |
      (((colour.r * 255).round() & 0xff) << 16) |
      (((colour.g * 255).round() & 0xff) << 8) |
      ((colour.b * 255).round() & 0xff);
  return value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
}

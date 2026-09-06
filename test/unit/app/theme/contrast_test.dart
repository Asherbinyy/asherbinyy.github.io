import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';

import '../../../support/wcag.dart';

/// One palette role, the surfaces it appears on, and the ratio it owes them.
///
/// Roles are transcribed from the purpose each token is given in
/// `01-DESIGN-SYSTEM.md` section 2, and the surfaces from where the codebase
/// actually paints them. Nothing here is a guess about intent: a colour the
/// documents call "metadata, timestamps" is checked as body text, and one they
/// call "gridlines, inactive data" is checked as a graphical object.
typedef _Role = ({
  String name,
  Color Function(ThemeTokens) colour,
  List<Color Function(ThemeTokens)> surfaces,
  double target,
});

Color _void(ThemeTokens t) => t.void_;
Color _surface(ThemeTokens t) => t.surface;
Color _raised(ThemeTokens t) => t.surfaceRaised;

const _allSurfaces = [_void, _surface, _raised];

/// Text roles. Every one of these is painted below 24px and none is bold at
/// 18.66px or over, so WCAG's large-text allowance never applies — the type
/// scale's largest coloured role is `heading` at 22px.
const List<_Role> _textRoles = [
  (
    name: 'text-primary',
    colour: _textPrimary,
    surfaces: _allSurfaces,
    target: Wcag.aaNormalText,
  ),
  (
    name: 'text-secondary',
    colour: _textSecondary,
    surfaces: _allSurfaces,
    target: Wcag.aaNormalText,
  ),
  (
    name: 'text-muted (metadata, timestamps — 13px meta and 11px telemetry-s)',
    colour: _textMuted,
    surfaces: _allSurfaces,
    target: Wcag.aaNormalText,
  ),
  (
    name: 'instrument (telemetry values, live readouts)',
    colour: _instrument,
    surfaces: _allSurfaces,
    target: Wcag.aaNormalText,
  ),
  (
    name: 'instrument-mid (secondary data, axis labels)',
    colour: _instrumentMid,
    surfaces: _allSurfaces,
    target: Wcag.aaNormalText,
  ),
  (
    name:
        'beacon as text (burst labels and ledger links at 14px, '
        'transmission headings at 22px)',
    colour: _beacon,
    surfaces: _allSurfaces,
    target: Wcag.aaNormalText,
  ),
  (
    name: 'alert',
    colour: _alert,
    surfaces: _allSurfaces,
    target: Wcag.aaNormalText,
  ),
];

/// Non-text roles: boundaries and meaningful graphics, which owe 3:1.
///
/// `hairline` and `hairline-strong` are deliberately absent. They draw
/// structural rules and panel edges, which are decoration rather than the
/// visual information required to identify a component — WCAG 1.4.11 does not
/// reach them. Where an edge does carry state, the focus ring carries it.
const List<_Role> _nonTextRoles = [
  (
    name: 'instrument-dim (gridlines, inactive data, the trace at rest)',
    colour: _instrumentDim,
    surfaces: _allSurfaces,
    target: Wcag.aaNonText,
  ),
  (
    name: 'beacon-dim (corner ticks, inactive marks)',
    colour: _beaconDim,
    surfaces: _allSurfaces,
    target: Wcag.aaNonText,
  ),
];

Color _textPrimary(ThemeTokens t) => t.textPrimary;
Color _textSecondary(ThemeTokens t) => t.textSecondary;
Color _textMuted(ThemeTokens t) => t.textMuted;
Color _instrument(ThemeTokens t) => t.instrument;
Color _instrumentMid(ThemeTokens t) => t.instrumentMid;
Color _instrumentDim(ThemeTokens t) => t.instrumentDim;
Color _beacon(ThemeTokens t) => t.beacon;
Color _beaconDim(ThemeTokens t) => t.beaconDim;
Color _alert(ThemeTokens t) => t.alert;

void main() {
  const themes = {'Nocturne': nocturneTokens, 'Daybreak': daybreakTokens};

  group('palette contrast', () {
    for (final MapEntry(key: themeName, value: tokens) in themes.entries) {
      group(themeName, () {
        for (final role in [..._textRoles, ..._nonTextRoles]) {
          test('${role.name} is legible on every surface it appears on', () {
            for (final surface in role.surfaces) {
              expectContrast(
                role.colour(tokens),
                surface(tokens),
                target: role.target,
                role: '$themeName ${role.name}',
              );
            }
          });
        }

        // The primary call to action inverts: section 2 reserves amber for
        // what the viewer can act on, so BeaconButton fills with `beacon` and
        // labels in `void_`. The pair that matters is therefore the label on
        // the fill, not the fill on the page.
        test('the primary call to action is legible on its own fill', () {
          expectContrast(
            tokens.void_,
            tokens.beacon,
            target: Wcag.aaNormalText,
            role: '$themeName primary CTA label on beacon fill',
          );
        });

        test('the primary call to action stays legible when hovered', () {
          expectContrast(
            tokens.void_,
            tokens.beaconGlow,
            target: Wcag.aaNormalText,
            role: '$themeName primary CTA label on beacon-glow fill',
          );
        });
      });
    }
  });

  group('the two themes are distinct artifacts', () {
    // Section 1: "Dark is the identity, not a mode. Daybreak is a genuine
    // second artifact — a technical drawing on paper — not an inverted dark
    // theme." A straight inversion would put each Daybreak surface at the
    // complement of its Nocturne counterpart; a warm paper stock does not.
    test('Daybreak is warm where an inversion would be neutral', () {
      // Paper carries more red than blue. Inverting Nocturne's blue-black void
      // would instead yield a base whose blue channel led.
      expect(
        daybreakTokens.void_.r,
        greaterThan(daybreakTokens.void_.b),
        reason: 'Daybreak --void should read as warm paper, not inverted ink',
      );
      expect(nocturneTokens.void_.b, greaterThan(nocturneTokens.void_.r));
    });

    test(
      'Daybreak raises toward white while Nocturne raises toward light ink',
      () {
        // Elevation moves in opposite directions, which an inversion would not
        // preserve: Nocturne lifts panels off the void, Daybreak lifts them to
        // paper white.
        expect(
          daybreakTokens.surfaceRaised.computeLuminance(),
          greaterThan(daybreakTokens.void_.computeLuminance()),
        );
        expect(
          nocturneTokens.surfaceRaised.computeLuminance(),
          greaterThan(nocturneTokens.void_.computeLuminance()),
        );
      },
    );

    test('amber is darkened for paper rather than reused', () {
      expect(
        daybreakTokens.beacon.computeLuminance(),
        lessThan(nocturneTokens.beacon.computeLuminance()),
        reason:
            'section 2 calls the Daybreak beacon "darkened for contrast '
            'on paper"',
      );
    });
  });
}

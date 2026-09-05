part of 'tokens.dart';

/// Theme-selected palette; measurements are shared between both artifacts.
@immutable
class ThemeTokens extends ThemeExtension<ThemeTokens> {
  /// Creates a complete palette without synthesizing additional hues.
  const ThemeTokens({
    required this.void_,
    required this.surface,
    required this.surfaceRaised,
    required this.hairline,
    required this.hairlineStrong,
    required this.beacon,
    required this.beaconDim,
    required this.beaconGlow,
    required this.instrument,
    required this.instrumentMid,
    required this.instrumentDim,
    required this.alert,
    required this.verified,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  /// Semantic palette role: void_.
  final Color void_;

  /// Semantic palette role: surface.
  final Color surface;

  /// Semantic palette role: surfaceRaised.
  final Color surfaceRaised;

  /// Semantic palette role: hairline.
  final Color hairline;

  /// Semantic palette role: hairlineStrong.
  final Color hairlineStrong;

  /// Semantic palette role: beacon.
  final Color beacon;

  /// Semantic palette role: beaconDim.
  final Color beaconDim;

  /// Semantic palette role: beaconGlow.
  final Color beaconGlow;

  /// Semantic palette role: instrument.
  final Color instrument;

  /// Semantic palette role: instrumentMid.
  final Color instrumentMid;

  /// Semantic palette role: instrumentDim.
  final Color instrumentDim;

  /// Semantic palette role: alert.
  final Color alert;

  /// Semantic palette role: verified.
  final Color verified;

  /// Semantic palette role: textPrimary.
  final Color textPrimary;

  /// Semantic palette role: textSecondary.
  final Color textSecondary;

  /// Semantic palette role: textMuted.
  final Color textMuted;

  /// Regular bundled font weight.
  FontWeight get weightRegular => Tokens.weightRegular;

  /// Medium bundled font weight.
  FontWeight get weightMedium => Tokens.weightMedium;

  /// Semibold bundled font weight.
  FontWeight get weightSemibold => Tokens.weightSemibold;

  /// Bold bundled font weight.
  FontWeight get weightBold => Tokens.weightBold;

  @override
  ThemeTokens copyWith({
    Color? void_,
    Color? surface,
    Color? surfaceRaised,
    Color? hairline,
    Color? hairlineStrong,
    Color? beacon,
    Color? beaconDim,
    Color? beaconGlow,
    Color? instrument,
    Color? instrumentMid,
    Color? instrumentDim,
    Color? alert,
    Color? verified,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
  }) => ThemeTokens(
    void_: void_ ?? this.void_,
    surface: surface ?? this.surface,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    hairline: hairline ?? this.hairline,
    hairlineStrong: hairlineStrong ?? this.hairlineStrong,
    beacon: beacon ?? this.beacon,
    beaconDim: beaconDim ?? this.beaconDim,
    beaconGlow: beaconGlow ?? this.beaconGlow,
    instrument: instrument ?? this.instrument,
    instrumentMid: instrumentMid ?? this.instrumentMid,
    instrumentDim: instrumentDim ?? this.instrumentDim,
    alert: alert ?? this.alert,
    verified: verified ?? this.verified,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textMuted: textMuted ?? this.textMuted,
  );

  @override
  ThemeTokens lerp(covariant ThemeTokens? other, double t) {
    if (other == null) return this;
    return ThemeTokens(
      void_: Color.lerp(void_, other.void_, t) ?? void_,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceRaised:
          Color.lerp(surfaceRaised, other.surfaceRaised, t) ?? surfaceRaised,
      hairline: Color.lerp(hairline, other.hairline, t) ?? hairline,
      hairlineStrong:
          Color.lerp(hairlineStrong, other.hairlineStrong, t) ?? hairlineStrong,
      beacon: Color.lerp(beacon, other.beacon, t) ?? beacon,
      beaconDim: Color.lerp(beaconDim, other.beaconDim, t) ?? beaconDim,
      beaconGlow: Color.lerp(beaconGlow, other.beaconGlow, t) ?? beaconGlow,
      instrument: Color.lerp(instrument, other.instrument, t) ?? instrument,
      instrumentMid:
          Color.lerp(instrumentMid, other.instrumentMid, t) ?? instrumentMid,
      instrumentDim:
          Color.lerp(instrumentDim, other.instrumentDim, t) ?? instrumentDim,
      alert: Color.lerp(alert, other.alert, t) ?? alert,
      verified: Color.lerp(verified, other.verified, t) ?? verified,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
    );
  }
}

/// Resolves the active palette at the point of use.
extension ThemeTokenContext on BuildContext {
  /// Tokens installed by either Nocturne theme.
  ThemeTokens get tokens {
    final result = Theme.of(this).extension<ThemeTokens>();
    if (result == null) throw StateError('Nocturne theme tokens are missing.');
    return result;
  }
}

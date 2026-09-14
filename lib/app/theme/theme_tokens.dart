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
    required this.ornamentField,
    required this.ornamentFieldAlpha,
    required this.beaconGlow,
    required this.faience,
    required this.faienceDim,
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

  /// The ink the inscription behind every page is drawn in.
  ///
  /// It was `instrumentDim`, a grey, at four percent — present in the file and
  /// invisible on the screen. The owner could not find it in either theme and
  /// asked for gold: warm and faintly lit in the dark, darker and drier in the
  /// light.
  ///
  /// This is the one place gold is allowed to cover the page rather than mark
  /// something actionable. It earns the exception by being an architectural
  /// surface — the wall the site is built on — and it stays legible as
  /// ornament because it never gets close to the weight of a control.
  final Color ornamentField;

  /// How strongly that inscription is cut.
  ///
  /// Per theme, because the same alpha does not read the same on silt and on
  /// limestone: dark ground needs more of it before anything shows at all.
  final double ornamentFieldAlpha;

  /// Semantic palette role: beaconGlow.
  final Color beaconGlow;

  /// Interaction feedback, and nothing else.
  ///
  /// Design system section 2 gives each of the four pigments exactly one job
  /// and this one owns hover, focus, links and in-game state. It must never
  /// appear at rest: a faience pixel on screen while the viewer is not
  /// hovering, focusing or playing is a bug, not a decorative choice.
  final Color faience;

  /// Faience at rest: an interactive affordance that is currently inactive.
  final Color faienceDim;

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
    Color? ornamentField,
    double? ornamentFieldAlpha,
    Color? beaconGlow,
    Color? faience,
    Color? faienceDim,
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
    ornamentField: ornamentField ?? this.ornamentField,
    ornamentFieldAlpha: ornamentFieldAlpha ?? this.ornamentFieldAlpha,
    beaconGlow: beaconGlow ?? this.beaconGlow,
    faience: faience ?? this.faience,
    faienceDim: faienceDim ?? this.faienceDim,
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
      ornamentField:
          Color.lerp(ornamentField, other.ornamentField, t) ?? ornamentField,
      ornamentFieldAlpha:
          lerpDouble(ornamentFieldAlpha, other.ornamentFieldAlpha, t) ??
          ornamentFieldAlpha,
      beaconGlow: Color.lerp(beaconGlow, other.beaconGlow, t) ?? beaconGlow,
      faience: Color.lerp(faience, other.faience, t) ?? faience,
      faienceDim: Color.lerp(faienceDim, other.faienceDim, t) ?? faienceDim,
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
    if (result == null) throw StateError('Theme tokens are missing.');
    return result;
  }
}

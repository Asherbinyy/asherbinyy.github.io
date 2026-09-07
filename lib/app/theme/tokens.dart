// Group immutable scales to keep the single token source under 300 lines.
// ignore_for_file: avoid_multiple_declarations_per_line

import 'package:material_ui/material_ui.dart';

part 'theme_tokens.dart';
part 'token_values.dart';

/// Exact design-system values. Section 11 is tokenized only, not implemented.
abstract final class Tokens {
  /// Bundled type weights, including the semibold body face.
  static const FontWeight weightRegular = FontWeight.w400,
      weightMedium = FontWeight.w500,
      weightSemibold = FontWeight.w600,
      weightBold = FontWeight.w700;

  /// Settled state, with no animation.
  static const Duration noMotion = Duration.zero;

  /// Design-system value for zero.
  static const double zero = 0;

  /// Design-system value for grainOpacity.
  static const double grainOpacity = 0.03;

  /// Design-system value for amberCoverageLimit.
  static const double amberCoverageLimit = 0.05;

  /// Exact space4 scale and related values.
  static const double space4 = 4,
      space8 = 8,
      space12 = 12,
      space16 = 16,
      space24 = 24,
      space32 = 32,
      space48 = 48,
      space64 = 64,
      space96 = 96,
      space128 = 128;

  /// Design-system value for gridUnit.
  static const double gridUnit = 8;

  /// Design-system value for mediumBreakpoint.
  static const double mediumBreakpoint = 600;

  /// Design-system value for expandedBreakpoint.
  static const double expandedBreakpoint = 1024;

  /// Design-system value for largeBreakpoint.
  static const double largeBreakpoint = 1440;

  /// Design-system value for compactGutter.
  static const double compactGutter = 20;

  /// Design-system value for mediumGutter.
  static const double mediumGutter = 32;

  /// Design-system value for expandedGutter.
  static const double expandedGutter = 32;

  /// Design-system value for largeGutter.
  static const double largeGutter = 40;

  /// Design-system value for expandedContentWidth.
  static const double expandedContentWidth = 1180;

  /// Design-system value for largeContentWidth.
  static const double largeContentWidth = 1280;

  /// Design-system value for expandedColumns.
  static const int expandedColumns = 12;

  /// Design-system value for panelRadius.
  static const double panelRadius = 0;

  /// Design-system value for tagRadius.
  static const double tagRadius = 2;

  /// Design-system value for controlRadius.
  static const double controlRadius = 6;

  /// Design-system value for modalRadius.
  static const double modalRadius = 10;

  /// Design-system value for hairlineWidth.
  static const double hairlineWidth = 1;

  /// Design-system value for cornerTickLength.
  static const double cornerTickLength = 8;

  /// Design-system value for cornerTickOffset.
  static const double cornerTickOffset = 4;

  /// Exact displayFamily scale and related values.
  static const String displayFamily = 'Space Grotesk',
      bodyFamily = 'IBM Plex Sans',
      arabicFamily = 'IBM Plex Sans Arabic',
      telemetryFamily = 'IBM Plex Mono';

  /// Exact displayXlMin scale and related values.
  static const double displayXlMin = 48,
      displayXlMax = 112,
      displayXlViewportFactor = 0.09,
      displayXlHeight = 0.92,
      displayXlTracking = -0.03;

  /// Exact displayLMin scale and related values.
  static const double displayLMin = 36,
      displayLMax = 64,
      displayLViewportFactor = 0.055,
      displayLHeight = 1,
      displayLTracking = -0.02;

  /// Exact displayMMin scale and related values.
  static const double displayMMin = 26,
      displayMMax = 40,
      displayMViewportFactor = 0.032,
      displayMHeight = 1.1,
      displayMTracking = -0.01;

  /// Design-system value for headingSize.
  static const double headingSize = 22;

  /// Design-system value for headingHeight.
  static const double headingHeight = 1.25;

  /// Design-system value for bodyLSize.
  static const double bodyLSize = 18;

  /// Design-system value for bodySize.
  static const double bodySize = 16;

  /// Design-system value for bodySSize.
  static const double bodySSize = 14;

  /// Design-system value for bodyHeight.
  static const double bodyHeight = 1.6;

  /// Design-system value for bodySHeight.
  static const double bodySHeight = 1.55;

  /// Design-system value for metaSize.
  static const double metaSize = 13;

  /// Design-system value for metaHeight.
  static const double metaHeight = 1.4;

  /// Design-system value for telemetrySize.
  static const double telemetrySize = 13;

  /// Design-system value for telemetrySSize.
  static const double telemetrySSize = 11;

  /// Design-system value for telemetryHeight.
  static const double telemetryHeight = 1.3;

  /// Design-system value for arabicHeightIncrease.
  static const double arabicHeightIncrease = 0.15;

  /// Design-system value for bodyMeasureCharacters.
  static const int bodyMeasureCharacters = 68;

  /// Average character advance as a fraction of the font size.
  ///
  /// Section 3 caps the measure at 68 characters and says to enforce it with a
  /// max-width rather than guesswork. Proportional Latin text averages close to
  /// half an em per character, which is what turns a character count into one.
  static const double measureAdvanceRatio = 0.5;

  /// Exact instant scale and related values.
  static const Duration instant = Duration(milliseconds: 100),
      quick = Duration(milliseconds: 180),
      standard = Duration(milliseconds: 280),
      considered = Duration(milliseconds: 480),
      sequence = Duration(milliseconds: 900);

  /// Design-system value for reducedAcquisition.
  static const Duration reducedAcquisition = Duration(milliseconds: 200);

  /// Design-system value for emphasized.
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);

  /// Design-system value for exit.
  static const Curve exit = Cubic(0.4, 0, 1, 1);

  /// Design-system value for linear.
  static const Curve linear = Curves.linear;

  /// Design-system value for spring.
  static const SpringDescription spring = SpringDescription(
    mass: 1,
    stiffness: 180,
    damping: 22,
  );

  /// Design-system value for idleTraceFrequency.
  static const double idleTraceFrequency = 0.2;

  /// Design-system value for traceFrameRate.
  static const int traceFrameRate = 60;

  /// Design-system value for traceFrameBudget.
  static const Duration traceFrameBudget = Duration(milliseconds: 4);

  /// Design-system value for messageLifetime.
  static const Duration messageLifetime = Duration(seconds: 4);

  /// Design-system value for tooltipDelay.
  static const Duration tooltipDelay = Duration(milliseconds: 400);

  /// Design-system value for touchTarget.
  static const double touchTarget = 48;

  /// Design-system value for pointerTarget.
  static const double pointerTarget = 40;

  /// Design-system value for iconStroke.
  static const double iconStroke = 1.5;

  /// Design-system value for iconGrid.
  static const double iconGrid = 24;

  /// Design-system value for portraitAspectRatio.
  static const double portraitAspectRatio = 4 / 5;

  /// Design-system value for skeletonTextFraction.
  static const double skeletonTextFraction = 0.6;

  /// Design-system value for sweepOpacity.
  static const double sweepOpacity = 0.18;

  /// Design-system value for sweepWidthFraction.
  static const double sweepWidthFraction = 0.2;

  /// Design-system value for sweep.
  static const Duration sweep = Duration(milliseconds: 1400);

  /// Design-system value for sweepPause.
  static const Duration sweepPause = Duration(milliseconds: 400);

  /// Design-system value for loaderWidth.
  static const double loaderWidth = 32;

  /// Width of one `/console` stat tile.
  ///
  /// Not from `01-DESIGN-SYSTEM.md`: the console is Milestone 2 and the design
  /// system predates it. Added here rather than written inline because §6 of
  /// `AGENTS.md` bans raw values in feature code. Sized to hold four tiles on
  /// one row at the expanded breakpoint, which is the layout the screen spec
  /// draws.
  static const double consoleTileWidth = 120;

  /// Design-system value for loaderHeight.
  static const double loaderHeight = 12;

  /// Design-system value for loaderFrequency.
  static const double loaderFrequency = 0.6;

  /// Design-system value for placeholderImageWidth.
  static const double placeholderImageWidth = 20;

  /// Design-system value for placeholderImageHeight.
  static const double placeholderImageHeight = 25;

  /// Design-system value for placeholderImageByteLimit.
  static const int placeholderImageByteLimit = 400;

  /// Design-system value for imageResolve.
  static const Duration imageResolve = Duration(milliseconds: 280);

  /// Cycles of carrier visible across one container width at rest.
  static const double carrierRestCycles = 3;

  /// Baseline carrier amplitude, as a fraction of the available half-height.
  static const double carrierRestAmplitude = 0.35;

  /// Burst envelope width, as a fraction of the container width.
  static const double carrierBurstWidth = 0.18;

  /// Fewest and most nodes in a procedural station-card constellation.
  static const int stationNodeMin = 5, stationNodeMax = 9;

  /// Chrome dimensions from screen-spec section "Global chrome".
  static const double headerHeight = 64,
      railWidth = 56,
      footerHeight = 48,
      railProgressHeight = 3;

  /// The hero's amber rule: 120px wide, 2px thick, and deliberately short of
  /// the column — a full-width rule reads as a divider, a short one as a mark.
  static const double heroRuleWidth = 120, heroRuleHeight = 2;

  /// Grain tile edge, in logical pixels, and the specks drawn into one tile.
  static const double grainTile = 128;

  /// Specks per tile. Enough to read as texture at 3% opacity, few enough that
  /// the tile paints in well under a frame.
  static const int grainSpecks = 640;

  /// Acquisition beat boundaries as fractions of the full sequence.
  static const double acquisitionBeatOne = 0.25,
      acquisitionBeatTwo = 0.583,
      acquisitionBeatThree = 0.833;

  /// The full acquisition sequence: four beats totalling 2400ms.
  static const Duration acquisition = Duration(milliseconds: 2400);

  /// Station node radius at rest and when selected, per the screen spec.
  static const double stationNodeRadius = 6, stationNodeActiveRadius = 10;

  /// How far the selected node's pulse ring expands beyond the node.
  static const double stationPulseRadius = 22;

  /// Arc opacity for legs that are not the active one.
  static const double arcOpacity = 0.4;

  /// How long the arcs take to draw in on first view.
  static const Duration arcDraw = Duration(milliseconds: 1600);

  /// Degrees between graticule lines on the map surface.
  static const double graticuleStep = 30;

  /// The map's aspect ratio. Equirectangular is 2:1 by construction.
  static const double mapAspectRatio = 2;

  /// Scroll velocity above which the signal degrades toward noise, px/s.
  static const double traceScanningVelocity = 900;

  /// Scroll velocity below which the signal can lock, px/s.
  static const double traceLockVelocity = 120;

  /// How near the nearest burst must be for lock, in pixels.
  static const double traceLockDistance = 200;

  /// How long without scrolling before the trace reads as at rest.
  static const Duration traceRestDelay = Duration(milliseconds: 1200);

  /// Carrier cycles per viewport height.
  ///
  /// Expressed per screen rather than per trace so the waveform reads at the
  /// same frequency whatever the page's length; a fixed count over the whole
  /// trace turns into a slow decorative sine on a long page.
  static const double traceCycles = 9;

  /// Trace amplitude as a fraction of its own column width.
  static const double traceAmplitude = 0.2;

  /// Burst width as a fraction of the whole trace.
  ///
  /// Much narrower than the mark's, because the trace is pages long: at the
  /// carrier's own width every burst would overlap every other and the rest
  /// amplitude would never be seen.
  static const double traceBurstWidth = 0.045;

  /// Fraction of the content column the trace occupies, from the trailing edge.
  ///
  /// Two values, because one was wrong on a phone. At 66% of a desktop the
  /// trace runs down the space beside a measure-limited text column and never
  /// touches it. At 66% of a 360px phone, where the text fills the full width,
  /// it runs straight across the copy — which is what the owner reported, along
  /// with the burst labels colliding with the same text.
  ///
  /// On compact the trace keeps to a narrow strip at the trailing edge. It is
  /// still legible as a waveform and it no longer competes with the words.
  static const double traceColumnFraction = 0.66,
      traceColumnFractionCompact = 0.28;

  /// Jitter added to the carrier when coherence is entirely lost.
  static const double traceNoiseAmplitude = 0.55;

  /// How many standard deviations of the burst the mark spans.
  ///
  /// The mark is a burst on a carrier, not a bare curve: section 12 draws flat
  /// line either side of the hump. Sampling five sigmas each way puts those
  /// shoulders inside the box, where a one-sigma window would fill it with
  /// hump alone and read as a hill.
  static const double markCurveSigmas = 5;

  /// The mark: 2px stroke at its native 32px square, 24px in the header.
  static const double markNativeSize = 32, markStroke = 2, markHeaderSize = 24;

  /// The torch's reach over the wall, as a fraction of the visible frame's
  /// longest side.
  ///
  /// It tightens as the reading settles and spreads as it is lost, so a fast
  /// scroll washes the wall in weak light rather than lighting a small part of
  /// it brightly — which is the difference between "unreadable" and "hidden".
  static const double wallTorchSpread = 1.15, wallTorchFocus = 0.62;

  /// How much the torch breathes at rest, as a fraction of its radius.
  static const double wallTorchBreath = 0.04;

  /// How much of a plain register's run carries signs.
  ///
  /// Short of full, so a career line reads as denser than the wall around it.
  static const double wallRestFill = 0.55;

  /// Distance between signs on an inscribed line.
  static const double wallSignPitch = 26;

  /// The cursor wake: how long a mote lives, how many may live at once, and
  /// how large one starts.
  ///
  /// The cap is the performance budget expressed as a number rather than an
  /// intention: a fast drag across a wide viewport would otherwise accumulate
  /// hundreds of circles. `12-MOTIF-LIBRARY.md` §5 fixes it at 24.
  static const int cursorTrailLifeMs = 520, cursorTrailMaxMotes = 24;

  /// A mote's radius at birth.
  static const double cursorTrailRadius = 3;

  /// Opacity of the inscription field behind every page.
  ///
  /// One step above the 3% texture beneath it, so the two read as separate
  /// layers rather than as one muddy surface. `12-MOTIF-LIBRARY.md` §4.
  static const double glyphFieldOpacity = 0.04;

  /// The cartouche's height where it introduces the name in the hero.
  ///
  /// Its width follows from `CartouchePainter.aspectRatio`, so this is the
  /// only dimension anyone sets. Sized to sit clearly under the display-xl
  /// name without competing with it: the sign is the ornament, the name is
  /// the information.
  static const double cartoucheHeroHeight = 40;
}

/// Kemet palette from design-system section 2 — the Black Land.
///
/// Every value was solved rather than chosen: each role was moved on lightness
/// alone, hue and saturation untouched, until it met its WCAG floor on all
/// three surfaces. `contrast_test.dart` is what makes that true; changing a
/// value here means running it, not eyeballing the result.
const nocturneTokens = ThemeTokens(
  // Lifted off black on the owner's instruction — 4.4x the relative luminance
  // of the milestone-1 value, and blue-led, because the Black Land is river
  // silt rather than void.
  void_: Color(0xFF121826),
  surface: Color(0xFF1A2233),
  surfaceRaised: Color(0xFF232D40),
  hairline: Color(0xFF2E3A50),
  hairlineStrong: Color(0xFF3F4D66),
  beacon: Color(0xFFE3A93F),
  beaconDim: Color(0xFF92702E),
  beaconGlow: Color(0xFFFFD98A),
  faience: Color(0xFF45B8B2),
  faienceDim: Color(0xFF2D827D),
  instrument: Color(0xFFCBD6E6),
  instrumentMid: Color(0xFF93A2B8),
  instrumentDim: Color(0xFF69788F),
  alert: Color(0xFFE3716C),
  verified: Color(0xFFCBD6E6),
  textPrimary: Color(0xFFEDF1F8),
  textSecondary: Color(0xFFA8B4C6),
  textMuted: Color(0xFF8895A8),
);

/// Deshret palette from design-system section 2 — the Red Land.
///
/// A second artifact on papyrus, not an inversion of Kemet. Solved the same
/// way, and needing more of the work, because dark ink on warm paper has less
/// headroom than light ink on near-black.
const daybreakTokens = ThemeTokens(
  void_: Color(0xFFF2E9D8),
  surface: Color(0xFFE9DEC8),
  surfaceRaised: Color(0xFFFCF7EC),
  hairline: Color(0xFFD6C8AC),
  hairlineStrong: Color(0xFFAD9C7C),
  beacon: Color(0xFF885912),
  beaconDim: Color(0xFF9C7534),
  beaconGlow: Color(0xFF6F4409),
  faience: Color(0xFF1C6B68),
  faienceDim: Color(0xFF2E8481),
  instrument: Color(0xFF37424F),
  instrumentMid: Color(0xFF586472),
  instrumentDim: Color(0xFF8A7C63),
  alert: Color(0xFF9C2E26),
  verified: Color(0xFF37424F),
  textPrimary: Color(0xFF13181F),
  textSecondary: Color(0xFF48545F),
  textMuted: Color(0xFF5A6470),
);

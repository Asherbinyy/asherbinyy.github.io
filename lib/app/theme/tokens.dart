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
  static const double traceColumnFraction = 0.66;

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
}

/// Nocturne palette from design-system section 2.
const nocturneTokens = ThemeTokens(
  void_: Color(0xFF05070A),
  surface: Color(0xFF0B0F16),
  surfaceRaised: Color(0xFF131A24),
  hairline: Color(0xFF1C2530),
  hairlineStrong: Color(0xFF2C3846),
  beacon: Color(0xFFF2A83B),
  beaconDim: Color(0xFF7E5720),
  beaconGlow: Color(0xFFFFD48A),
  instrument: Color(0xFFC6D2E0),
  instrumentMid: Color(0xFF8A99AB),
  instrumentDim: Color(0xFF5A6878),
  alert: Color(0xFFE4574E),
  verified: Color(0xFFC6D2E0),
  textPrimary: Color(0xFFE9EEF5),
  textSecondary: Color(0xFF93A3B5),
  textMuted: Color(0xFF57687B),
);

/// Daybreak palette from design-system section 2.
const daybreakTokens = ThemeTokens(
  void_: Color(0xFFF1EDE4),
  surface: Color(0xFFE8E3D8),
  surfaceRaised: Color(0xFFFFFFFF),
  hairline: Color(0xFFCFC7B8),
  hairlineStrong: Color(0xFFA79C89),
  beacon: Color(0xFFA8620C),
  beaconDim: Color(0xFFC9A878),
  beaconGlow: Color(0xFF7A4506),
  instrument: Color(0xFF3A4654),
  instrumentMid: Color(0xFF6B7887),
  instrumentDim: Color(0xFFA79C89),
  alert: Color(0xFFA32A22),
  verified: Color(0xFF3A4654),
  textPrimary: Color(0xFF12171E),
  textSecondary: Color(0xFF4A5766),
  textMuted: Color(0xFF778395),
);

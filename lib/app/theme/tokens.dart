// Group immutable scales to keep the single token source under 300 lines.
// ignore_for_file: avoid_multiple_declarations_per_line

import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

part 'theme_tokens.dart';
part 'token_values.dart';

/// Exact design-system values. Section 11 is tokenized only, not implemented.
abstract final class Tokens {
  /// A complete kick, flight and net reaction at a readable pace.
  static const Duration footballAction = Duration(milliseconds: 1400);

  /// A stalled Writing request yields to bundled published metadata.
  static const Duration writingTimeout = Duration(seconds: 8);

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

  /// How much of the screen a secondary surface may occupy.
  ///
  /// A bottom sheet is anchored to an edge and can take more; a dialog is
  /// centred and needs air around it. Both scroll inside the cap rather than
  /// clipping, which is what they did before.
  static const double sheetMaxHeightFraction = 0.86;

  /// How much of the screen a centred dialog may occupy.
  static const double dialogMaxHeightFraction = 0.8;

  /// The widest the content frame is allowed to become.
  ///
  /// Pages were laid out from the leading edge with no ceiling, so above about
  /// 1600px the content sat against the left of the window with a third of the
  /// screen empty beside it. This caps the frame and centres it; paragraphs
  /// still cap at their own reading measure inside it.
  static const double contentMaxWidth = 1320;

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

  /// Corner radius on the top edge of a bottom sheet.
  ///
  /// Larger than a modal's, and applied to the top corners only. The sheet
  /// used one radius on all four, so the bottom corners were rounded against
  /// the bottom of the screen and the whole thing read as a floating box
  /// rather than as something that had come up from the edge.
  static const double sheetRadius = 20;

  /// Corner radius for a card carrying an image.
  ///
  /// The design language is square: panels have no radius, because an
  /// instrument panel does not. A photograph is not an instrument, and a cover
  /// with square corners reads as a screenshot dropped on the page rather than
  /// as a card, which is what the owner objected to. This is the one place
  /// roundness is allowed, and it is deliberately larger than a control's so
  /// that it reads as intentional rather than as a control that grew.
  static const double cardRadius = 12;

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

  /// The theme brazier: one loop of its flame, and the time it takes to catch
  /// or go out. Values unchanged from when they were written in the widget.
  static const Duration brazierFlicker = Duration(milliseconds: 2600),
      brazierStrike = Duration(milliseconds: 520);

  /// One rise and fall of the three bars while the name recording plays.
  static const Duration voicePulse = Duration(milliseconds: 1400);

  /// The papyrus figures winding up and opening out again. Nothing drives
  /// them at present -- the owner asked for the sheets to stay flat -- but the
  /// controller still needs a length.
  static const Duration papyrusRoll = Duration(milliseconds: 460),
      papyrusUnroll = Duration(milliseconds: 520);

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

  /// Below this content height Journey scrolls instead of clipping controls.
  static const double journeyMinContentHeight = 320;

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

  /// The narrowest the wall may become on a wide viewport.
  ///
  /// Below this it stops reading as a wall and becomes a sliver of rules at
  /// the edge of the page.
  static const double traceColumnFractionMinimum = 0.22;

  /// Fraction of the content column the trace occupies, from the trailing edge.
  ///
  /// At 66% of a desktop the trace runs down the space beside a
  /// measure-limited text column and never touches it. Phones used to keep a
  /// narrower strip of their own; the wall is behind the whole page there now.
  static const double traceColumnFraction = 0.38;

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

  /// Peak brightness of the light entering during the opening sequence.
  ///
  /// Low: it is a door opening in a dark room, not a flash. The whole point of
  /// the beat is that the page arrives out of the dark.
  static const double openingGlow = 0.28;

  /// Every this many metres, the shaft acknowledges the climb.
  ///
  /// Fifty, matching the step at which the floor speeds up. It was a hundred,
  /// which meant the first thing the game ever said to a player arrived after
  /// they had survived the floor starting to move — the one moment in the climb
  /// most worth saying something about. Every fifty is also close enough
  /// together that a long run is punctuated rather than silent.
  static const int ascentRewardStep = 50;

  /// How long the mark stays up afterwards, in seconds.
  static const double ascentRewardHold = 1.6;

  /// How long, in seconds, the line naming a relic or a spent life stays up.
  static const double ascentNewsHold = 1.6;

  /// The climb's HUD: a relic's sign, an empty life's strength, the width of
  /// a relic's draining bar, and a sign in the legend.
  static const double ascentHudMark = 18,
      ascentEmptyLife = 0.25,
      ascentMeterWidth = 72,
      ascentLegendMark = 44;

  /// The golden mask at the summit: its size, and its golds and kohl -- the
  /// night palette's own, fixed, since the reward is the same by day.
  static const double ascentMaskSize = 128;

  /// See [ascentMaskSize].
  static const Color ascentMaskGold = Color(0xFFE3A93F),
      ascentMaskDeep = Color(0xFF92702E),
      ascentMaskInk = Color(0xFF121826);

  /// How heavy the kicking figure's limbs are, against the scene's own ink.
  ///
  /// It was 1.7, which drew a figure with the build of a snowman -- the owner
  /// called the stickman too fat and he was right. Just above the scene's own
  /// line weight reads as a drawn figure rather than a padded one.
  static const double footballLimbWeight = 1.05;

  /// The head, as a fraction of the scene's height. Smaller than the limbs
  /// suggest, because a stick figure's head is a mark and not a ball.
  static const double footballHeadRadius = 0.038;

  /// How strongly the portrait's gold edge reads.
  static const double portraitEdgeAlpha = 0.55;

  /// How much light the frame throws behind the picture.
  static const double portraitGlowAlpha = 0.22;

  /// How far that light carries, and how far it is pushed out first.
  static const double portraitGlowBlur = 34, portraitGlowSpread = 2;

  /// One country disc on the reach row, and how far the flag inside it is
  /// blown up before being clipped so no letterboxing shows.
  static const double flagDiameter = 26, flagOverscan = 1.35;

  /// How wide the year and name column on a stop card may grow.
  static const double stopCardTextWidth = 168;

  /// How far down the page the way back up appears, in viewports.
  static const double backToTopAfter = 1.4;

  /// The diameter of that control.
  static const double backToTopSize = 48;

  /// The column the career's frieze runs down.
  static const double careerThreadWidth = 28;

  /// Clear air between the frieze and the stop marks beside it.
  ///
  /// Without it the two draw on top of each other, and the one column that is
  /// meant to be legible at a glance becomes a muddle.
  static const double careerThreadGap = 12;

  /// The narrowest column that holds half the skill titles on one line;
  /// below it they are one wrap rather than two broken halves.
  static const double skillsTwoLinesFrom = 820;

  /// The phone's stops beside the career cards: the rail's width and the
  /// mark on it.
  static const double careerRailCompact = 44, careerRailNode = 36;

  /// How fast the carved field travels against the page.
  ///
  /// A quarter of the scroll. Far enough that the two planes separate and the
  /// wall reads as being behind the text; near enough that the signs do not
  /// visibly race the words, which stops looking like depth and starts looking
  /// like a bug.
  static const double ornamentParallax = 0.25;

  /// The still of the climb beside the courtyard's Play button: how tall it
  /// is, and which fresh run it shows. A fixed seed, so the picture is the
  /// same climb on every visit rather than a new one per page load.
  static const double courtyardStillHeight = 240;

  /// See [courtyardStillHeight].
  static const int courtyardStillSeed = 7;

  /// One service card, and the mark on it.
  static const double serviceCardWidth = 220,
      serviceCardCompactWidth = 140,
      serviceIconSize = 26;

  /// An icon standing in for a word in the header.
  static const double chromeIconSize = 20;

  /// The platform mark on a contact card.
  static const double contactIconSize = 18;

  /// One contact card's width, and every contact card is this wide.
  ///
  /// Sized to hold the longest destination -- "Instagram" with its mark -- and
  /// no more. It was 132, which truncated, and briefly it was whatever a row
  /// divided into, which gave "GitHub" a box twice the size of its word.
  static const double contactCardWidth = 152;

  /// The narrowest a social profile's tile may be: narrower than the two
  /// ways to message him, so nine profiles take three rows, not five.
  static const double contactSocialWidth = 148;

  /// The "or" line between messaging and booking: four profile tiles and
  /// the gaps between them, so it ends where they do.
  static const double contactOrMaxWidth = 640;

  /// On a phone: the narrowest a way to message him may be (two across),
  /// and a profile tile (four across).
  static const double contactCompactDirect = 120, contactCompactTile = 64;

  /// The calendar on the booking card.
  static const double bookingIconSize = 32;

  /// One skill chip's width, and every skill chip is this wide.
  ///
  /// Sized to hold the longest of them -- "Adobe Premiere Pro" -- so the block
  /// reads as a grid without any chip being padded out past its word. Sizing
  /// each to its own text made the panel look like rubble; sizing each to a
  /// share of the row made "Dart" mostly empty box.
  static const double skillChipWidth = 168;

  /// How many chips an open skills group shows before "N more".
  static const int skillsPreviewCount = 15;

  /// A card rising into view: how long it takes, how far it travels in from
  /// the side and from below, and how much smaller it starts.
  static const Duration revealRise = Duration(milliseconds: 640);

  /// See [revealRise].
  static const double revealRiseSlide = 36,
      revealRiseLift = 28,
      revealRiseShrink = 0.04;

  /// The booking card: the widest it runs, and how far its arrow slides on
  /// hover (a share of the arrow).
  static const double bookingCardMaxWidth = 380, bookingArrowTravel = 0.3;

  /// The falcon beside the contact links: one flight, its box, and the panel
  /// width from which it has room.
  static const Duration courierFlight = Duration(milliseconds: 4200);

  /// See [courierFlight].
  static const double courierWidth = 340,
      courierHeight = 260,
      courierFrom = 900;

  /// A flag in the wind, on hover: one period of the ripple, how long a tap
  /// flies it on a phone, how far the disc lifts and grows, the shadow under
  /// it, how many strips the cloth is cut into, how far apart the strips sit
  /// on the wave, how high the wave runs, and the light and shade of a fold.
  static const Duration flagWavePeriod = Duration(milliseconds: 1100),
      flagTapFlight = Duration(milliseconds: 1600);

  /// See [flagWavePeriod].
  static const double flagLift = 4,
      flagLiftScale = 0.18,
      flagShadowAlpha = 0.45,
      flagShadowBlur = 10,
      flagWaveStep = 0.7,
      flagWaveHeight = 2.2,
      flagFoldLight = 0.18,
      flagFoldShade = 0.22;

  /// See [flagWavePeriod].
  static const int flagStrips = 10;

  /// The skills panel: how long an opened group takes to fill in, how far a
  /// chip rises as it arrives, how many chips' length each one's arrival
  /// overlaps the next, and how strongly the count shows on an open title.
  static const Duration skillsArrive = Duration(milliseconds: 420);

  /// See [skillsArrive].
  static const double skillsRise = 8, skillsStaggerTail = 4;

  /// See [skillsArrive].
  static const double skillsCountAlpha = 0.7;

  /// How the gold glow behind a hovered contact card is thrown.
  static const double contactGlowAlpha = 0.35, contactGlowBlur = 18;

  /// The sign beside a career entry.
  ///
  /// Big enough to read as a figure rather than a bullet, small enough that
  /// the entry's own heading is still the first thing the eye lands on.
  static const double stopMarkSize = 44;

  /// How strongly its cut edges show.
  static const double stopMarkReliefAlpha = 0.5;

  /// How opaque the ground under an artwork card's name becomes, and how far
  /// up the card that ground rises.
  ///
  /// The name was drawn straight over the constellation, so its dots and
  /// orbit lines crossed the letters -- the badge above it had a solid backing
  /// for exactly this reason and the name never got one. The ground fades in
  /// from nothing, so the artwork is still whole above the name.
  static const double cardNameScrimAlpha = 0.92, cardNameScrimExtent = 0.62;

  /// How much of the phone nav row fades at an edge with more links past it.
  ///
  /// Was a bare 0.88 stop in the row's mask, which faded the last 12 percent;
  /// named here with the same share, and now used at the leading edge too.
  static const double navEdgeFade = 0.12;

  /// How opaque the backing under an artwork card's sector badge is.
  ///
  /// Was a bare 0.86 in the card; named here with its value unchanged.
  static const double cardBadgeScrimAlpha = 0.86;

  /// The itinerary on Home: one stop's node and the cell it sits in.
  ///
  /// Small. It is an index to the career below, not a second telling of it,
  /// and a node the size of the atlas's would compete with the entries.
  static const double stopNodeRadius = 5;

  /// The width of the column the thread runs down.
  static const double stopRailWidth = 22;

  /// The height of one stop's cell, which is what sets the thread's length.
  static const double stopRowHeight = 30;

  /// How much wider than tall a station's cartouche sits on the atlas.
  ///
  /// The shape only, and it encloses nothing: a cartouche ring is what an
  /// Egyptian map-maker would have drawn around a place, and it is read here
  /// at a glance rather than read as writing. Past about this ratio it stops
  /// reading as an enclosure and starts reading as a dash on a coastline.
  static const double stationCartoucheRatio = 1.7;

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

  /// The widest the climb's playfield is allowed to become.
  ///
  /// A shaft that fills a desktop window is a shaft nobody can see the walls
  /// of, and the steering becomes imprecise at that width.
  static const double ascentMaxWidth = 520;

  /// How wide the board sits beside the climb.
  ///
  /// Narrow on purpose. It is read in the corner of an eye between two jumps,
  /// and anything wider starts competing with the shaft for the middle of the
  /// screen — which is where the thing the player is actually watching is.
  static const double ascentRailWidth = 190;

  /// The touch controls: the share of the screen's width that steers (the
  /// rest jumps), the stick's base and knob, how far the knob must move
  /// before it steers, the jump button and its mark, how much of the jump
  /// button's gold shows at rest, and the fill behind the stick.
  static const double ascentStickShare = 0.55,
      ascentStickBase = 120,
      ascentStickKnob = 52,
      ascentStickDead = 12,
      ascentJumpSize = 96,
      ascentJumpIcon = 40,
      ascentJumpRest = 0.14,
      ascentTouchFill = 0.35;

  /// The cursor wake: how long a mote lives, how many may live at once, and
  /// how large one starts.
  ///
  /// The cap is the performance budget expressed as a number rather than an
  /// intention: a fast drag across a wide viewport would otherwise accumulate
  /// hundreds of circles. `12-MOTIF-LIBRARY.md` §5 fixes it at 24.
  static const int cursorTrailLifeMs = 520, cursorTrailMaxMotes = 24;

  /// A mote's radius at birth.
  static const double cursorTrailRadius = 3;

  /// How far a carved edge sits from the body of its stroke.
  ///
  /// A fraction of the stroke weight, so a cut reads as one groove at any
  /// weight rather than separating into three parallel lines.
  static const double wallCarveOffset = 0.9;

  /// Height of one masonry course on the wall.
  static const double wallCourseHeight = 132;

  /// Width of one block in that course.
  static const double wallBlockWidth = 96;

  /// How much of a block its sign fills.
  ///
  /// Short of the joint on every side, because a sign that touches the edge
  /// of its block reads as tiling rather than as something cut into it.
  static const double wallSignFill = 0.54;

  /// How deep a sign is cut, against its own size.
  static const double wallSignRelief = 0.016;

  /// One block in this many is gilded.
  ///
  /// Sparse on purpose. Gold on this site marks the person and anything
  /// actionable, and a wall of it would spend that meaning on decoration.
  static const int wallGildedInOne = 5;

  /// How far each course lags the one above it in the shimmer.
  ///
  /// Without the lag the whole column brightens at once, which reads as a
  /// bulb rather than as light moving across a surface.
  static const double wallShimmerStagger = 0.7;

  /// How far a held torch reaches, in pixels.
  ///
  /// Wide enough that moving across the wall lights a group rather than one
  /// block at a time, which is what makes it read as a lamp rather than a
  /// hover state.
  static const double wallTorchReach = 300;

  /// Seconds for the light to come up, and the same to die down.
  ///
  /// Long enough to read as a flame being carried in rather than a hover
  /// state switching on, short enough that it keeps up with the hand.
  static const double wallTorchFade = 0.26;

  /// The brightest a scroll-carried torch gets where the wall is behind the
  /// text rather than beside it.
  ///
  /// On a wide frame a hand holds the light and can take it off the wall
  /// entirely. On a phone the light never leaves — it is carried by the scroll,
  /// so it is on for the whole page — and the wall's strip runs close enough to
  /// the text that a flame at full strength sits behind the ends of lines.
  ///
  /// It was 0.85 while the wall kept a strip of its own on a phone. The wall
  /// is behind the whole page there now (the owner asked for the content
  /// centred, not squeezed left of a strip), so a strong light sits behind
  /// the words themselves. Low enough to read as a glow behind the copy.
  static const double wallTorchTouchPeak = 0.3;

  /// The picture beside the hero: its shape (width over height), how long
  /// the sun takes to rise or set when the theme changes, and how quickly the
  /// layers follow the pointer each frame (a share of the remaining distance).
  static const double heroSceneAspect = 0.96, heroParallaxEase = 0.08;

  /// See [heroSceneAspect].
  static const Duration heroSunTravel = Duration(milliseconds: 2400);

  /// How much of the picture fades into the page at each edge, as a share of
  /// its width or height: the sides, the top (where the sky already matches
  /// the page) and the foot of the desk.
  static const double heroSceneFadeSides = 0.12,
      heroSceneFadeTop = 0.1,
      heroSceneFadeBottom = 0.16;

  /// Skin, for the one person the site draws: the climber in the game, and
  /// the same man at his desk in the hero picture. The owner asked for his
  /// face and limbs in a human skin tone rather than gold. It is
  /// illustration, not a fifth pigment for the interface: nothing but that
  /// figure may use it.
  static const Color figureSkin = Color(0xFFB98159);

  /// See [figureSkin]: the far arm, the shadowed side.
  static const Color figureSkinShade = Color(0xFF93613F);

  /// The sun's button: its hit area as a multiple of the disc's radius, the
  /// focus ring's radius, and the faience wash of a press.
  static const double heroSunTargetScale = 2.6,
      heroSunFocusRadius = 999,
      heroSunSplashAlpha = 0.18;

  /// The life loop on `/about`: one step's share of a run (a run is six of
  /// them), the loop's height, a node's size and the width its label may use.
  static const Duration lifeFlowStep = Duration(milliseconds: 1400);

  /// See [lifeFlowStep].
  static const double lifeFlowHeight = 560,
      lifeFlowNodeSize = 56,
      lifeFlowLabelWidth = 120;

  /// The widest the life loop runs when it stacks under the biography.
  static const double lifeFlowMaxWidth = 420;

  /// A running node's light, and the tick a finished node keeps.
  static const double lifeFlowGlowAlpha = 0.35,
      lifeFlowGlowBlur = 18,
      lifeFlowTickSize = 18,
      lifeFlowTickInset = 6;

  /// How the hero's width is shared between the copy and the picture.
  static const int heroCopyFlex = 11, heroSceneFlex = 9;

  /// A career card splits into facts and story from this width, and shares
  /// it between them in this ratio.
  static const double careerCardSplitWidth = 720;

  /// See [careerCardSplitWidth].
  static const int careerFactsFlex = 2, careerStoryFlex = 3;

  /// The disc that shows an app's own screen on a career card's chip.
  static const double careerAppThumb = 28;

  /// On a phone, the column the hero's figures sit in before their labels.
  static const double compactStatFigure = 64;

  /// A Work card's artwork height, tall enough for a phone screen to be a
  /// screen.
  static const double workArtHeight = 220;

  /// How long the front screen comes forward before an app's page opens,
  /// and how far a card gives under a press.
  static const Duration workOpenLead = Duration(milliseconds: 200);

  /// See [workOpenLead].
  static const double workPressScale = 0.97;

  /// A Work card's fan of screens: the seed's ground behind it, how tall a
  /// screen is against the artwork, its shape (width to height, and corner
  /// as a share of its width), and its shadow.
  static const double workFanGroundAlpha = 0.45,
      workShotHeight = 0.8,
      workShotAspect = 0.47,
      workShotRadius = 0.12,
      workShotShadowAlpha = 0.35,
      workShotShadowBlur = 16,
      workShotShadowDrop = 6;

  /// How the fan sits closed and how far it opens: the side screens' offset
  /// as a share of a screen's width, their turn in radians, how far the
  /// front one rises in pixels and the sides drop as a share of the height,
  /// and how much smaller the sides are and how much larger the front grows
  /// as it is picked up.
  static const double workFanOffset = 0.62,
      workFanOpen = 0.3,
      workFanTurn = 0.14,
      workFanTurnOpen = 0.08,
      workFanRise = 6,
      workFanDrop = 0.04,
      workFanBackScale = 0.9,
      workFanForwardScale = 0.08;

  /// An app's page arriving: the whole sequence, how far apart its parts
  /// start (as a share of it) and how long each takes to rise.
  static const Duration appPageArrive = Duration(milliseconds: 1400);

  /// See [appPageArrive].
  static const double appPageStep = 0.08, appPageRise = 0.4;

  /// An app's page: the fan of screens beside the name, how the width is
  /// shared between the words and the screens, and how far the fan stands
  /// open at rest.
  static const double appPageArtHeight = 380, appPageFanRest = 0.6;

  /// See [appPageArtHeight].
  static const int appPageTextFlex = 5, appPageArtFlex = 4;

  /// The rule beside an app's headline result.
  static const double appPageHeadlineRule = 28;

  /// A fact card on an app's page: its narrowest, and its ringed mark.
  static const double appFactWidth = 220, appFactMark = 36;

  /// A card for another app from the same place: its narrowest, its screen's
  /// width, and how far the screen lifts under the pointer, as a share of
  /// its height.
  static const double appSiblingWidth = 220,
      appSiblingThumb = 40,
      appSiblingLift = 0.08;

  /// The pause between one Work card arriving and the next along its row.
  static const Duration workStagger = Duration(milliseconds: 90);

  /// The door to the courtyard on /about: the width below which the climb
  /// goes under the words, the climb's size (and on a phone), how far it
  /// stands in from the panel's edge, and how high it climbs before starting
  /// again.
  static const double doorSplitWidth = 720,
      doorClimbWidth = 240,
      doorClimbHeight = 220,
      doorClimbCompact = 200,
      doorClimbInset = 48,
      liveClimbRestart = 90;

  /// The scoreboard opened from the courtyard: its width, and how dark the
  /// page goes behind it.
  static const double boardDialogWidth = 440, boardBarrierAlpha = 0.8;

  /// The phone at the end of Home whose app is put together a part at a
  /// time: one build, lit, held and cleared; its width; its height as a
  /// multiple of the width.
  static const Duration appBuildCycle = Duration(milliseconds: 7000);

  /// See [appBuildCycle].
  static const double appBuildWidth = 150, appBuildAspect = 1.9;

  /// The closing panel is wide enough for the phone beside its two halves
  /// from this width.
  static const double closingIllustrationFrom = 1000;

  /// The beat between one Off duty tile rising in and the next.
  static const Duration interestStagger = Duration(milliseconds: 70);

  /// One lap of the light round the game's panel.
  static const Duration goldEdgeLap = Duration(milliseconds: 5200);

  /// The mark beside each service named in Home's closing panel.
  static const double serviceTagIconSize = 16;

  /// The stop's sign cut large into its card: its size, how faint, and how
  /// much of it runs off the card's edge.
  static const double careerReliefSize = 148,
      careerReliefAlpha = 0.07,
      careerReliefBleed = 0.28;

  /// The narrowest a career stop card may be in its grid.
  static const double stopCardMinWidth = 220;

  /// A stop on the Home timeline: the narrowest it may be before the line
  /// scrolls, its marker's size, and how much the marker grows under the
  /// pointer.
  static const double stopItemWidth = 132,
      stopNodeSize = 40,
      stopNodeLift = 1.12;

  /// The narrowest hero that gets the picture beside it. Below this the copy
  /// needs the width, and the picture would be a postage stamp.
  static const double heroSceneMinWidth = 900;

  /// How strongly the wall shows at rest when it is the whole page's
  /// background.
  ///
  /// On a wide screen the wall stopped being a column beside the copy and
  /// became the pattern behind everything, at the owner's suggestion. He
  /// suggested half; at half, and then at 0.3, the pale signs still ran
  /// through the grey positioning line in a browser -- they are light on dark,
  /// so they carry further than the number suggests. This is the resting
  /// strength only: the torch still lights a sign to full gold, so the carving
  /// comes up bright wherever the pointer holds the light and stays out of the
  /// way of the reading everywhere else.
  static const double wallPatternOpacity = 0.2;

  /// Where in the wave a gilded sign starts to bloom.
  static const double wallShimmerBloomAt = 0.62;

  /// How far it blooms at the peak.
  static const double wallShimmerBloom = 9;

  /// Opacity of the ornament field behind every page.
  ///
  /// Superseded by the per-theme `ornamentFieldAlpha`: four percent of a grey
  /// was in the file and invisible on the screen, and the two grounds do not
  /// take the same value. Kept because other surfaces still reference it.
  static const double ornamentFieldOpacity = 0.04;
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
  ornamentField: Color(0xFFE3A93F),
  ornamentFieldAlpha: 0.14,
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
  ornamentField: Color(0xFF7A5410),
  ornamentFieldAlpha: 0.17,
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

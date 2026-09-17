import 'dart:math' as math;

// `meta` rather than `flutter/foundation` on purpose. The physics is what a
// score is judged by, and it should be runnable by anything that runs Dart --
// the vector generator is a plain `dart run` script with no Flutter anywhere
// near it, and it could not be if this file reached for a UI framework to
// borrow one annotation.
import 'package:meta/meta.dart';

import 'package:nocturne/features/courtyard/game/domain/ascent_rng.dart';

/// What a ledge is made of, which decides how it behaves underfoot.
enum LedgeKind {
  /// Dressed limestone. Holds.
  stone,

  /// Weathered. Gives way one bounce after it is used.
  cracked,

  /// Carried by a scarab, so it drifts across the shaft.
  scarab,
}

/// One ledge in the shaft.
@immutable
class Ledge {
  /// Creates a ledge at [y] metres above the floor.
  const Ledge({
    required this.id,
    required this.kind,
    required this.x,
    required this.y,
    required this.width,
    this.drift = 0,
    this.isBroken = false,
    this.hasBoon = false,
    this.boonTaken = false,
  });

  /// Stable identity, so a ledge keeps its state as the world scrolls.
  final int id;

  /// What it is made of.
  final LedgeKind kind;

  /// Centre, 0..1 across the shaft.
  final double x;

  /// Height above the floor, in metres.
  final double y;

  /// Width as a fraction of the shaft.
  final double width;

  /// Horizontal travel per second, for a scarab ledge.
  final double drift;

  /// Whether a cracked ledge has already given way.
  final bool isBroken;

  /// Whether a gilded ankh floats above this ledge, waiting to be taken.
  ///
  /// Carried by the ledge rather than kept in a list of its own, so a boon
  /// recycles, drifts and sorts with the thing it belongs to. A parallel list
  /// would be a second collection to keep in step across two languages, and
  /// the first time it fell out of step would be a score nobody could explain.
  final bool hasBoon;

  /// Whether this ledge's boon has already been taken.
  final bool boonTaken;

  /// Where the boon floats, in metres above the shaft floor.
  double get boonY => y + AscentWorld.boonHeight;

  /// This ledge one frame later.
  Ledge advance(double dt) {
    if (kind != LedgeKind.scarab || drift == 0) return this;
    var next = x + drift * dt;
    var heading = drift;
    // The shaft has walls. A scarab turns rather than leaving the world.
    if (next < width / 2 || next > 1 - width / 2) {
      heading = -drift;
      next = next.clamp(width / 2, 1 - width / 2);
    }
    return Ledge(
      id: id,
      kind: kind,
      x: next,
      y: y,
      width: width,
      drift: heading,
      isBroken: isBroken,
      hasBoon: hasBoon,
      boonTaken: boonTaken,
    );
  }

  /// This ledge, given way.
  Ledge get broken => Ledge(
    id: id,
    kind: kind,
    x: x,
    y: y,
    width: width,
    drift: drift,
    isBroken: true,
    hasBoon: hasBoon,
    boonTaken: boonTaken,
  );

  /// This ledge, with its boon collected.
  Ledge get boonClaimed => Ledge(
    id: id,
    kind: kind,
    x: x,
    y: y,
    width: width,
    drift: drift,
    isBroken: isBroken,
    hasBoon: hasBoon,
    boonTaken: true,
  );

  /// Whether [climberX] is over this ledge.
  bool carries(double climberX) => (climberX - x).abs() <= width / 2;
}

/// The climb, as a pure value.
///
/// Physics and state live here rather than in the widget so the whole game can
/// be reasoned about, and stepped, without a ticker or a canvas anywhere near
/// it. `13-GAME-DESIGN.md`: one painter, one ticker, axis-aligned collision,
/// and no engine package.
@immutable
class AscentWorld {
  /// Creates a world. Use `AscentWorld.seeded` to start a run.
  const AscentWorld({
    required this.ledges,
    required this.climberX,
    required this.climberY,
    required this.velocity,
    required this.altitude,
    required this.best,
    required this.isPractice,
    required this.isOver,
    required this.nextLedgeId,
    required this.registersPassed,
    this.seed = 0,
    this.brokeLedge = false,
    this.isGrounded = false,
    this.wasWalled = false,
    this.floorY = -_fallMargin,
    this.kickedWall = false,
    this.horizontalVelocity = 0,
    this.coyoteFor = 0,
    this.jumpQueuedFor = 0,
    this.jumpHeld = false,
    this.jumpConsumed = false,
    this.landingAge = 1,
    this.landed = false,
    this.lastKickSide = 0,
    this.boonFor = 0,
    this.tookBoon = false,
    this.boonsTaken = 0,
  });

  /// A fresh run.
  factory AscentWorld.seeded({
    required int best,
    required bool isPractice,
    int seed = 0,
  }) {
    final ledges = <Ledge>[
      // A floor wide enough that the first bounce cannot be missed.
      const Ledge(id: 0, kind: LedgeKind.stone, x: 0.5, y: 0, width: 0.9),
    ];
    for (var i = 1; i < _ledgeCount; i++) {
      ledges.add(_generate(i, i * ledgeGap, AscentRng.ledge(seed, i)));
    }
    return AscentWorld(
      seed: seed,
      ledges: ledges,
      climberX: 0.5,
      climberY: 1,
      velocity: 0,
      altitude: 0,
      best: best,
      isPractice: isPractice,
      isOver: false,
      nextLedgeId: _ledgeCount,
      registersPassed: 0,
    );
  }

  /// The number the whole shaft is derived from.
  ///
  /// Every ledge in the run is a pure function of this and its own id, so two
  /// machines handed the same seed build the same climb without exchanging
  /// anything else.
  final int seed;

  /// Ledges currently in play, lowest first.
  final List<Ledge> ledges;

  /// The climber's position across the shaft, 0..1.
  final double climberX;

  /// The climber's height above the floor, in metres.
  final double climberY;

  /// Vertical speed, metres per second.
  final double velocity;

  /// The highest point reached this run.
  final double altitude;

  /// The best altitude on this device.
  final int best;

  /// Whether falling is survivable.
  final bool isPractice;

  /// Whether the run has ended.
  final bool isOver;

  /// Identity for the next ledge generated.
  final int nextLedgeId;

  /// How many register bands have been passed.
  final int registersPassed;

  /// Whether a ledge gave way on the step that produced this world.
  ///
  /// Reported rather than played: the world stays a pure value with no idea a
  /// speaker exists, and presentation decides what a broken ledge sounds like.
  final bool brokeLedge;

  /// Whether the climber is standing on something.
  ///
  /// Landing settles rather than bouncing, so this is what space acts on.
  final bool isGrounded;

  /// Whether the climber was already touching a wall on the previous step.
  ///
  /// A kick is worth height, so it has to cost contact: without this a player
  /// could hold one direction and ride an edge to the top.
  final bool wasWalled;

  /// The height below which a run ends, in metres.
  ///
  /// It rises on its own, faster at every level, which is what turns a climb
  /// anyone could take slowly into one with a pace.
  final double floorY;

  /// Whether this step kicked off a wall, for the sound and the flourish.
  final bool kickedWall;

  /// Horizontal momentum; released controls brake instead of snapping.
  final double horizontalVelocity;

  /// Remaining seconds of grace after leaving a ledge.
  final double coyoteFor;

  /// Remaining seconds of an early jump request.
  final double jumpQueuedFor;

  /// Previous frame's input, for one jump per press.
  final bool jumpHeld;

  /// A held input cannot automatically jump again after landing.
  final bool jumpConsumed;

  /// Time since landing, used only for the character's spring pose.
  final double landingAge;

  /// A fresh landing event, independent of holding a control.
  final bool landed;

  /// The same wall cannot grant repeated boosts before a landing.
  final int lastKickSide;

  /// Seconds of lifted jump remaining from a boon.
  ///
  /// Part of the physics, not of the presentation: it changes how high a press
  /// goes, so it is replayed on the server like everything else a score depends
  /// on. A timed effect that lived only in the widget would make a verified
  /// height disagree with the one on the screen.
  final double boonFor;

  /// Whether a boon was taken on the step that produced this world.
  final bool tookBoon;

  /// How many boons this run has taken.
  ///
  /// Part of the outcome rather than a statistic. If the two implementations
  /// ever disagree about whether the climber passed near enough to an ankh,
  /// the height would only differ once the extra lift had changed a landing --
  /// a hundred metres later, or never on the run that happened to be recorded.
  /// Counting them makes the disagreement itself the failure.
  final int boonsTaken;

  /// Whether the jump is currently lifted.
  bool get hasBoon => boonFor > 0;

  static const double _inputGrace = 0.14;
  static const double _acceleration = 7;
  static const double _braking = 9;
  static const double _shortJumpSpeed = 9.5;

  /// Metres between ledges.
  static const double ledgeGap = 2.6;

  /// How much taller a wall kick is than a standing jump.
  static const double _wallBoost = 1.34;

  /// Metres climbed before the pace steps up.
  static const double levelHeight = 100;

  /// Metres between one step up in difficulty and the next.
  ///
  /// Separate from [levelHeight] on purpose: the owner asked for the climb to
  /// get harder every fifty metres and to reach a new level every hundred, so
  /// a level is two steps of pace rather than one. The floor accelerating and
  /// the shaft changing character are different events, and tying them to one
  /// number made the first fifty metres as hard as the second.
  static const double difficultyStep = 50;

  /// How wide the ledges are on the first level.
  ///
  /// Nearly half the shaft, before the spread. The owner's complaint was that
  /// the climb begins by dropping you off the edge of a narrow platform before
  /// you have learned anything; down here they overlap enough that a jump lands
  /// on something whatever you do with the steering.
  static const double openingWidth = 0.42;

  /// How much the opening ledges vary in width.
  static const double openingSpread = 0.14;

  /// Below this height no boon is placed.
  ///
  /// The first fifty metres are for finding out what the jump does. A power-up
  /// that changes what the jump does, offered before that, teaches the wrong
  /// jump.
  static const double boonFloor = 50;

  /// How often a ledge above [boonFloor] carries a boon.
  static const double boonChance = 0.13;

  /// How far above its ledge a boon floats, in metres.
  ///
  /// Reachable from the ledge below without a running start, and low enough
  /// that it sits inside the arc of an ordinary jump rather than beside it.
  static const double boonHeight = 1.3;

  /// How near, across the shaft, the climber must pass to take a boon.
  static const double boonReachX = 0.09;

  /// How near, in metres, the climber must pass to take a boon.
  static const double boonReachY = 0.85;

  /// How long a boon lifts the jump, in seconds.
  ///
  /// The owner asked for ten, and ten is right for a different reason: the
  /// climb covers roughly twenty-five metres in that time, which is long enough
  /// to be worth going out of the way for and short enough that the run does
  /// not become a different game.
  static const double boonSeconds = 10;

  /// How much taller a jump is while a boon burns.
  ///
  /// A little more than the wall kick. It has to be plainly better than the
  /// jump it replaces or there is no reason to reach for one, and plainly worse
  /// than flight or there is no reason to land.
  static const double boonLift = 1.42;

  /// How fast the floor rises at difficulty [step], in metres per second.
  ///
  /// Zero for the first fifty metres: the opening stretch is where the controls
  /// are learned, and a floor chasing a player who has not worked out the jump
  /// yet is just a short run. After that it climbs by a step every fifty
  /// metres, linearly rather than exponentially, so the top of the shaft is
  /// hard rather than impossible.
  static double _floorSpeed(int step) => step == 0 ? 0 : 0.4 + step * 0.34;

  /// Metres between register bands, each of which unlocks one fact.
  static const double registerGap = 24;

  /// How many ledges are kept in play at once.
  static const int _ledgeCount = 40;

  /// Upward speed given by a jump, metres per second.
  ///
  /// Set against the ledge spacing rather than picked: at 13 the apex is
  /// 3.84m, which is 1.48 gaps, so one press clears the next ledge with room
  /// to steer under it. It was 11, whose apex of 2.75m against a 2.6m gap left
  /// 15cm of margin, and a climb that needs a pixel-perfect landing every time
  /// is not a climb.
  static const double _bounce = 13;

  /// Gravity, metres per second squared.
  static const double _gravity = 22;

  /// Sideways speed, in shaft-widths per second.
  static const double _steerRate = 1.15;

  /// How far below the view the climber may fall before a run ends.
  static const double _fallMargin = 14;

  /// Advances the world by [dt] seconds.
  ///
  /// [steer] is -1, 0 or 1. [isLeaping] is the space bar. The whole game is
  /// this function; everything else draws its result.
  ///
  /// The bounce used to be automatic, as it is in the game this was modelled
  /// on: the climber was never told to jump, only where to go. The owner's
  /// objection was that the character was therefore jumping the entire time
  /// with nothing asked of the player, so landing settles now and space is
  /// what leaves the ground. Dive went with it: it existed because the only
  /// way to come down deliberately was to force it, and not jumping is now how
  /// you stay put.
  AscentWorld step({
    required double dt,
    required double steer,
    bool isLeaping = false,
  }) {
    if (isOver) return this;

    // The rising floor. Every level it climbs faster, and falling below it
    // ends the run, so the climb stops being something a patient player can
    // take at their own pace forever.
    final rise = _floorSpeed(difficulty) * dt;

    // How high a press goes this tick. Read from the state coming in rather
    // than from the state going out, so a boon taken on the way up does not
    // retroactively raise the jump that reached it.
    final lift = boonFor > 0 ? boonLift : 1.0;

    // Sideways first. Reaching a wall is worth something now: it kicks the
    // climber back with more height than a standing jump, which is the trick
    // the tower games are built on and the reason to steer wide rather than
    // straight up.
    final target = steer.clamp(-1.0, 1.0) * _steerRate;
    final change = (steer == 0 ? _braking : _acceleration) * dt;
    var horizontal =
        horizontalVelocity +
        (target - horizontalVelocity).clamp(-change, change);
    var x = climberX + horizontal * dt;
    var grace = isGrounded ? _inputGrace : math.max<double>(0, coyoteFor - dt);
    var queued = isLeaping && !jumpHeld
        ? _inputGrace
        : math.max<double>(0, jumpQueuedFor - dt);
    var consumed = isLeaping && jumpConsumed;
    var walled = false;
    if (x <= 0) {
      x = 0;
      walled = true;
    }
    if (x >= 1) {
      x = 1;
      walled = true;
    }

    var speed = velocity - _gravity * dt;
    if (!isLeaping && jumpHeld && jumpConsumed && speed > _shortJumpSpeed) {
      speed = _shortJumpSpeed;
    }
    var y = climberY + speed * dt;
    var grounded = false;
    var kicked = false;
    var kickSide = isGrounded ? 0 : lastKickSide;

    // A wall kick only counts on the way up, and only once per contact: a
    // climber grinding along an edge would otherwise ride it to the top.
    if (walled && speed > 0 && !wasWalled && kickSide != (x == 0 ? -1 : 1)) {
      kickSide = x == 0 ? -1 : 1;
      speed = _bounce * _wallBoost * lift;
      kicked = true;
      horizontal = x == 0 ? _steerRate : -_steerRate;
    }

    final live = [for (final ledge in ledges) ledge.advance(dt)];
    var broke = false;

    // Buffered input survives a slightly early press; coyote time survives
    // a slightly late one. A held key is consumed after one launch.
    final requested = queued > 0 || (isLeaping && !consumed);
    if (requested && grace > 0 && !consumed && !kicked) {
      speed = _bounce * lift;
      y = climberY + speed * dt;
      grace = 0;
      queued = 0;
      consumed = true;
    }
    var touchedDown = false;

    // Only ever falling, and only from above: a climber rising through a ledge
    // passes it, which is what makes the ascent readable rather than a trap.
    if (speed < 0) {
      for (var i = live.length - 1; i >= 0; i--) {
        final ledge = live[i];
        if (ledge.isBroken) continue;
        final crossed = climberY >= ledge.y && y <= ledge.y;
        if (!crossed || !ledge.carries(x)) continue;

        y = ledge.y;
        // Landing no longer throws the climber back up on its own. It used to
        // bounce automatically, which is Ice Tower's rule and, as the owner
        // put it, meant the character was jumping the whole time with nothing
        // asked of the player. A landing settles; space is what leaves the
        // ground.
        speed = 0;
        grounded = true;
        touchedDown = !isGrounded;
        grace = _inputGrace;
        if (queued > 0 && !consumed) {
          speed = _bounce * lift;
          grounded = false;
          grace = 0;
          queued = 0;
          consumed = true;
        }
        if (ledge.kind == LedgeKind.cracked) {
          live[i] = ledge.broken;
          broke = true;
        }
        break;
      }
    }

    // Boons, taken by passing through them.
    //
    // Run over `live` rather than over the recycled list on purpose: a ledge is
    // only recycled once it is twice the fall margin below the floor, which is
    // twenty-eight metres down, and nothing within a metre of the climber is
    // ever in that set. Doing it here means one place mutates the ledge list
    // and the recycler downstream never has to know a boon exists.
    //
    // One per tick. Two ankhs close enough to be inside the same reach is
    // possible and vanishingly rare, and taking both on one tick would spend
    // the second one for no extra time -- the timer is set, not added to.
    var tookOne = false;
    for (var i = 0; i < live.length; i++) {
      final ledge = live[i];
      if (!ledge.hasBoon || ledge.boonTaken) continue;
      if ((x - ledge.x).abs() > boonReachX) continue;
      if ((y - ledge.boonY).abs() > boonReachY) continue;
      live[i] = ledge.boonClaimed;
      tookOne = true;
      break;
    }
    // Set rather than extended. Stacking would make a lucky row of ankhs into
    // a minute of flight, which is a different game from the one above it.
    final boonLeft = tookOne ? boonSeconds : math.max<double>(0, boonFor - dt);

    final reached = math.max(altitude, y);
    final registers = (reached / registerGap).floor();
    final risenFloor = math.max(floorY + rise, reached - _fallMargin);

    // Recycle ledges that have dropped well below, so the list stays a fixed
    // size however far the climb goes.
    final floor = risenFloor - _fallMargin * 2;
    final kept = <Ledge>[];
    var nextId = nextLedgeId;
    var highest = 0.0;
    for (final ledge in live) {
      highest = math.max(highest, ledge.y);
    }
    for (final ledge in live) {
      if (ledge.y >= floor) {
        kept.add(ledge);
        continue;
      }
      highest += ledgeGap;
      kept.add(_generate(nextId, highest, AscentRng.ledge(seed, nextId)));
      nextId++;
    }
    // By height, then by id. Two ledges at one height is unlikely and not
    // impossible, and `sort` is not stable, so leaving the tie to it would put
    // the order of the list — and therefore which ledge a fall lands on — at
    // the mercy of an implementation detail on each side of the replay.
    kept.sort((a, b) {
      final byHeight = a.y.compareTo(b.y);
      return byHeight != 0 ? byHeight : a.id.compareTo(b.id);
    });

    final fallen = y < risenFloor;
    if (fallen && isPractice) {
      // Practice mode never ends. The climber is set back down on the highest
      // ledge below, so the whole shaft stays reachable at the player's pace.
      final below = kept.where((ledge) => ledge.y <= reached).toList();
      final landing = below.isEmpty ? kept.first : below.last;
      return _copy(
        ledges: kept,
        climberX: landing.x,
        climberY: landing.y,
        velocity: 0,
        altitude: reached,
        nextLedgeId: nextId,
        registersPassed: registers,
        isGrounded: true,
        wasWalled: false,
        floorY: risenFloor,
        brokeLedge: broke,
        boonFor: boonLeft,
        tookBoon: tookOne,
        boonsTaken: boonsTaken + (tookOne ? 1 : 0),
      );
    }

    return _copy(
      ledges: kept,
      climberX: x,
      climberY: y,
      velocity: speed,
      altitude: reached,
      isOver: fallen,
      nextLedgeId: nextId,
      registersPassed: registers,
      brokeLedge: broke,
      isGrounded: grounded,
      wasWalled: walled,
      floorY: risenFloor,
      kickedWall: kicked,
      horizontalVelocity: horizontal,
      coyoteFor: grace,
      jumpQueuedFor: queued,
      jumpHeld: isLeaping,
      jumpConsumed: consumed,
      landingAge: touchedDown ? 0 : landingAge + dt,
      landed: touchedDown,
      lastKickSide: touchedDown ? 0 : kickSide,
      boonFor: boonLeft,
      tookBoon: tookOne,
      boonsTaken: boonsTaken + (tookOne ? 1 : 0),
    );
  }

  /// The run's score, in whole metres.
  int get metres => altitude.floor();

  /// How far into the climb the pace has stepped up.
  int get level => (altitude / levelHeight).floor();

  /// How many steps of pace the climb has taken, one every fifty metres.
  int get difficulty => (altitude / difficultyStep).floor();

  /// How near the rising floor is, 0 when it is far off and 1 when it is level.
  ///
  /// Presentation reads this to make the shaft feel like it is closing in. The
  /// owner's note was that there is no sense of the clock running out, and the
  /// reason is that the floor is drawn faithfully and faithfully is invisible:
  /// it is below the frame for most of a run, so the thing that is about to end
  /// it makes no sound and casts no light until it arrives.
  double get danger {
    final gap = climberY - floorY;
    if (gap >= _dangerFrom) return 0;
    if (gap <= 0) return 1;
    return 1 - gap / _dangerFrom;
  }

  /// How far above the floor the climber starts to feel it, in metres.
  ///
  /// About half a screen: near enough that the warning means something, far
  /// enough that a run does not spend its whole length flashing.
  static const double _dangerFrom = 9;

  /// Whether this run beat the stored best.
  bool get isRecord => metres > best;

  /// Builds the ledge at [y], in the character its level calls for.
  ///
  /// Each hundred metres is a different shaft, which is the owner's "new level
  /// with a different mode". They are introductions rather than difficulty
  /// dials: one new thing per level, in the order that teaches it.
  ///
  /// - **I, the dressed shaft.** Stone, and wide enough that a jump lands on
  ///   something whatever the steering does. Nothing gives way, nothing moves.
  ///   The only thing that changes is the floor, which starts rising at fifty.
  /// - **II, the weathered shaft.** Cracked ledges, which hold for one landing.
  ///   Narrower, now that standing still is no longer an option.
  /// - **III, the scarab shaft.** Ledges carried across the shaft, so a landing
  ///   spot has to be aimed at where it will be rather than where it is.
  /// - **IV and above, the deep shaft.** All three at once, at the narrowest
  ///   the ledges get. It does not keep narrowing past here: a shaft that
  ///   tightens forever ends every run at the same wall, and the floor is
  ///   already the thing that ends runs.
  ///
  /// The draws happen in a fixed order — kind, width, position, drift, boon —
  /// because `worker/src/game/ascent.js` draws them in that same order from the
  /// same generator, and a stream read out of step is a different shaft.
  /// The ledge with [id] at [y] in the shaft seeded [seed].
  ///
  /// Public because it is contract surface rather than an internal helper: the
  /// fixture generator samples it across every level so that the mode changes
  /// are *proven* to agree with `worker/src/game/ascent.js`, instead of being
  /// inferred from a recorded run that happened to climb high enough to meet
  /// them. Levels three and four are not reachable by any vector the bot
  /// produces, so without this they would be two hundred metres of shaft that
  /// nothing on either side had ever checked.
  static Ledge generate(int id, double y, int seed) =>
      _generate(id, y, AscentRng.ledge(seed, id));

  static Ledge _generate(int id, double y, AscentRng random) {
    final level = (y / levelHeight).floor();
    final roll = random.nextDouble();
    final kind = switch (level) {
      <= 0 => LedgeKind.stone,
      1 => roll < 0.60 ? LedgeKind.stone : LedgeKind.cracked,
      2 => roll < 0.58 ? LedgeKind.stone : LedgeKind.scarab,
      _ =>
        roll < 0.54
            ? LedgeKind.stone
            : roll < 0.80
            ? LedgeKind.cracked
            : LedgeKind.scarab,
    };
    final (double narrowest, double spread) = switch (level) {
      <= 0 => (openingWidth, openingSpread),
      1 => (0.25, 0.14),
      2 => (0.20, 0.13),
      _ => (0.16, 0.12),
    };
    final width = narrowest + random.nextDouble() * spread;
    final x = width / 2 + random.nextDouble() * (1 - width);
    final drift = kind == LedgeKind.scarab
        ? (random.nextDouble() < 0.5 ? 0.16 : -0.16)
        : 0.0;
    // Drawn whether or not it can be used. `&&` would short-circuit the draw
    // below the boon floor and leave the two implementations reading the same
    // stream from different positions, which is the kind of divergence that
    // shows up as one unexplainable rejected score a month from now.
    final boonRoll = random.nextDouble();
    return Ledge(
      id: id,
      kind: kind,
      x: x,
      y: y,
      width: width,
      drift: drift,
      hasBoon: y >= boonFloor && boonRoll < boonChance,
    );
  }

  AscentWorld _copy({
    List<Ledge>? ledges,
    double? climberX,
    double? climberY,
    double? velocity,
    double? altitude,
    bool? isOver,
    int? nextLedgeId,
    int? registersPassed,
    bool brokeLedge = false,
    bool? isGrounded,
    bool? wasWalled,
    double? floorY,
    bool kickedWall = false,
    double? horizontalVelocity,
    double? coyoteFor,
    double? jumpQueuedFor,
    bool? jumpHeld,
    bool? jumpConsumed,
    double? landingAge,
    bool landed = false,
    int? lastKickSide,
    double? boonFor,
    bool tookBoon = false,
    int? boonsTaken,
  }) => AscentWorld(
    seed: seed,
    ledges: ledges ?? this.ledges,
    climberX: climberX ?? this.climberX,
    climberY: climberY ?? this.climberY,
    velocity: velocity ?? this.velocity,
    altitude: altitude ?? this.altitude,
    best: best,
    isPractice: isPractice,
    isOver: isOver ?? this.isOver,
    nextLedgeId: nextLedgeId ?? this.nextLedgeId,
    registersPassed: registersPassed ?? this.registersPassed,
    isGrounded: isGrounded ?? this.isGrounded,
    wasWalled: wasWalled ?? this.wasWalled,
    floorY: floorY ?? this.floorY,
    kickedWall: kickedWall,
    brokeLedge: brokeLedge,
    horizontalVelocity: horizontalVelocity ?? this.horizontalVelocity,
    coyoteFor: coyoteFor ?? this.coyoteFor,
    jumpQueuedFor: jumpQueuedFor ?? this.jumpQueuedFor,
    jumpHeld: jumpHeld ?? this.jumpHeld,
    jumpConsumed: jumpConsumed ?? this.jumpConsumed,
    landingAge: landingAge ?? this.landingAge,
    landed: landed,
    lastKickSide: lastKickSide ?? this.lastKickSide,
    boonFor: boonFor ?? this.boonFor,
    tookBoon: tookBoon,
    boonsTaken: boonsTaken ?? this.boonsTaken,
  );
}

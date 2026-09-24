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

/// A sacred sign floating above a ledge, taken by passing through it.
///
/// Three, each the sign for what it gives, and each placed on its own
/// schedule rather than at random ledges, so they arrive about as often as the
/// owner asked for and never in a clump:
///
/// - **The ankh**, life: an extra life. Rare -- one every hundred to a
///   hundred and fifty metres.
/// - **The eye of Horus**, protection: the rising floor slows for ten
///   seconds. About every fifty metres.
/// - **Ma'at's feather**, lightness: for five seconds a press in mid-air is a
///   jump, twice before landing -- the triple jump. As often as the eye.
enum Relic {
  /// An extra life.
  ankh,

  /// The floor slows.
  eye,

  /// Two more jumps in the air.
  feather,
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
    this.isLanding = false,
    this.relic,
    this.relicTaken = false,
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

  /// Whether this is the full-width ledge a level begins on.
  ///
  /// The owner asked for every level to open on a floor the whole width of
  /// the shaft: a moment to stand on something before the new rules start.
  final bool isLanding;

  /// The sign floating above this ledge, if any.
  ///
  /// Carried by the ledge rather than kept in a list of its own, so a relic
  /// recycles, drifts and sorts with the thing it belongs to. A parallel list
  /// would be a second collection to keep in step across two languages, and
  /// the first time it fell out of step would be a score nobody could explain.
  final Relic? relic;

  /// Whether this ledge's relic has already been taken.
  final bool relicTaken;

  /// Where the relic floats, in metres above the shaft floor.
  double get relicY => y + AscentWorld.relicHeight;

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
    return _with(x: next, drift: heading);
  }

  /// This ledge, given way.
  Ledge get broken => _with(isBroken: true);

  /// This ledge, with its relic collected.
  Ledge get relicClaimed => _with(relicTaken: true);

  Ledge _with({double? x, double? drift, bool? isBroken, bool? relicTaken}) =>
      Ledge(
        id: id,
        kind: kind,
        x: x ?? this.x,
        y: y,
        width: width,
        drift: drift ?? this.drift,
        isBroken: isBroken ?? this.isBroken,
        isLanding: isLanding,
        relic: relic,
        relicTaken: relicTaken ?? this.relicTaken,
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
    this.time = 0,
    this.lives = 0,
    this.eyeFor = 0,
    this.featherFor = 0,
    this.airJumps = 0,
    this.relicsTaken = 0,
    this.livesLost = 0,
    this.tookRelic,
    this.lostLife = false,
    this.won = false,
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
      ledges.add(_generate(i, i * ledgeGap, AscentRng.ledge(seed, i), seed));
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

  /// Seconds the run has lasted: the clock the sand's wind blows by.
  ///
  /// A sum of exact ticks, so it is exact too, and the same number on both
  /// sides of the replay.
  final double time;

  /// Extra lives in hand, from ankhs.
  final int lives;

  /// Seconds left of the eye's slowed floor.
  final double eyeFor;

  /// Seconds left of the feather's jumps in the air.
  final double featherFor;

  /// How many of the feather's jumps have been used since the last landing.
  final int airJumps;

  /// How many relics this run has taken.
  ///
  /// Part of the outcome rather than a statistic. If the two implementations
  /// ever disagree about whether the climber passed near enough to a relic,
  /// the height would only differ once its effect had changed a landing -- a
  /// hundred metres later, or never on the run that happened to be recorded.
  /// Counting them makes the disagreement itself the failure.
  final int relicsTaken;

  /// How many lives this run has spent.
  final int livesLost;

  /// The relic taken on the step that produced this world, if one was.
  final Relic? tookRelic;

  /// Whether a life was spent on the step that produced this world.
  final bool lostLife;

  /// Whether the climb reached the summit: the only way a run ends well.
  final bool won;

  /// Whether the floor is slowed.
  bool get hasEye => eyeFor > 0;

  /// Whether a press in mid-air is a jump.
  bool get hasFeather => featherFor > 0;

  /// See the constant above: part of the same rule.
  static const double _inputGrace = 0.14;

  /// See the constant above: part of the same rule.
  static const double _acceleration = 7;

  /// See the constant above: part of the same rule.
  static const double _braking = 9;

  /// See the constant above: part of the same rule.
  static const double _shortJumpSpeed = 9.5;

  /// Metres between ledges.
  static const double ledgeGap = 2.6;

  /// How much taller a wall kick is than a standing jump.
  static const double _wallBoost = 1.34;

  /// Metres in a level.
  static const double levelHeight = 100;

  /// How many levels the shaft has. The top of the last is the summit.
  static const int levelCount = 8;

  /// The height that wins the climb, in metres.
  static const double summit = levelHeight * levelCount;

  /// Metres between one step up in difficulty and the next.
  ///
  /// Separate from [levelHeight] on purpose: the owner asked for the climb to
  /// get harder every fifty metres and to reach a new level every hundred, so
  /// a level is two steps of pace rather than one.
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

  /// How far above its ledge a relic floats, in metres.
  ///
  /// Reachable from the ledge below without a running start, and low enough
  /// that it sits inside the arc of an ordinary jump rather than beside it.
  static const double relicHeight = 1.3;

  /// How near, across the shaft, the climber must pass to take a relic.
  static const double relicReachX = 0.09;

  /// How near, in metres, the climber must pass to take a relic.
  static const double relicReachY = 0.85;

  /// How long the eye slows the floor, and to what share of its pace.
  static const double eyeSeconds = 10;

  /// See the constant above: part of the same rule.
  static const double eyeSlow = 0.3;

  /// How long the feather lasts, in seconds.
  static const double featherSeconds = 5;

  /// Jumps the feather adds in the air: with the one from the ledge, three.
  static const int featherJumps = 2;

  /// The most extra lives a climber may hold.
  static const int maxLives = 3;

  /// How far below a climber a spent life sets the floor, in metres.
  static const double lifeClearance = 6;

  /// The sand's wind: its strongest push, in shaft-widths per second, and
  /// the seconds it takes to swing from one side to the other and back.
  ///
  /// It pushes only in the air, so a jump lands a little off where it was
  /// aimed -- the owner's "slightly inaccurate jumps" -- and a player standing
  /// still is never blown off a ledge.
  static const double windMax = 0.18;

  /// See the constant above: part of the same rule.
  static const double windPeriod = 5.5;

  /// How much grip the ice leaves, as a share of the usual: the climber
  /// slides rather than stops.
  static const double iceGrip = 0.2;

  /// The fastest the floor ever rises, in metres per second. High enough to
  /// make the last levels a race, low enough that a good climber can win it.
  static const double floorCap = 5;

  /// Where each relic is placed: one to a band of the shaft, somewhere in a
  /// window of it, so they come about as often as the owner asked and never
  /// in a clump. Each band draws from a stream of its own, keyed far from
  /// any ledge id.
  static const double ankhBand = 125;

  /// See the constant above: part of the same rule.
  static const double ankhOffset = 25;

  /// See the constant above: part of the same rule.
  static const double ankhWindow = 25;

  /// See [ankhBand].
  static const double eyeBand = 50;

  /// See the constant above: part of the same rule.
  static const double eyeOffset = 5;

  /// See the constant above: part of the same rule.
  static const double eyeWindow = 15;

  /// See [ankhBand].
  static const double featherBand = 50;

  /// See the constant above: part of the same rule.
  static const double featherOffset = 30;

  /// See the constant above: part of the same rule.
  static const double featherWindow = 15;

  /// See [ankhBand].
  static const int ankhStream = 0x40000000;

  /// See the constant above: part of the same rule.
  static const int eyeStream = 0x50000000;

  /// See the constant above: part of the same rule.
  static const int featherStream = 0x60000000;

  /// The first band with an eye in it: below fifty metres the floor does not
  /// move, so an eye there would slow nothing.
  static const int eyeFirstBand = 1;

  /// How fast the floor rises at difficulty [step], in metres per second.
  ///
  /// Zero for the first fifty metres: the opening stretch is where the controls
  /// are learned, and a floor chasing a player who has not worked out the jump
  /// yet is just a short run. After that it climbs by a step every fifty
  /// metres, to a cap, so the top of the shaft is hard rather than impossible.
  static double _floorSpeed(int step) =>
      step == 0 ? 0 : math.min(0.4 + step * 0.34, floorCap);

  /// Metres between register bands, each of which unlocks one fact.
  static const double registerGap = 24;

  /// How many ledges are kept in play at once.
  static const int _ledgeCount = 40;

  /// Upward speed given by a jump, metres per second.
  ///
  /// Set against the ledge spacing rather than picked: at 13 the apex is
  /// 3.84m, which is 1.48 gaps, so one press clears the next ledge with room
  /// to steer under it.
  static const double _bounce = 13;

  /// Gravity, metres per second squared.
  static const double _gravity = 22;

  /// Sideways speed, in shaft-widths per second.
  static const double _steerRate = 1.15;

  /// How far below the view the climber may fall before a run ends.
  static const double _fallMargin = 14;

  /// The level a height is in, 0 to 7.
  static int levelOf(double y) =>
      (y / levelHeight).floor().clamp(0, levelCount - 1);

  /// Whether the wind blows in [level]: the sands, and the last climb.
  static bool isWindy(int level) => level == 1 || level == 7;

  /// Whether the ledges are ice in [level]: the frozen Nile, and the last.
  static bool isIcy(int level) => level == 2 || level == 7;

  /// The wind's push at [time], in shaft-widths per second.
  ///
  /// A triangle wave, not a sine: floor, subtraction and a product are exact
  /// in both languages, and a library `sin` is not promised to agree with
  /// another language's to the last bit.
  static double windAt(double time) {
    final u = time / windPeriod;
    final f = u - u.floor();
    return windMax * (1 - 4 * (f - 0.5).abs());
  }

  /// Advances the world by [dt] seconds.
  ///
  /// [steer] is -1, 0 or 1. [isLeaping] is the space bar. The whole game is
  /// this function; everything else draws its result.
  AscentWorld step({
    required double dt,
    required double steer,
    bool isLeaping = false,
  }) {
    if (isOver) return this;

    final level = levelOf(climberY);
    final now = time + dt;

    // The rising floor. Every step of difficulty it climbs faster, and falling
    // below it ends the run; the eye slows it while it burns.
    final rise = _floorSpeed(difficulty) * dt * (eyeFor > 0 ? eyeSlow : 1.0);

    // Sideways first. On ice the climber's grip is a fraction of the usual,
    // so a stop is a slide.
    final target = steer.clamp(-1.0, 1.0) * _steerRate;
    final grip = isGrounded && isIcy(level) ? iceGrip : 1.0;
    final change = (steer == 0 ? _braking : _acceleration) * dt * grip;
    var horizontal =
        horizontalVelocity +
        (target - horizontalVelocity).clamp(-change, change);
    var x = climberX + horizontal * dt;
    // In the sands the wind carries a jump off its line.
    if (!isGrounded && isWindy(level)) x = x + windAt(time) * dt;
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
    var airUsed = isGrounded ? 0 : airJumps;

    // A wall kick only counts on the way up, and only once per contact: a
    // climber grinding along an edge would otherwise ride it to the top.
    if (walled && speed > 0 && !wasWalled && kickSide != (x == 0 ? -1 : 1)) {
      kickSide = x == 0 ? -1 : 1;
      speed = _bounce * _wallBoost;
      kicked = true;
      horizontal = x == 0 ? _steerRate : -_steerRate;
    }

    final live = [for (final ledge in ledges) ledge.advance(dt)];
    var broke = false;

    // Buffered input survives a slightly early press; coyote time survives
    // a slightly late one. A held key is consumed after one launch.
    final requested = queued > 0 || (isLeaping && !consumed);
    var jumped = false;
    if (requested && grace > 0 && !consumed && !kicked) {
      speed = _bounce;
      y = climberY + speed * dt;
      grace = 0;
      queued = 0;
      consumed = true;
      jumped = true;
    }
    // The feather: while it lasts a fresh press in mid-air is a jump, twice
    // before landing.
    if (!jumped &&
        !kicked &&
        featherFor > 0 &&
        isLeaping &&
        !jumpHeld &&
        grace <= 0 &&
        airUsed < featherJumps) {
      speed = _bounce;
      y = climberY + speed * dt;
      queued = 0;
      consumed = true;
      airUsed = airUsed + 1;
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
        // A landing settles; space is what leaves the ground.
        speed = 0;
        grounded = true;
        touchedDown = !isGrounded;
        grace = _inputGrace;
        airUsed = 0;
        if (queued > 0 && !consumed) {
          speed = _bounce;
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

    // Relics, taken by passing through them. Over `live` rather than the
    // recycled list: nothing within a metre of the climber is ever recycled,
    // so one place mutates the ledges and the recycler never has to know a
    // relic exists. One per tick; a timer is set, never extended.
    Relic? took;
    for (var i = 0; i < live.length; i++) {
      final ledge = live[i];
      final relic = ledge.relic;
      if (relic == null || ledge.relicTaken) continue;
      if ((x - ledge.x).abs() > relicReachX) continue;
      if ((y - ledge.relicY).abs() > relicReachY) continue;
      live[i] = ledge.relicClaimed;
      took = relic;
      break;
    }
    final livesNow = took == Relic.ankh ? math.min(lives + 1, maxLives) : lives;
    final eyeLeft = took == Relic.eye
        ? eyeSeconds
        : math.max<double>(0, eyeFor - dt);
    final featherLeft = took == Relic.feather
        ? featherSeconds
        : math.max<double>(0, featherFor - dt);
    final relics = relicsTaken + (took == null ? 0 : 1);

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
      kept.add(_generate(nextId, highest, AscentRng.ledge(seed, nextId), seed));
      nextId++;
    }
    // By height, then by id. `sort` is not stable, so leaving a tie to it
    // would put the order of the list -- and therefore which ledge a fall
    // lands on -- at the mercy of an implementation detail on each side.
    kept.sort((a, b) {
      final byHeight = a.y.compareTo(b.y);
      return byHeight != 0 ? byHeight : a.id.compareTo(b.id);
    });

    // The summit. The only way a run ends well.
    if (reached >= summit) {
      return _copy(
        ledges: kept,
        climberX: x,
        climberY: y,
        velocity: speed,
        altitude: reached,
        isOver: true,
        won: true,
        nextLedgeId: nextId,
        registersPassed: registers,
        floorY: risenFloor,
        time: now,
        lives: livesNow,
        eyeFor: eyeLeft,
        featherFor: featherLeft,
        relicsTaken: relics,
        tookRelic: took,
      );
    }

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
        time: now,
        lives: livesNow,
        eyeFor: eyeLeft,
        featherFor: featherLeft,
        airJumps: 0,
        relicsTaken: relics,
        tookRelic: took,
      );
    }

    if (fallen && livesNow > 0) {
      // A life, spent: back on the highest whole ledge the climb has reached,
      // with the floor pushed down beneath it so the climber has a moment to
      // stand before it is coming again.
      Ledge? landing;
      for (final ledge in kept) {
        if (!ledge.isBroken && ledge.y <= reached) landing = ledge;
      }
      final spot = landing ?? kept.first;
      return _copy(
        ledges: kept,
        climberX: spot.x,
        climberY: spot.y,
        velocity: 0,
        altitude: reached,
        nextLedgeId: nextId,
        registersPassed: registers,
        isGrounded: true,
        wasWalled: false,
        floorY: math.min(risenFloor, spot.y - lifeClearance),
        brokeLedge: broke,
        horizontalVelocity: 0,
        coyoteFor: 0,
        jumpQueuedFor: 0,
        jumpHeld: isLeaping,
        jumpConsumed: isLeaping,
        landingAge: 0,
        lastKickSide: 0,
        time: now,
        lives: livesNow - 1,
        eyeFor: eyeLeft,
        featherFor: featherLeft,
        airJumps: 0,
        relicsTaken: relics,
        livesLost: livesLost + 1,
        tookRelic: took,
        lostLife: true,
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
      time: now,
      lives: livesNow,
      eyeFor: eyeLeft,
      featherFor: featherLeft,
      airJumps: airUsed,
      relicsTaken: relics,
      tookRelic: took,
    );
  }

  /// The run's score, in whole metres.
  int get metres => altitude.floor();

  /// The level the climb has reached, 0 to 7.
  int get level => levelOf(altitude);

  /// How many steps of pace the climb has taken, one every fifty metres.
  int get difficulty => (altitude / difficultyStep).floor();

  /// How near the rising floor is, 0 when it is far off and 1 when it is level.
  ///
  /// Presentation reads this to make the shaft feel like it is closing in: the
  /// floor is below the frame for most of a run, so the thing that is about to
  /// end it would otherwise make no sound and cast no light until it arrives.
  double get danger {
    final gap = climberY - floorY;
    if (gap >= _dangerFrom) return 0;
    if (gap <= 0) return 1;
    return 1 - gap / _dangerFrom;
  }

  /// How far above the floor the climber starts to feel it, in metres.
  static const double _dangerFrom = 9;

  /// Whether this run beat the stored best.
  bool get isRecord => metres > best;

  /// The ledge with [id] at [y] in the shaft seeded [seed].
  ///
  /// Public because it is contract surface rather than an internal helper: the
  /// fixture generator samples it across every level so that the mode changes
  /// are *proven* to agree with `worker/src/game/ascent.js`, instead of being
  /// inferred from a recorded run that happened to climb high enough to meet
  /// them.
  static Ledge generate(int id, double y, int seed) =>
      _generate(id, y, AscentRng.ledge(seed, id), seed);

  /// Builds the ledge at [y], in the character its level calls for.
  ///
  /// Eight levels of a hundred metres, each its own shaft:
  ///
  /// 0. **The Temple.** Dressed stone, wide enough to land whatever the
  ///    steering does.
  /// 1. **The Sands.** Weathered ledges, and a wind across the shaft.
  /// 2. **The Frozen Nile.** Ledges carried by scarabs, and ice underfoot.
  /// 3. **The Duat.** All three kinds, in the dark.
  /// 4. **The Hall of Ma'at.** Mostly weathered: every step is weighed.
  /// 5. **Apep's Coils.** The scarabs move faster.
  /// 6. **The Lake of Fire.** Narrow, and the floor at its fastest.
  /// 7. **The Field of Reeds.** Wind and ice together, at the narrowest.
  ///
  /// Every level opens on a ledge the width of the shaft.
  ///
  /// The draws happen in a fixed order -- kind, width, position, drift -- and
  /// all four happen whatever the ledge turns out to be, because
  /// `worker/src/game/ascent.js` draws them in that same order from the same
  /// generator, and a stream read out of step is a different shaft.
  static Ledge _generate(int id, double y, AscentRng random, int seed) {
    final level = levelOf(y);
    final roll = random.nextDouble();
    final widthRoll = random.nextDouble();
    final xRoll = random.nextDouble();
    final driftRoll = random.nextDouble();
    if (level > 0 && levelOf(y - ledgeGap) < level) {
      return Ledge(
        id: id,
        kind: LedgeKind.stone,
        x: 0.5,
        y: y,
        width: 1,
        isLanding: true,
      );
    }
    final kind = switch (level) {
      <= 0 => LedgeKind.stone,
      1 => roll < 0.60 ? LedgeKind.stone : LedgeKind.cracked,
      2 => roll < 0.58 ? LedgeKind.stone : LedgeKind.scarab,
      3 =>
        roll < 0.54
            ? LedgeKind.stone
            : roll < 0.80
            ? LedgeKind.cracked
            : LedgeKind.scarab,
      4 =>
        roll < 0.40
            ? LedgeKind.stone
            : roll < 0.85
            ? LedgeKind.cracked
            : LedgeKind.scarab,
      5 =>
        roll < 0.42
            ? LedgeKind.stone
            : roll < 0.60
            ? LedgeKind.cracked
            : LedgeKind.scarab,
      _ =>
        roll < 0.50
            ? LedgeKind.stone
            : roll < 0.75
            ? LedgeKind.cracked
            : LedgeKind.scarab,
    };
    final (double narrowest, double spread) = switch (level) {
      <= 0 => (openingWidth, openingSpread),
      1 => (0.25, 0.14),
      2 => (0.22, 0.13),
      3 => (0.19, 0.12),
      4 => (0.18, 0.12),
      5 => (0.17, 0.11),
      _ => (0.16, 0.10),
    };
    final width = narrowest + widthRoll * spread;
    final x = width / 2 + xRoll * (1 - width);
    final pace = switch (level) {
      5 => 0.26,
      >= 6 => 0.2,
      _ => 0.16,
    };
    final drift = kind == LedgeKind.scarab
        ? (driftRoll < 0.5 ? pace : -pace)
        : 0.0;
    return Ledge(
      id: id,
      kind: kind,
      x: x,
      y: y,
      width: width,
      drift: drift,
      relic: relicAt(seed, y),
    );
  }

  /// The relic, if any, on a ledge at [y] in the shaft seeded [seed].
  ///
  /// Each kind has a target height in every band of the shaft; the ledge whose
  /// span of the climb, [y] up to the next ledge, holds that target carries
  /// it. An ankh wins a ledge two relics want, then the eye.
  static Relic? relicAt(int seed, double y) {
    if (y <= 0 || y >= summit) return null;
    bool hits(
      double band,
      double offset,
      double window,
      int stream,
      int firstBand,
    ) {
      final index = (y / band).floor();
      if (index < firstBand) return false;
      final roll = AscentRng.ledge(seed, stream + index).nextDouble();
      final target = index * band + offset + roll * window;
      return target >= y && target < y + ledgeGap;
    }

    if (hits(ankhBand, ankhOffset, ankhWindow, ankhStream, 0)) {
      return Relic.ankh;
    }
    if (hits(eyeBand, eyeOffset, eyeWindow, eyeStream, eyeFirstBand)) {
      return Relic.eye;
    }
    if (hits(featherBand, featherOffset, featherWindow, featherStream, 0)) {
      return Relic.feather;
    }
    return null;
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
    double? time,
    int? lives,
    double? eyeFor,
    double? featherFor,
    int? airJumps,
    int? relicsTaken,
    int? livesLost,
    Relic? tookRelic,
    bool lostLife = false,
    bool won = false,
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
    time: time ?? this.time,
    lives: lives ?? this.lives,
    eyeFor: eyeFor ?? this.eyeFor,
    featherFor: featherFor ?? this.featherFor,
    airJumps: airJumps ?? this.airJumps,
    relicsTaken: relicsTaken ?? this.relicsTaken,
    livesLost: livesLost ?? this.livesLost,
    tookRelic: tookRelic,
    lostLife: lostLife,
    won: won,
  );
}

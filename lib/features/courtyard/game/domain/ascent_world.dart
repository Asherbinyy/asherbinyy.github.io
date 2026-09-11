import 'dart:math' as math;

import 'package:flutter/foundation.dart';

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
    this.brokeLedge = false,
    this.isGrounded = false,
    this.wasWalled = false,
    this.floorY = -_fallMargin,
    this.kickedWall = false,
  });

  /// A fresh run.
  factory AscentWorld.seeded({
    required int best,
    required bool isPractice,
    int seed = 0,
  }) {
    final random = math.Random(seed);
    final ledges = <Ledge>[
      // A floor wide enough that the first bounce cannot be missed.
      const Ledge(id: 0, kind: LedgeKind.stone, x: 0.5, y: 0, width: 0.9),
    ];
    for (var i = 1; i < _ledgeCount; i++) {
      ledges.add(_generate(i, i * ledgeGap, random));
    }
    return AscentWorld(
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

  /// Metres between ledges.
  static const double ledgeGap = 2.6;

  /// How much taller a wall kick is than a standing jump.
  static const double _wallBoost = 1.34;

  /// Metres climbed before the pace steps up.
  static const double levelHeight = 60;

  /// How fast the floor rises at [level], in metres per second.
  ///
  /// Zero on the first level: the opening stretch is where the controls are
  /// learned, and a floor chasing a player who has not worked out the jump yet
  /// is just a short run. After that it climbs, and the steps are linear
  /// rather than exponential so the last level is hard rather than impossible.
  static double _floorSpeed(int level) => level == 0 ? 0 : 0.5 + level * 0.55;

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
    final rise = _floorSpeed(level) * dt;

    // Sideways first. Reaching a wall is worth something now: it kicks the
    // climber back with more height than a standing jump, which is the trick
    // the tower games are built on and the reason to steer wide rather than
    // straight up.
    var x = climberX + steer * _steerRate * dt;
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
    var y = climberY + speed * dt;
    var grounded = false;
    var kicked = false;

    // A wall kick only counts on the way up, and only once per contact: a
    // climber grinding along an edge would otherwise ride it to the top.
    if (walled && speed > 0 && !wasWalled) {
      speed = _bounce * _wallBoost;
      kicked = true;
    }

    final live = [for (final ledge in ledges) ledge.advance(dt)];
    var broke = false;

    // Space, from a standing start or in the air on the first press.
    // Space, from a standing start only. A kick has already set its own,
    // taller speed, and letting the jump overwrite it meant holding space
    // through a kick threw the bonus away.
    if (isLeaping && isGrounded) speed = _bounce;

    // Only ever falling, and only from above: a climber rising through a ledge
    // passes it, which is what makes the ascent readable rather than a trap.
    if (speed < 0) {
      for (var i = 0; i < live.length; i++) {
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
        if (ledge.kind == LedgeKind.cracked) {
          live[i] = ledge.broken;
          broke = true;
        }
        break;
      }
    }

    final reached = math.max(altitude, y);
    final registers = (reached / registerGap).floor();
    final risenFloor = math.max(floorY + rise, reached - _fallMargin);

    // Recycle ledges that have dropped well below, so the list stays a fixed
    // size however far the climb goes.
    final floor = risenFloor - _fallMargin * 2;
    final random = math.Random(nextLedgeId);
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
      kept.add(_generate(nextId, highest, random));
      nextId++;
    }
    kept.sort((a, b) => a.y.compareTo(b.y));

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
    );
  }

  /// The run's score, in whole metres.
  int get metres => altitude.floor();

  /// How far into the climb the pace has stepped up.
  int get level => (altitude / levelHeight).floor();

  /// Whether this run beat the stored best.
  bool get isRecord => metres > best;

  static Ledge _generate(int id, double y, math.Random random) {
    final roll = random.nextDouble();
    // Cracked and scarab ledges arrive gradually: the first stretch of the
    // shaft is dressed stone, so the controls are learned before the hazards.
    final kind = y < 40 || roll < 0.62
        ? LedgeKind.stone
        : roll < 0.82
        ? LedgeKind.cracked
        : LedgeKind.scarab;
    final width = 0.16 + random.nextDouble() * 0.12;
    return Ledge(
      id: id,
      kind: kind,
      x: width / 2 + random.nextDouble() * (1 - width),
      y: y,
      width: width,
      drift: kind == LedgeKind.scarab ? (random.nextBool() ? 0.16 : -0.16) : 0,
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
  }) => AscentWorld(
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
  );
}

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nocturne/app/l10n/locale_controller.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/painting/ascent_painter.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';
import 'package:nocturne/features/ascent/domain/ascent_facts.dart';
import 'package:nocturne/features/ascent/domain/ascent_world.dart';

/// `/ascent` — the climb up the obelisk.
///
/// Full specification in `13-GAME-DESIGN.md`. The short version: climbing is
/// how the CV is read, every band uncovers something true, and every fact stays
/// reachable without playing.
class AscentScreen extends ConsumerStatefulWidget {
  /// Creates the climb.
  const AscentScreen({super.key});

  @override
  ConsumerState<AscentScreen> createState() => _AscentScreenState();
}

class _AscentScreenState extends ConsumerState<AscentScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker = createTicker(_onTick);
  final FocusNode _focus = FocusNode(debugLabel: 'ascent');

  AscentWorld? _world;
  Duration _last = Duration.zero;
  double _steer = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause on blur, always. A ticker left running on a hidden tab is a
    // battery bug, and this is the only route allowed a continuous one.
    if (state != AppLifecycleState.resumed && _ticker.isActive) {
      _ticker.stop();
      setState(() {});
    }
  }

  void _onTick(Duration elapsed) {
    final world = _world;
    if (world == null) return;
    final dt = (elapsed - _last).inMicroseconds / 1000000;
    _last = elapsed;
    // A long frame, a resumed tab or a slow machine must not teleport the
    // climber through a ledge. Clamping is what keeps collision honest.
    final step = dt.clamp(0.0, 1 / 30);

    final next = world.step(dt: step, steer: _steer);
    if (next.isOver) _ticker.stop();
    setState(() => _world = next);
  }

  void _start({required bool isPractice}) {
    _last = Duration.zero;
    setState(() {
      _world = AscentWorld.seeded(
        best: _world?.best ?? 0,
        isPractice: isPractice,
        seed: DateTime.now().millisecondsSinceEpoch,
      );
    });
    _focus.requestFocus();
    _ticker
      ..stop()
      ..start();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final left = {LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA};
    final right = {LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD};

    if (event is KeyUpEvent) {
      if (left.contains(event.logicalKey) || right.contains(event.logicalKey)) {
        _steer = 0;
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (left.contains(event.logicalKey)) {
      _steer = -1;
      return KeyEventResult.handled;
    }
    if (right.contains(event.logicalKey)) {
      _steer = 1;
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _aimAt(double x, double width) {
    final world = _world;
    if (world == null || width <= 0) return;
    // Steer toward where the finger or pointer is, rather than teleporting
    // there: the same one axis of input the keyboard has.
    final target = (x / width).clamp(0.0, 1.0);
    _steer = (target - world.climberX).abs() < 0.02
        ? 0
        : (target > world.climberX ? 1 : -1);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final world = _world;
    final locale = ref.watch(localeControllerProvider);

    final roles = switch (ref.watch(careerProvider).valueOrNull) {
      ContentReady<Career>(:final data) => data.roles,
      _ => const <CareerRole>[],
    };
    final apps = switch (ref.watch(appsProvider).valueOrNull) {
      ContentReady<Apps>(:final data) => data.apps,
      _ => const <ShippedApp>[],
    };
    final facts = AscentFacts.from(roles: roles, apps: apps, locale: locale);

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: context.platform.gutter,
        end: context.platform.gutter,
        top: tokens.space48,
        bottom: tokens.space64,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.ascentHeading, style: context.type.displayM),
          SizedBox(height: tokens.space8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.type.measureFor(context.type.bodyL),
            ),
            child: Text(
              l10n.ascentIntro,
              style: context.type.bodyL.copyWith(color: tokens.textSecondary),
            ),
          ),
          SizedBox(height: tokens.space24),
          _Shaft(
            world: world,
            focus: _focus,
            onKey: _onKey,
            onAim: _aimAt,
            onRelease: () => _steer = 0,
          ),
          SizedBox(height: tokens.space16),
          _Controls(
            world: world,
            onStart: () => _start(isPractice: false),
            onPractice: () => _start(isPractice: true),
          ),
          SizedBox(height: tokens.space32),
          _Uncovered(facts: facts, world: world),
        ],
      ),
    );
  }
}

/// The playfield.
class _Shaft extends StatelessWidget {
  const _Shaft({
    required this.world,
    required this.focus,
    required this.onKey,
    required this.onAim,
    required this.onRelease,
  });

  final AscentWorld? world;
  final FocusNode focus;
  final KeyEventResult Function(FocusNode, KeyEvent) onKey;
  final void Function(double, double) onAim;
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final live = world;

    return InstrumentPanel(
      fill: tokens.surface,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Focus(
          focusNode: focus,
          onKeyEvent: onKey,
          child: Semantics(
            // An unlabelled canvas tells a screen-reader user nothing. This
            // says what it is and points at the list below, which carries the
            // same content in text.
            label: context.l10n.ascentCanvasLabel,
            child: LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) =>
                    onAim(details.localPosition.dx, constraints.maxWidth),
                onHorizontalDragUpdate: (details) =>
                    onAim(details.localPosition.dx, constraints.maxWidth),
                onHorizontalDragEnd: (_) => onRelease(),
                onTapUp: (_) => onRelease(),
                child: live == null
                    ? Center(
                        child: Text(
                          context.l10n.ascentReady,
                          style: context.type.body.copyWith(
                            color: tokens.textMuted,
                          ),
                        ),
                      )
                    : CustomPaint(
                        painter: AscentPainter(
                          world: live,
                          stone: tokens.instrument,
                          cracked: tokens.instrumentDim,
                          gold: tokens.beacon,
                          wall: tokens.hairline,
                          strokeWidth: tokens.hairlineWidth,
                          isReducedMotion: ReducedMotion.of(context),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Start, practice, and the readout.
class _Controls extends StatelessWidget {
  const _Controls({
    required this.world,
    required this.onStart,
    required this.onPractice,
  });

  final AscentWorld? world;
  final VoidCallback onStart;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final live = world;

    return Wrap(
      spacing: tokens.space16,
      runSpacing: tokens.space12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        BeaconButton(
          label: live == null || live.isOver
              ? l10n.ascentBegin
              : l10n.ascentAgain,
          emphasis: ButtonEmphasis.primary,
          onPressed: onStart,
        ),
        // Offered with equal weight, not buried as an easier option: the whole
        // shaft has to be reachable at the player's own pace.
        BeaconButton(label: l10n.ascentPractice, onPressed: onPractice),
        if (live != null)
          Text(
            l10n.ascentAltitude(live.metres),
            style: context.type.telemetry.copyWith(color: tokens.instrument),
          ),
      ],
    );
  }
}

/// What the climb has uncovered, and what it has not.
class _Uncovered extends StatelessWidget {
  const _Uncovered({required this.facts, required this.world});

  final List<AscentFact> facts;
  final AscentWorld? world;

  @override
  Widget build(BuildContext context) {
    if (facts.isEmpty) return const SizedBox.shrink();
    final tokens = context.tokens;
    final reached = world?.registersPassed ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.ascentUncovered, style: context.type.heading),
        SizedBox(height: tokens.space12),
        for (var i = 0; i < facts.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.space12),
            child: _Row(fact: facts[i], isUncovered: i < reached),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.fact, required this.isUncovered});

  final AscentFact fact;
  final bool isUncovered;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;

    return Semantics(
      link: true,
      child: InkWell(
        onTap: () => context.go(fact.route),
        hoverColor: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.space4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: tokens.space24,
                child: Text(
                  isUncovered ? '◆' : '◇',
                  style: type.telemetryS.copyWith(
                    color: isUncovered ? tokens.beacon : tokens.instrumentDim,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fact.title,
                      style: type.body.copyWith(
                        color: isUncovered
                            ? tokens.textPrimary
                            : tokens.textSecondary,
                      ),
                    ),
                    // Never hidden, only marked. The content is reachable
                    // whether or not anyone plays.
                    Text(
                      fact.detail,
                      style: type.telemetryS.copyWith(color: tokens.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

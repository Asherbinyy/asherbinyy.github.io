import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/painting/life_flow_painter.dart';
import 'package:nocturne/core/painting/mark_painter.dart';

/// The owner's life as an automation that runs on a loop.
///
/// He asked for the space beside his portrait to hold something like an n8n
/// workflow that represents him -- coding, studying, automating, building
/// apps, the gym -- animated, running continuously. So it is one: a trigger
/// and five steps, wired in order, with a run travelling through them. Each
/// node lights as it executes and keeps a tick once it has, the result moves
/// down the wire to the next, and the last hands back to the first.
///
/// The trigger is Life, drawn with the site's own ankh, which is the sign for
/// it. The steps are his words and nothing more: no hours, no frequencies, no
/// claims the owner has not made.
///
/// Gold is the run, because gold is what is live; the nodes at rest are
/// limestone; a node under the pointer takes a faience ring, because that is
/// what faience is for. Under reduced motion it is the finished run, still.
class LifeFlow extends StatefulWidget {
  /// Draws the loop.
  const LifeFlow({super.key});

  @override
  State<LifeFlow> createState() => _LifeFlowState();
}

/// One node: what it is called and what it looks like.
typedef _Step = ({String label, IconData? icon});

class _LifeFlowState extends State<LifeFlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: Tokens.lifeFlowStep * _count,
  );
  final GlobalKey _key = GlobalKey(debugLabel: 'life-flow');
  final ValueNotifier<int?> _hovered = ValueNotifier(null);
  ScrollController? _scroll;
  bool _isReduced = false;
  bool _isOnScreen = true;

  static const int _count = 6;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scroll = ChromeScrollScope.maybeOf(context)?.controller;
    if (scroll != _scroll) {
      _scroll?.removeListener(_checkOnScreen);
      _scroll = scroll?..addListener(_checkOnScreen);
    }
    _isReduced = ReducedMotion.of(context);
    _updateRun();
  }

  @override
  void dispose() {
    _scroll?.removeListener(_checkOnScreen);
    _run.dispose();
    _hovered.dispose();
    super.dispose();
  }

  /// Runs only while it can be seen, and never under reduced motion.
  void _updateRun() {
    if (_isReduced) {
      _run
        ..stop()
        ..value = 1;
      return;
    }
    if (_isOnScreen && !_run.isAnimating) {
      _run.repeat();
    } else if (!_isOnScreen && _run.isAnimating) {
      _run.stop();
    }
  }

  void _checkOnScreen() {
    if (!mounted) return;
    final box = _key.currentContext?.findRenderObject();
    final viewport =
        Scrollable.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (box is! RenderBox || !box.hasSize || viewport == null) return;
    final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    final onScreen = top + box.size.height > 0 && top < viewport.size.height;
    if (onScreen == _isOnScreen) return;
    _isOnScreen = onScreen;
    _updateRun();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final steps = <_Step>[
      (label: l10n.aboutFlowLife, icon: null),
      (label: l10n.aboutFlowStudy, icon: Icons.menu_book_rounded),
      (label: l10n.aboutFlowCode, icon: Icons.code_rounded),
      (label: l10n.aboutFlowApps, icon: Icons.smartphone_rounded),
      (label: l10n.aboutFlowAutomate, icon: Icons.account_tree_rounded),
      (label: l10n.aboutFlowGym, icon: Icons.fitness_center_rounded),
    ];
    assert(steps.length == _count, 'the loop and its timing disagree');

    return Semantics(
      label: l10n.aboutFlowLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          key: _key,
          height: Tokens.lifeFlowHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              const node = Tokens.lifeFlowNodeSize;
              return AnimatedBuilder(
                animation: Listenable.merge([_run, _hovered]),
                builder: (context, _) {
                  // At rest under reduced motion the run has finished: every
                  // wire travelled, every node ticked, nothing in transit.
                  final progress = _isReduced
                      ? _count.toDouble()
                      : _run.value * _count;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: LifeFlowPainter(
                            count: _count,
                            progress: progress,
                            nodeSize: node,
                            wire: tokens.hairlineStrong,
                            done: tokens.beaconDim,
                            packet: tokens.beacon,
                            glow: tokens.beaconGlow,
                            strokeWidth: tokens.hairlineWidth,
                          ),
                        ),
                      ),
                      for (final (index, step) in steps.indexed)
                        _positioned(
                          index,
                          size,
                          _FlowNode(
                            step: step,
                            isTrigger: index == 0,
                            isRunning:
                                !_isReduced &&
                                progress >= index &&
                                progress < index + LifeFlowPainter.executing,
                            isDone:
                                _isReduced ||
                                progress >= index + LifeFlowPainter.executing,
                            isHovered: _hovered.value == index,
                            onHover: (inside) =>
                                _hovered.value = inside ? index : null,
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  /// Places a node and its label around the node's centre.
  Widget _positioned(int index, Size size, Widget child) {
    final centre = LifeFlowPainter.centreOf(index, _count, size);
    const node = Tokens.lifeFlowNodeSize;
    const label = Tokens.lifeFlowLabelWidth;
    return Positioned(
      left: centre.dx - label / 2,
      top: centre.dy - node / 2,
      width: label,
      child: child,
    );
  }
}

/// A step in the loop: a square with its mark, and its name under it.
class _FlowNode extends StatelessWidget {
  const _FlowNode({
    required this.step,
    required this.isTrigger,
    required this.isRunning,
    required this.isDone,
    required this.isHovered,
    required this.onHover,
  });

  final _Step step;
  final bool isTrigger;
  final bool isRunning;
  final bool isDone;
  final bool isHovered;
  final ValueChanged<bool> onHover;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final edge = isHovered
        ? tokens.faience
        : isRunning
        ? tokens.beacon
        : tokens.hairlineStrong;
    final mark = isRunning ? tokens.beaconGlow : tokens.textSecondary;
    const size = Tokens.lifeFlowNodeSize;

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: ReducedMotion.duration(context, Tokens.quick),
                    decoration: BoxDecoration(
                      color: tokens.surfaceRaised,
                      // A trigger is rounded on its leading side, the way an
                      // automation editor tells a start from a step.
                      borderRadius: isTrigger
                          ? const BorderRadiusDirectional.horizontal(
                              start: Radius.circular(size / 2),
                              end: Radius.circular(Tokens.cardRadius),
                            )
                          : BorderRadius.circular(Tokens.cardRadius),
                      border: Border.all(
                        color: edge,
                        width: tokens.hairlineWidth * (isRunning ? 2 : 1),
                      ),
                      boxShadow: isRunning
                          ? [
                              BoxShadow(
                                color: tokens.beaconGlow.withValues(
                                  alpha: Tokens.lifeFlowGlowAlpha,
                                ),
                                blurRadius: Tokens.lifeFlowGlowBlur,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: step.icon == null
                          ? SizedBox.square(
                              dimension: size * 0.46,
                              child: CustomPaint(
                                painter: MarkPainter(
                                  colour: isRunning
                                      ? tokens.beaconGlow
                                      : tokens.beacon,
                                  strokeWidth: tokens.hairlineWidth * 2,
                                ),
                              ),
                            )
                          : Icon(step.icon, size: size * 0.42, color: mark),
                    ),
                  ),
                ),
                // A tick once the step has run, the way a workflow editor marks
                // a finished node. Limestone: success has no colour here.
                if (isDone)
                  PositionedDirectional(
                    top: -Tokens.lifeFlowTickInset,
                    end: -Tokens.lifeFlowTickInset,
                    child: Container(
                      width: Tokens.lifeFlowTickSize,
                      height: Tokens.lifeFlowTickSize,
                      decoration: BoxDecoration(
                        color: tokens.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: tokens.hairlineStrong,
                          width: tokens.hairlineWidth,
                        ),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: Tokens.lifeFlowTickSize * 0.7,
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: tokens.space8),
          Text(
            step.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: type.meta.copyWith(
              color: isRunning || isHovered
                  ? tokens.textPrimary
                  : tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

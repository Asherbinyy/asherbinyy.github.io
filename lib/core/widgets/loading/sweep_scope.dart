import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';

/// Hosts the one sweep controller every skeleton on a page shares.
///
/// Section 11 is explicit: twelve cards with twelve controllers is twelve times
/// the frame cost for an identical effect. Wrap the nearest common ancestor of
/// everything that can be loading, and every `SweepShimmer` below finds it.
class SweepScope extends StatefulWidget {
  /// Wraps [child] and its descendants.
  const SweepScope({required this.child, super.key});

  /// Subtree that may contain sweeping surfaces.
  final Widget child;

  /// The shared band position, 0..1 across the container.
  ///
  /// Null when there is no scope above — so a primitive used standalone renders
  /// static rather than throwing — and null under reduced motion, which section
  /// 11 requires to settle the sweep entirely.
  static Animation<double>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SweepAnimationScope>()?.sweep;

  @override
  State<SweepScope> createState() => _SweepScopeState();
}

class _SweepScopeState extends State<SweepScope>
    with SingleTickerProviderStateMixin {
  /// One pass plus the pause that follows it. Derived rather than tokenised so
  /// the two published durations stay the single source.
  static final Duration _cycle = Tokens.sweep + Tokens.sweepPause;
  static final double _sweepFraction =
      Tokens.sweep.inMicroseconds / _cycle.inMicroseconds;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _cycle,
  );

  /// The band travels over the first pass and then holds off-end for the pause.
  late final CurvedAnimation _sweep = CurvedAnimation(
    parent: _controller,
    // Interval is linear by default, which is what section 11 specifies.
    curve: Interval(0, _sweepFraction),
  );

  /// Caches the last resolved preference so a rebuild does not restart a
  /// controller that is already running at the right setting.
  bool? _isSettled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settled = ReducedMotion.of(context);
    if (settled == _isSettled) return;
    _isSettled = settled;
    if (settled) {
      _controller
        ..stop()
        ..value = 0;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SweepAnimationScope(
    // Reading the preference here registers the dependency, so a change
    // rebuilds this scope without any local state flag.
    sweep: ReducedMotion.of(context) ? null : _sweep,
    child: widget.child,
  );
}

class _SweepAnimationScope extends InheritedWidget {
  const _SweepAnimationScope({required this.sweep, required super.child});

  final Animation<double>? sweep;

  @override
  bool updateShouldNotify(_SweepAnimationScope oldWidget) =>
      oldWidget.sweep != sweep;
}

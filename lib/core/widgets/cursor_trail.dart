import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/painting/cursor_trail_painter.dart';
import 'package:nocturne/core/platform/platform_scope.dart';

/// A wake that follows the pointer.
///
/// `12-MOTIF-LIBRARY.md` §5, and every constraint there is load-bearing:
///
/// - **The system cursor is untouched.** This draws beside it, never instead
///   of it, so pointer size, high-contrast cursors and every other pointer
///   accessibility setting keep working.
/// - **Pointer input only**, asked of the platform service rather than
///   inferred from viewport width — `AGENTS.md` §6.
/// - **Off under reduced motion**, and off in Recruiter Mode, which is a quiet
///   document.
/// - A hard cap on live motes, one `RepaintBoundary`, and the ticker stops
///   when the pointer leaves or the widget is not needed. It is the least
///   important thing on the page and it gets the smallest budget.
///
/// The widget keeps one tree shape whether or not it is running, and only the
/// overlay comes and goes. Swapping between `child` and a `Stack` wrapping it
/// re-parents the whole page, and Flutter builds the replacement before
/// disposing the original — which briefly attaches the page's single
/// `ScrollController` to two scroll views and trips an assertion.
class CursorTrail extends StatefulWidget {
  /// Wraps [child] with the overlay above it.
  const CursorTrail({required this.child, required this.isEnabled, super.key});

  /// The page beneath.
  final Widget child;

  /// False in Recruiter Mode, where nothing decorative runs.
  final bool isEnabled;

  @override
  State<CursorTrail> createState() => _CursorTrailState();
}

class _CursorTrailState extends State<CursorTrail>
    with SingleTickerProviderStateMixin {
  final List<TrailMote> _motes = [];
  late final Ticker _ticker = createTicker(_onTick);
  int _now = 0;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    _now = elapsed.inMilliseconds;
    _motes.removeWhere((mote) => _now - mote.born >= Tokens.cursorTrailLifeMs);
    // Nothing left to draw and nothing arriving: stop rather than tick against
    // an empty list for the rest of the session.
    if (_motes.isEmpty) {
      _ticker.stop();
    }
    setState(() {});
  }

  void _drop(Offset position) {
    if (!_ticker.isActive) _ticker.start();
    _motes.add(TrailMote(position: position, born: _now));
    // The cap is the budget. Dropping the oldest keeps the wake a wake rather
    // than letting a fast drag across the page accumulate hundreds of motes.
    while (_motes.length > Tokens.cursorTrailMaxMotes) {
      _motes.removeAt(0);
    }
  }

  void _clear() {
    _motes.clear();
    _ticker.stop();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isRunning =
        widget.isEnabled &&
        context.platform.isPointer &&
        !ReducedMotion.of(context);

    if (!isRunning && (_motes.isNotEmpty || _ticker.isActive)) {
      _motes.clear();
      _ticker.stop();
    }

    // One tree shape, always. Returning `child` bare when idle and a Stack
    // when active re-parents everything below, and Flutter builds the new
    // subtree before disposing the old -- which attaches the page's single
    // ScrollController to two scroll views at once and trips an assertion.
    // The overlay is what appears and disappears; the scaffolding does not.
    return MouseRegion(
      // `opaque: false` so the region observes the pointer without taking it
      // from anything underneath. The trail must never eat a click.
      opaque: false,
      onHover: isRunning ? (event) => _drop(event.localPosition) : null,
      onExit: isRunning ? (_) => _clear() : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (isRunning && _motes.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: CursorTrailPainter(
                      motes: List.unmodifiable(_motes),
                      now: _now,
                      colour: tokens.beacon,
                      lifetimeMs: Tokens.cursorTrailLifeMs,
                      radius: tokens.cursorTrailRadius,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

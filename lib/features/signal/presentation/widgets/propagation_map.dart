import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/painting/map_painter.dart';
import 'package:nocturne/core/painting/papyrus_painter.dart';
import 'package:nocturne/core/painting/coastline_data.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';

/// The propagation map surface: graticule, arcs and station nodes.
///
/// Arcs draw in on first view, which section 5 permits because entering the
/// viewport is a response to the viewer rather than ambient motion. Under
/// reduced motion they are simply already drawn.
class PropagationMap extends StatefulWidget {
  /// [onSelected] receives the index of the station the viewer chose.
  const PropagationMap({
    required this.stations,
    required this.selectedIndex,
    required this.labels,
    required this.coastlines,
    required this.onSelected,
    super.key,
  });

  /// Stations in chronological order.
  final List<MapStation> stations;

  /// Currently selected station, or -1.
  final int selectedIndex;

  /// Accessible name per station, keyed by id.
  final Map<String, String> labels;

  /// Bundled public-domain land outlines.
  final List<CoastlineRing> coastlines;

  /// Called when a station is chosen by pointer, touch or keyboard.
  final ValueChanged<int> onSelected;

  @override
  State<PropagationMap> createState() => _PropagationMapState();
}

class _PropagationMapState extends State<PropagationMap>
    with TickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: Tokens.arcDraw,
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: Tokens.considered,
  );
  final FocusNode _focus = FocusNode(debugLabel: 'propagation map');
  final TransformationController _transform = TransformationController();
  bool? _isSettled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settled = ReducedMotion.of(context);
    if (settled == _isSettled) return;
    _isSettled = settled;
    if (settled) {
      // Section 5: map arcs draw instantly under reduced motion.
      _draw.value = 1;
      _pulse.value = 0;
    } else {
      _draw.forward();
    }
  }

  @override
  void didUpdateWidget(PropagationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex == widget.selectedIndex) return;
    if (_isSettled ?? false) return;
    // One expanding ring per selection, not a loop.
    _pulse.forward(from: 0);
  }

  @override
  void dispose() {
    _draw.dispose();
    _pulse.dispose();
    _focus.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _move(int delta) {
    if (widget.stations.isEmpty) return;
    final next =
        (widget.selectedIndex < 0 ? 0 : widget.selectedIndex + delta) %
        widget.stations.length;
    widget.onSelected(next < 0 ? widget.stations.length - 1 : next);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    // Arrow keys move station selection, per the platform matrix in section 7.
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.arrowDown:
        _move(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.arrowUp:
        _move(-1);
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      label: context.l10n.signalMapLabel,
      child: FocusRing(
        isFocused: _focus.hasFocus,
        radius: tokens.panelRadius,
        child: Focus(
          focusNode: _focus,
          onKeyEvent: _onKey,
          child: AspectRatio(
            aspectRatio: tokens.mapAspectRatio,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return MouseRegion(
                  cursor: context.platform.isPointer
                      // Section 7: crosshair over the map surface.
                      ? SystemMouseCursors.precise
                      : MouseCursor.defer,
                  child: InteractiveViewer(
                    transformationController: _transform,
                    trackpadScrollCausesScale: true,
                    child: SizedBox.fromSize(
                      size: size,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (details) {
                          _focus.requestFocus();
                          final index = MapPainter.nearestTo(
                            details.localPosition,
                            widget.stations,
                            size,
                            within: context.platform.minimumTarget,
                          );
                          if (index != null) widget.onSelected(index);
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // The sheet, in its own boundary so the weave and
                            // the torn edge are rasterised once and are not
                            // redrawn by the arc animation running over them.
                            RepaintBoundary(
                              child: CustomPaint(
                                size: size,
                                painter: PapyrusPainter(
                                  sheet: tokens.surfaceRaised,
                                  fibre: tokens.hairline,
                                  edge: tokens.hairlineStrong,
                                  hairlineWidth: tokens.hairlineWidth,
                                ),
                              ),
                            ),
                            RepaintBoundary(
                              child: AnimatedBuilder(
                                animation: Listenable.merge([_draw, _pulse]),
                                builder: (context, _) => CustomPaint(
                                  size: size,
                                  painter: MapPainter(
                                    stations: widget.stations,
                                    selectedIndex: widget.selectedIndex,
                                    drawProgress: MotionCurves.emphasized
                                        .transform(_draw.value),
                                    pulse: _pulse.value,
                                    coastlines: widget.coastlines,
                                    // Ink on a sheet, so the coast and the
                                    // graticule step up a rung: against the
                                    // page they were legible, against a raised
                                    // surface they were not.
                                    landColour: tokens.instrument,
                                    graticuleColour: tokens.hairlineStrong,
                                    arcColour: tokens.instrumentMid,
                                    activeColour: tokens.beacon,
                                    nodeColour: tokens.instrumentMid,
                                    hairlineWidth: tokens.hairlineWidth,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

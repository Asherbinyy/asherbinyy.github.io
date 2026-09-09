import 'package:material_ui/material_ui.dart';

import 'package:go_router/go_router.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/mark_painter.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';

/// The mark in the header, always linking to the station.
///
/// Design-system section 12: header, top-left, 24px, links to `/`, and it is a
/// wayfinding element rather than a decorative one. It is drawn from the trace
/// curve rather than from an asset, so it cannot drift from the trace and needs
/// no file to exist before task 1.6b exports one.
class AppMark extends StatefulWidget {
  /// [semanticLabel] names the destination, not the shape.
  const AppMark({required this.semanticLabel, super.key});

  /// What a screen reader announces for the link.
  final String semanticLabel;

  @override
  State<AppMark> createState() => _AppMarkState();
}

class _AppMarkState extends State<AppMark> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      link: true,
      label: widget.semanticLabel,
      child: ListenableBuilder(
        listenable: _states,
        builder: (context, _) => FocusRing(
          isFocused: _states.value.contains(WidgetState.focused),
          child: InkWell(
            onTap: () => context.goNamed(AppRoute.home.name),
            statesController: _states,
            borderRadius: BorderRadius.circular(tokens.controlRadius),
            child: Padding(
              padding: EdgeInsets.all(tokens.space8),
              child: CustomPaint(
                size: Size.square(tokens.markHeaderSize),
                painter: MarkPainter(
                  colour: tokens.beacon,
                  strokeWidth: MarkPainter.strokeFor(tokens.markHeaderSize),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

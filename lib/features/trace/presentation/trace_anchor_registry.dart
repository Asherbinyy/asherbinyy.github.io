import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/features/trace/domain/trace_geometry.dart';

/// Shares the rendered career-entry positions with the fixed trace layer.
///
/// The trace and the scrolling station content are siblings in the chrome
/// stack. Stable global keys let the trace measure each entry without pushing
/// layout state through the page or rebuilding it while scrolling.
class TraceAnchorRegistry {
  final Map<String, GlobalKey> _keys = {};

  /// Returns the stable key for one career role.
  GlobalKey keyFor(String id) =>
      _keys.putIfAbsent(id, () => GlobalKey(debugLabel: 'trace-anchor-$id'));

  /// Replaces each burst's provisional anchor with its rendered section centre.
  ///
  /// Returns `null` until every entry and the trace have completed layout. The
  /// caller can render its provisional geometry for that first frame and retry
  /// after layout.
  List<TraceBurst>? resolve({
    required List<TraceBurst> bursts,
    required BuildContext traceContext,
    required double scrollOffset,
    required double traceHeight,
  }) {
    final traceObject = traceContext.findRenderObject();
    if (traceObject is! RenderBox || !traceObject.hasSize || traceHeight <= 0) {
      return null;
    }

    final traceTop = traceObject.localToGlobal(Offset.zero).dy;
    final resolved = <TraceBurst>[];
    for (final burst in bursts) {
      final anchorObject = _keys[burst.id]?.currentContext?.findRenderObject();
      if (anchorObject is! RenderBox || !anchorObject.hasSize) return null;
      final centre = anchorObject.localToGlobal(
        Offset(0, anchorObject.size.height / 2),
      );
      resolved.add((
        id: burst.id,
        anchor: ((centre.dy - traceTop + scrollOffset) / traceHeight).clamp(
          0.0,
          1.0,
        ),
        amplitude: burst.amplitude,
        density: burst.density,
      ));
    }
    return resolved;
  }
}

/// One registry per application scope keeps the two station layers in sync.
// This presentation registry owns Flutter keys. The build.yaml workaround for
// https://github.com/dart-lang/sdk/issues/61870 limits generation to pure-Dart
// providers because Riverpod 2 cannot summarize this SDK's widget syntax.
final traceAnchorRegistryProvider = Provider<TraceAnchorRegistry>(
  (ref) => TraceAnchorRegistry(),
);

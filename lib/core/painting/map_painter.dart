import 'package:flutter/rendering.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/coastline_data.dart';
import 'package:nocturne/core/painting/great_circle.dart';
import 'package:nocturne/core/painting/projection.dart';

/// One station on the propagation map.
typedef MapStation = ({
  String id,
  double latitude,
  double longitude,
  bool isMinor,
});

/// Draws the propagation map: graticule, arcs and station nodes.
///
/// No map SDK, no API key, no third-party data flow — the public-domain land
/// geometry is bundled with the application.
class MapPainter extends CustomPainter {
  /// [drawProgress] runs 0..1 as the arcs draw in on first view.
  const MapPainter({
    required this.stations,
    required this.selectedIndex,
    required this.drawProgress,
    required this.pulse,
    required this.coastlines,
    required this.landColour,
    required this.graticuleColour,
    required this.arcColour,
    required this.activeColour,
    required this.nodeColour,
    required this.hairlineWidth,
  });

  /// Stations in chronological order; arcs run between consecutive pairs.
  final List<MapStation> stations;

  /// Index of the selected station, or -1 for none.
  final int selectedIndex;

  /// How much of the arc sequence has drawn, 0..1.
  final double drawProgress;

  /// The selected node's expanding ring, 0..1.
  final double pulse;

  /// Bundled Natural Earth rings in geographic coordinates.
  final List<CoastlineRing> coastlines;

  /// Hairline land-outline colour.
  final Color landColour;

  /// Graticule colour.
  final Color graticuleColour;

  /// Resting arc colour.
  final Color arcColour;

  /// The active leg and selected node.
  final Color activeColour;

  /// Resting node colour.
  final Color nodeColour;

  /// Hairline stroke width.
  final double hairlineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    _paintLand(canvas, size);
    _paintGraticule(canvas, size);
    _paintArcs(canvas, size);
    _paintNodes(canvas, size);
  }

  void _paintLand(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = landColour
      ..style = PaintingStyle.stroke
      ..strokeWidth = hairlineWidth;
    final path = Path();
    for (final ring in coastlines) {
      for (var index = 0; index < ring.length; index++) {
        final point = Projection.toCanvas(
          latitude: ring[index].latitude,
          longitude: ring[index].longitude,
          size: size,
        );
        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
    }
    canvas.drawPath(path, paint);
  }

  void _paintGraticule(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = graticuleColour
      ..style = PaintingStyle.stroke
      ..strokeWidth = hairlineWidth;

    for (
      var lon = Projection.minLongitude;
      lon <= Projection.maxLongitude;
      lon += Tokens.graticuleStep
    ) {
      final x = Projection.toCanvas(latitude: 0, longitude: lon, size: size).dx;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (
      var lat = Projection.minLatitude;
      lat <= Projection.maxLatitude;
      lat += Tokens.graticuleStep
    ) {
      final y = Projection.toCanvas(latitude: lat, longitude: 0, size: size).dy;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintArcs(Canvas canvas, Size size) {
    if (stations.length < 2) return;
    final legs = stations.length - 1;

    for (var i = 0; i < legs; i++) {
      // Arcs draw in chronological order, so the sequence reads as the career
      // propagating rather than as everything appearing at once.
      final legProgress = (drawProgress * legs - i).clamp(0.0, 1.0);
      if (legProgress <= 0) continue;

      final isActive = i + 1 == selectedIndex || i == selectedIndex;
      final points = GreatCircle.path(
        fromLatitude: stations[i].latitude,
        fromLongitude: stations[i].longitude,
        toLatitude: stations[i + 1].latitude,
        toLongitude: stations[i + 1].longitude,
      );

      final path = Path();
      final drawn = (points.length * legProgress).ceil().clamp(
        2,
        points.length,
      );
      for (var p = 0; p < drawn; p++) {
        final point = Projection.toCanvas(
          latitude: points[p].latitude,
          longitude: points[p].longitude,
          size: size,
        );
        // The antimeridian wrap would otherwise draw a line straight back
        // across the whole map.
        final previous = p == 0
            ? null
            : Projection.toCanvas(
                latitude: points[p - 1].latitude,
                longitude: points[p - 1].longitude,
                size: size,
              );
        if (p == 0 ||
            (previous != null &&
                (point.dx - previous.dx).abs() > size.width / 2)) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = isActive
              ? activeColour
              : arcColour.withValues(alpha: Tokens.arcOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = hairlineWidth,
      );
    }
  }

  void _paintNodes(Canvas canvas, Size size) {
    for (var i = 0; i < stations.length; i++) {
      final station = stations[i];
      final centre = Projection.toCanvas(
        latitude: station.latitude,
        longitude: station.longitude,
        size: size,
      );
      final isSelected = i == selectedIndex;
      // A minor station reads smaller: present and factual, not featured.
      final radius = isSelected
          ? Tokens.stationNodeActiveRadius
          : Tokens.stationNodeRadius * (station.isMinor ? 0.7 : 1);

      if (isSelected && pulse > 0) {
        canvas.drawCircle(
          centre,
          radius + pulse * Tokens.stationPulseRadius,
          Paint()
            ..color = activeColour.withValues(alpha: (1 - pulse) * 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = hairlineWidth,
        );
      }

      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..color = isSelected ? activeColour : nodeColour
          ..style = isSelected ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = hairlineWidth,
      );
    }
  }

  /// The canvas position of a station, for hit testing and panel placement.
  static Offset positionOf(MapStation station, Size size) =>
      Projection.toCanvas(
        latitude: station.latitude,
        longitude: station.longitude,
        size: size,
      );

  /// The station nearest [point], or null when nothing is close enough.
  static int? nearestTo(
    Offset point,
    List<MapStation> stations,
    Size size, {
    double within = Tokens.touchTarget,
  }) {
    var best = -1;
    var nearest = double.infinity;
    for (var i = 0; i < stations.length; i++) {
      final distance = (positionOf(stations[i], size) - point).distance;
      if (distance < nearest) {
        nearest = distance;
        best = i;
      }
    }
    return nearest <= within && best >= 0 ? best : null;
  }

  @override
  bool shouldRepaint(MapPainter oldDelegate) =>
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.drawProgress != drawProgress ||
      oldDelegate.pulse != pulse ||
      !identical(oldDelegate.coastlines, coastlines) ||
      oldDelegate.landColour != landColour ||
      oldDelegate.graticuleColour != graticuleColour ||
      oldDelegate.arcColour != arcColour ||
      oldDelegate.activeColour != activeColour ||
      oldDelegate.nodeColour != nodeColour ||
      oldDelegate.hairlineWidth != hairlineWidth ||
      !identical(oldDelegate.stations, stations);
}

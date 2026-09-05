import 'package:flutter/rendering.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/projection.dart';
import 'package:nocturne/core/painting/station_seed.dart';

/// A node in a procedural constellation, in canvas coordinates.
typedef StationNode = ({Offset centre, bool isBeacon});

/// Draws the constellation behind a station card.
///
/// Section 11 uses this wherever an application has no screenshot: the same
/// node-and-hairline vocabulary as the propagation map, at card scale, so a
/// missing asset reads as a designed treatment rather than a gap.
class StationCardPainter extends CustomPainter {
  /// [seedId] must be the application id so the card never shifts between
  /// loads; [latitude] and [longitude] place the beacon node where the work
  /// actually happened, and are absent when the content does not record it.
  const StationCardPainter({
    required this.seedId,
    required this.nodeColour,
    required this.beaconColour,
    required this.linkColour,
    required this.hairlineWidth,
    this.latitude,
    this.longitude,
  });

  /// Application id; the only input to the deterministic layout.
  final String seedId;

  /// Resting node colour.
  final Color nodeColour;

  /// The single amber node.
  final Color beaconColour;

  /// Connecting hairline colour.
  final Color linkColour;

  /// Hairline stroke width, from tokens.
  final double hairlineWidth;

  /// Latitude of the application's country, when the content records one.
  final double? latitude;

  /// Longitude of the application's country, when the content records one.
  final double? longitude;

  /// Resolves the constellation for [size].
  ///
  /// Exposed so the geometry can be asserted directly rather than inferred
  /// from a rendered image, and so a test can prove that two cards built with
  /// the same id agree node for node.
  List<StationNode> nodesFor(Size size) {
    final field = Rect.fromLTWH(
      Tokens.space16,
      Tokens.space16,
      size.width - Tokens.space16 * 2,
      size.height - Tokens.space16 * 2,
    );
    if (field.width <= 0 || field.height <= 0) return const [];

    final seed = StationSeed(seedId);
    const span = Tokens.stationNodeMax - Tokens.stationNodeMin + 1;
    final count = Tokens.stationNodeMin + seed.nextInt(span);

    final nodes = <Offset>[
      for (var i = 0; i < count; i++)
        Offset(
          seed.nextRange(field.left, field.right),
          seed.nextRange(field.top, field.bottom),
        ),
    ];

    // A recorded country places the beacon geographically; otherwise it marks
    // the first seeded node, so there is always exactly one beacon and never an
    // invented location.
    final lat = latitude;
    final lon = longitude;
    if (lat != null && lon != null) {
      final projected = Projection.toCanvas(
        latitude: lat,
        longitude: lon,
        size: field.size,
      );
      nodes.add(projected.translate(field.left, field.top));
    }
    final beaconIndex = lat != null && lon != null ? nodes.length - 1 : 0;

    return [
      for (var i = 0; i < nodes.length; i++)
        (centre: nodes[i], isBeacon: i == beaconIndex),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final nodes = nodesFor(size);
    if (nodes.isEmpty) return;

    // Each node links to its nearest neighbour. This gives a connected-looking
    // constellation at a fraction of the strokes a full graph would draw, and
    // it never produces the tangle that random pairing does.
    final link = Paint()
      ..color = linkColour
      ..style = PaintingStyle.stroke
      ..strokeWidth = hairlineWidth;
    final drawn = <String>{};
    for (var i = 0; i < nodes.length; i++) {
      var nearest = -1;
      var nearestDistance = double.infinity;
      for (var j = 0; j < nodes.length; j++) {
        if (i == j) continue;
        final distance = (nodes[i].centre - nodes[j].centre).distanceSquared;
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearest = j;
        }
      }
      if (nearest < 0) continue;
      final key = i < nearest ? '$i:$nearest' : '$nearest:$i';
      if (!drawn.add(key)) continue;
      canvas.drawLine(nodes[i].centre, nodes[nearest].centre, link);
    }

    for (final node in nodes) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: node.centre,
            width: Tokens.space8,
            height: Tokens.space8,
          ),
          const Radius.circular(Tokens.tagRadius),
        ),
        Paint()..color = node.isBeacon ? beaconColour : nodeColour,
      );
    }
  }

  @override
  bool shouldRepaint(StationCardPainter oldDelegate) =>
      oldDelegate.seedId != seedId ||
      oldDelegate.nodeColour != nodeColour ||
      oldDelegate.beaconColour != beaconColour ||
      oldDelegate.linkColour != linkColour ||
      oldDelegate.hairlineWidth != hairlineWidth ||
      oldDelegate.latitude != latitude ||
      oldDelegate.longitude != longitude;
}

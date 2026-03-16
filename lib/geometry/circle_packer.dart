import 'dart:ui';
import 'models.dart';
import 'path_sampler.dart';

class CirclePacker {
  /// Distributes circles along the arc length of the path.
  /// 
  /// From the requirements and architecture design:
  /// - First circle is at arc length `r` (boundary at path start).
  /// - Subsequent circles are spaced `2r` apart along the curve.
  /// - Stop packing when a circle's start position extends beyond the path.
  /// 
  /// The packing guarantees:
  /// 1. The first circle's leading edge is exactly at position 0 (path start).
  /// 2. Circles are placed edge-to-edge with diameter spacing (2r).
  /// 3. The final circle may extend beyond the path end and will be clipped during rendering.
  static List<PackedCircle> pack(SampledPath sampledPath, double radius) {
    List<PackedCircle> circles = [];
    
    // Safety checks
    if (radius <= 0 || sampledPath.totalLength <= 0) return circles;
    if (sampledPath.totalLength < radius) return circles;

    double currentArc = radius; // First circle center at arc = r, so edge starts at 0
    double diameter = radius * 2;

    // Continue packing while the circle's leading edge hasn't passed the path end
    while (currentArc - radius < sampledPath.totalLength) {
      // The circle might extend beyond totalLength, but we still pack it
      // because it will be clipped during rendering to the exact endpoint.
      
      // Calculate center position along the curve
      Offset center = sampledPath.getPositionAt(currentArc);
      
      circles.add(PackedCircle(
        center: center,
        radius: radius,
        arcLengthStart: currentArc - radius,
        arcLengthEnd: currentArc + radius,
      ));

      currentArc += diameter;
    }

    return circles;
  }
}

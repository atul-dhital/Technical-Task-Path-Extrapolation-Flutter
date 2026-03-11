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
  static List<PackedCircle> pack(SampledPath sampledPath, double radius) {
    List<PackedCircle> circles = [];
    if (sampledPath.totalLength < radius || radius <= 0) return circles;

    double currentArc = radius;
    double diameter = radius * 2;

    while (currentArc - radius <= sampledPath.totalLength) {
      // The circle might extend slightly beyond totalLength, 
      // but if its starting edge is before the end, we place it 
      // and it will be clipped during rendering.
      
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

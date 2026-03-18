import 'dart:ui';
import 'models.dart';
import 'path_sampler.dart';

class CirclePacker {
  static List<PackedCircle> pack(SampledPath sampledPath, double radius) {
    List<PackedCircle> circles = [];
    
    if (radius <= 0 || sampledPath.totalLength <= 0) return circles;
    if (sampledPath.totalLength < radius) return circles;

    double currentArc = radius;
    double diameter = radius * 2;

    while (currentArc - radius < sampledPath.totalLength) {
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

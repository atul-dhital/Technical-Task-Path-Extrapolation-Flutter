import 'dart:ui';

class PathPoint {
  Offset position;
  final String label;

  PathPoint(this.position, this.label);
}

class BestFitLine {
  final Offset centroid;
  final Offset direction;

  BestFitLine(this.centroid, this.direction);

  Offset project(Offset point) {
    Offset v = point - centroid;
    double dotProduct = v.dx * direction.dx + v.dy * direction.dy;
    return centroid + direction * dotProduct;
  }
}

class PackedCircle {
  final Offset center;
  final double radius;
  final double arcLengthStart;
  final double arcLengthEnd;

  PackedCircle({
    required this.center,
    required this.radius,
    required this.arcLengthStart,
    required this.arcLengthEnd,
  });
}

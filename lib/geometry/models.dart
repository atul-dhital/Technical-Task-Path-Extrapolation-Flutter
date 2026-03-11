import 'dart:ui';

/// Represents a point in 2D space that can be dragged.
class PathPoint {
  Offset position;
  final String label;

  PathPoint(this.position, this.label);
}

/// Represents the best fit line found via PCA.
class BestFitLine {
  final Offset centroid;
  final Offset direction; // Unit vector

  BestFitLine(this.centroid, this.direction);

  /// Projects a given point onto this line.
  Offset project(Offset point) {
    Offset v = point - centroid;
    double dotProduct = v.dx * direction.dx + v.dy * direction.dy;
    return centroid + direction * dotProduct;
  }
}

/// Represents a circle placed along the path.
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

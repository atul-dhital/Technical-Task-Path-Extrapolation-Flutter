import 'dart:ui';

class SplineBuilder {
  static List<Offset> buildCatmullRom(List<Offset> points, {int samplesPerSegment = 50}) {
    if (points.length < 2) return List.from(points);

    List<Offset> path = [];
    
    List<Offset> controlPoints = [
      points.first - (points[1] - points.first),
      ...points,
      points.last + (points.last - points[points.length - 2]),
    ];

    for (int i = 0; i < points.length - 1; i++) {
      Offset p0 = controlPoints[i];
      Offset p1 = controlPoints[i + 1];
      Offset p2 = controlPoints[i + 2];
      Offset p3 = controlPoints[i + 3];

      for (int t = 0; t < samplesPerSegment; t++) {
        double mt = t / samplesPerSegment;
        path.add(_catmullRom(p0, p1, p2, p3, mt));
      }
    }
    path.add(points.last);
    return path;
  }

  static Offset _catmullRom(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    double t2 = t * t;
    double t3 = t2 * t;

    return Offset(
      0.5 * (
        (2 * p1.dx) +
        (-p0.dx + p2.dx) * t +
        (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 +
        (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3
      ),
      0.5 * (
        (2 * p1.dy) +
        (-p0.dy + p2.dy) * t +
        (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 +
        (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3
      ),
    );
  }
}

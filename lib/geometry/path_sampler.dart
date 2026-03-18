import 'dart:ui';
import 'dart:math';

class SampledPath {
  final List<Offset> points;
  final List<double> cumulativeLengths;
  final double totalLength;

  SampledPath(this.points, this.cumulativeLengths, this.totalLength);

  Offset getPositionAt(double arcLength) {
    if (points.isEmpty) return Offset.zero;
    if (points.length == 1) return points.first;
    
    if (arcLength <= 0) return points.first;
    if (arcLength >= totalLength) return points.last;

    int low = 0;
    int high = cumulativeLengths.length - 1;

    while (low <= high) {
      int mid = (low + high) ~/ 2;
      if (cumulativeLengths[mid] < arcLength) {
        low = mid + 1;
      } else if (cumulativeLengths[mid] > arcLength) {
        high = mid - 1;
      } else {
        return points[mid];
      }
    }

    int index = low;
    if (index == 0) return points.first;

    double prevLength = cumulativeLengths[index - 1];
    double nextLength = cumulativeLengths[index];
    double segmentLength = nextLength - prevLength;

    if (segmentLength <= 0) return points[index];

    double t = (arcLength - prevLength) / segmentLength;
    Offset p1 = points[index - 1];
    Offset p2 = points[index];

    return p1 + (p2 - p1) * t;
  }

  Offset getTangentAt(double arcLength, {double delta = 0.5}) {
    if (points.isEmpty) return const Offset(1, 0);
    if (points.length == 1) return const Offset(1, 0);

    double s1 = (arcLength - delta).clamp(0.0, totalLength).toDouble();
    double s2 = (arcLength + delta).clamp(0.0, totalLength).toDouble();

    Offset p1 = getPositionAt(s1);
    Offset p2 = getPositionAt(s2);

    Offset tangent = p2 - p1;
    double len = tangent.distance;

    if (len > 1e-6) {
      return tangent / len;
    }

    return const Offset(1, 0);
  }
}

class PathSampler {
  static SampledPath sample(List<Offset> points) {
    if (points.isEmpty) return SampledPath([], [], 0.0);
    
    List<double> cumulative = [0.0];
    double total = 0.0;
    
    for (int i = 1; i < points.length; i++) {
      double dist = (points[i] - points[i - 1]).distance;
      total += dist;
      cumulative.add(total);
    }
    
    return SampledPath(points, cumulative, total);
  }
}

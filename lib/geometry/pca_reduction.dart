import 'dart:math';
import 'dart:ui';
import 'models.dart';

class PCA {
  /// Computes the best fit line through a set of points using PCA.
  static BestFitLine computeBestFitLine(List<Offset> points) {
    if (points.isEmpty) return BestFitLine(Offset.zero, const Offset(1, 0));
    if (points.length == 1) return BestFitLine(points.first, const Offset(1, 0));

    // 1. Calculate centroid
    double sumX = 0, sumY = 0;
    for (var p in points) {
      sumX += p.dx;
      sumY += p.dy;
    }
    int n = points.length;
    Offset centroid = Offset(sumX / n, sumY / n);

    // 2. Calculate covariance matrix
    double cXX = 0, cYY = 0, cXY = 0;
    for (var p in points) {
      double dx = p.dx - centroid.dx;
      double dy = p.dy - centroid.dy;
      cXX += dx * dx;
      cYY += dy * dy;
      cXY += dx * dy;
    }
    cXX /= n;
    cYY /= n;
    cXY /= n;

    // 3. Find eigenvalues and eigenvectors
    // Characteristic equation: lambda^2 - (cXX + cYY)*lambda + (cXX*cYY - cXY^2) = 0
    double trace = cXX + cYY;
    double det = cXX * cYY - cXY * cXY;
    
    // Discriminant
    double disc = trace * trace - 4 * det;
    if (disc < 0) disc = 0; // Prevent NaN from floating point inaccuracies
    
    // Largest eigenvalue
    double lambda1 = (trace + sqrt(disc)) / 2;

    // The principal eigenvector corresponding to lambda1 determines the direction
    Offset dir;
    if (cXY == 0) {
      // Points aligned with axes
      dir = cXX > cYY ? const Offset(1, 0) : const Offset(0, 1);
    } else {
      dir = Offset(cXY, lambda1 - cXX);
      double len = dir.distance;
      if (len > 0) {
        dir /= len;
      } else {
        dir = const Offset(1, 0);
      }
    }

    return BestFitLine(centroid, dir);
  }
}

class ReductionStep {
  /// Reduces candidate points to a single point by projecting onto PCA line 
  /// and picking the one farthest from P2.
  static Offset reduce(List<Offset> candidates, Offset p2, {BestFitLine? outLine}) {
    if (candidates.isEmpty) return Offset.zero;
    if (candidates.length == 1) return candidates.first;

    BestFitLine line = PCA.computeBestFitLine(candidates);
    
    // Optional copy-out for debug rendering
    if (outLine != null) {
      outLine = line; 
      // Note: outLine assignment won't work in Dart like this, 
      // so we will export this from a combined state object instead.
    }

    Offset bestProjected = candidates.first;
    double maxDistSq = -1.0;

    for (var candidate in candidates) {
      Offset projected = line.project(candidate);
      double distSq = (projected - p2).distanceSquared;
      if (distSq > maxDistSq) {
        maxDistSq = distSq;
        bestProjected = projected;
      }
    }

    return bestProjected;
  }
}

import 'dart:math';
import 'dart:ui';
import 'models.dart';

class PCA {
  static BestFitLine computeBestFitLine(List<Offset> points) {
    if (points.isEmpty) return BestFitLine(Offset.zero, const Offset(1, 0));
    if (points.length == 1) return BestFitLine(points.first, const Offset(1, 0));

    double sumX = 0, sumY = 0;
    for (var p in points) {
      sumX += p.dx;
      sumY += p.dy;
    }
    int n = points.length;
    Offset centroid = Offset(sumX / n, sumY / n);

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

    double trace = cXX + cYY;
    double det = cXX * cYY - cXY * cXY;
    
    double disc = trace * trace - 4 * det;
    if (disc < 0) disc = 0;
    
    double lambda1 = (trace + sqrt(disc)) / 2;

    Offset dir;
    if (cXY == 0) {
      if (cXX == 0 && cYY == 0) {
        dir = const Offset(1, 0); // Default for identical candidates
      } else {
        dir = cXX > cYY ? const Offset(1, 0) : const Offset(0, 1);
      }
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
  static ReductionResult reduce(List<Offset> candidates, Offset p2) {
    if (candidates.isEmpty) {
      return ReductionResult(Offset.zero, BestFitLine(Offset.zero, const Offset(1, 0)));
    }
    if (candidates.length == 1) {
      return ReductionResult(candidates.first, BestFitLine(candidates.first, const Offset(1, 0)));
    }

    BestFitLine line = PCA.computeBestFitLine(candidates);
    
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

    return ReductionResult(bestProjected, line);
  }
}

import 'package:flutter/material.dart';
import '../geometry/models.dart';
import '../geometry/pca_reduction.dart';
import '../geometry/spline_builder.dart';
import '../geometry/path_sampler.dart';
import '../geometry/circle_packer.dart';

class AppState extends ChangeNotifier {
  // Draggable points
  List<PathPoint> candidates = [];
  List<PathPoint> pathPoints = []; // 4 points (P2, P3, P4, P5)
  
  // Toggles
  bool showDebug = true;
  bool showCircles = true;
  bool showClipBoundary = true;
  bool enableAnimation = true;

  // Animation
  double animationProgress = 1.0; 

  // Computed state
  Offset? reducedPoint;
  BestFitLine? pcaLine;
  SampledPath? sampledPath;
  List<PackedCircle> circles = [];
  double circleRadius = 15.0;

  void initialize(Size size) {
    if (candidates.isNotEmpty) return;

    // Initial proportional layout
    candidates = [
      PathPoint(Offset(size.width * 0.1, size.height * 0.2), "C1"),
      PathPoint(Offset(size.width * 0.15, size.height * 0.4), "C2"),
      PathPoint(Offset(size.width * 0.08, size.height * 0.6), "C3"),
    ];

    pathPoints = [
      PathPoint(Offset(size.width * 0.3, size.height * 0.4), "P2"),
      PathPoint(Offset(size.width * 0.5, size.height * 0.3), "P3"),
      PathPoint(Offset(size.width * 0.7, size.height * 0.5), "P4"),
      PathPoint(Offset(size.width * 0.9, size.height * 0.4), "P5"),
    ];

    recompute();
  }

  void moveCandidate(int index, Offset newPos) {
    candidates[index].position = newPos;
    recompute();
  }

  void movePathPoint(int index, Offset newPos) {
    pathPoints[index].position = newPos;
    recompute();
  }

  void setAnimationProgress(double progress) {
    animationProgress = progress.clamp(0.0, 1.0);
    notifyListeners();
  }

  void toggleDebug() {
    showDebug = !showDebug;
    notifyListeners();
  }

  void toggleCircles() {
    showCircles = !showCircles;
    notifyListeners();
  }

  void toggleClip() {
    showClipBoundary = !showClipBoundary;
    notifyListeners();
  }
  
  void toggleAnimation() {
    enableAnimation = !enableAnimation;
    if (!enableAnimation) {
      animationProgress = 1.0;
    }
    notifyListeners();
  }

  void updateRadius(double newRadius) {
    circleRadius = newRadius;
    recompute();
  }

  void recompute() {
    if (candidates.isEmpty || pathPoints.isEmpty) return;

    // 1. Reduction Step
    pcaLine = PCA.computeBestFitLine(candidates.map((c) => c.position).toList());
    
    Offset bestProjected = candidates.first.position;
    double maxDistSq = -1.0;
    
    Offset p2 = pathPoints.first.position;
    for (var candidate in candidates) {
      Offset projected = pcaLine!.project(candidate.position);
      double distSq = (projected - p2).distanceSquared;
      if (distSq > maxDistSq) {
        maxDistSq = distSq;
        bestProjected = projected;
      }
    }
    reducedPoint = bestProjected;

    // 2. Smooth Path
    List<Offset> allPoints = [reducedPoint!, ...pathPoints.map((p) => p.position)];
    List<Offset> rawSplinePoints = SplineBuilder.buildCatmullRom(allPoints, samplesPerSegment: 100);

    // 3. Arc length parameterization
    sampledPath = PathSampler.sample(rawSplinePoints);

    // 4. Circle Packing
    circles = CirclePacker.pack(sampledPath!, circleRadius);

    notifyListeners();
  }
}

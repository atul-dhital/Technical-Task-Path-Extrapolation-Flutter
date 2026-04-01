import 'package:flutter/material.dart';
import '../geometry/models.dart';
import '../geometry/pca_reduction.dart';
import '../geometry/spline_builder.dart';
import '../geometry/path_sampler.dart';
import '../geometry/circle_packer.dart';

class AppState extends ChangeNotifier {
  List<PathPoint> candidates = [];
  List<PathPoint> pathPoints = [];
  
  bool showDebug = true;
  bool showCircles = true;
  bool showClipBoundary = true;
  bool enableAnimation = true;

  double animationProgress = 1.0; 

  Offset? reducedPoint;
  BestFitLine? pcaLine;
  SampledPath? sampledPath;
  List<PackedCircle> circles = [];
  double circleRadius = 15.0;

  void initialize(Size size) {
    if (candidates.isNotEmpty) return;

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

    ReductionResult reduction = ReductionStep.reduce(
      candidates.map((c) => c.position).toList(),
      pathPoints.first.position,
    );
    
    pcaLine = reduction.line;
    reducedPoint = reduction.bestPoint;

    List<Offset> allPoints = [reducedPoint!, ...pathPoints.map((p) => p.position)];
    List<Offset> rawSplinePoints = SplineBuilder.buildCatmullRom(allPoints, samplesPerSegment: 100);

    sampledPath = PathSampler.sample(rawSplinePoints);

    circles = CirclePacker.pack(sampledPath!, circleRadius);

    notifyListeners();
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:path_extrapolation/geometry/pca_reduction.dart';
import 'package:path_extrapolation/geometry/spline_builder.dart';
import 'package:path_extrapolation/geometry/circle_packer.dart';
import 'package:path_extrapolation/geometry/path_sampler.dart';
import 'dart:ui';

void main() {
  group('Geometry Engine Tests V2', () {
    test('Reduction Step: Deterministic point selection via PCA', () {
      final candidates = [
        const Offset(10, 10),
        const Offset(50, 50),
        const Offset(100, 100),
      ];
      final p2 = const Offset(200, 200);

      final selected = ReductionStep.reduce(candidates, p2);
      
      expect((selected - const Offset(10, 10)).distance, lessThan(0.1));
    });

    test('Path Generation: Catmull-Rom produces valid spline', () {
      final points = [
        const Offset(0, 0),
        const Offset(10, 10),
        const Offset(20, 0),
        const Offset(30, 10),
        const Offset(40, 0),
      ];
      
      final path = SplineBuilder.buildCatmullRom(points, samplesPerSegment: 10);
      
      expect(path.length, greaterThan(40));
      expect(path.first, const Offset(0, 0));
      expect(path.last, const Offset(40, 0));
    });

    test('Circle Packing: Parameterized Spacing consistency', () {
      final points = [
        const Offset(0, 0),
        const Offset(100, 0),
      ]; // Degenerate strictly horizontal line
      
      final path = SplineBuilder.buildCatmullRom(points, samplesPerSegment: 10);
      final sampledPath = PathSampler.sample(path);

      const radius = 10.0;
      final circles = CirclePacker.pack(sampledPath, radius);
      
      // Total length 100. First circle at arc=10.
      // Next centers at 30, 50, 70, 90.
      expect(circles.length, 5);
      expect(circles[0].center.dx, closeTo(10, 0.5));
      expect(circles[1].center.dx, closeTo(30, 0.5));
      expect((circles[1].center - circles[0].center).distance, closeTo(20.0, 0.5));
    });

    test('PCA: Vertical axis detection', () {
      final points = [
        const Offset(100, 0),
        const Offset(100, 50),
        const Offset(100, 100),
      ];
      final line = PCA.computeBestFitLine(points);
      
      // Expect direction to be strictly vertical (0, 1) or (0, -1)
      expect(line.direction.dx, closeTo(0.0, 0.001));
      expect(line.direction.dy.abs(), closeTo(1.0, 0.001));
    });

    test('PCA: Identical candidates robustness', () {
      final points = [
        const Offset(100, 100),
        const Offset(100, 100),
        const Offset(100, 100),
      ];
      final line = PCA.computeBestFitLine(points);
      
      // Expect centroid at 100, 100
      expect(line.centroid, const Offset(100, 100));
      // Expect a valid, albeit default, direction (PCA should not crash)
      expect(line.direction.distance, closeTo(1.0, 0.001));
    });

    test('Endpoint Clipping: Tangent orientation at end of path', () {
      final points = [
        const Offset(0, 0),
        const Offset(100, 0),
      ];
      final path = PathSampler.sample(points);
      
      // Tangent at the end should point forward (+X)
      final tangent = path.getTangentAt(100.0);
      expect(tangent.dx, greaterThan(0.9));
      expect(tangent.dy, closeTo(0.0, 0.01));
    });
  });
}

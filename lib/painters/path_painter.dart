import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../geometry/models.dart';

class PathPainter extends CustomPainter {
  final AppState state;

  PathPainter(this.state) : super(repaint: state);

  @override
  void paint(Canvas canvas, Size size) {
    if (state.sampledPath == null) return;
    
    // Draw background grid (optional polish)
    _drawGrid(canvas, size);

    // 1. Draw Debug Overlays (Candidates, PCA, Projections)
    if (state.showDebug) {
      _drawDebugOverlays(canvas);
    }

    // 2. Draw Smooth Spline
    _drawSmoothPath(canvas);

    // 3. Draw Circles with Clipping
    if (state.showCircles) {
      _drawCirclePacking(canvas);
    }
    
    // 4. Draw Interactive Points
    _drawPoints(canvas);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  void _drawDebugOverlays(Canvas canvas) {
    if (state.pcaLine == null || state.reducedPoint == null) return;

    // Draw PCA axis
    final pcaPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
      
    // Extend the line across the screen
    Offset c = state.pcaLine!.centroid;
    Offset dir = state.pcaLine!.direction;
    canvas.drawLine(c - dir * 1000, c + dir * 1000, pcaPaint);

    // Draw projections
    final projPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeMiterLimit = 1
      ..strokeCap = StrokeCap.round; // Dash effect in full implementation is usually PathDash

    for (var candidate in state.candidates) {
      Offset pos = candidate.position;
      Offset proj = state.pcaLine!.project(pos);
      canvas.drawLine(pos, proj, projPaint);
      canvas.drawCircle(proj, 4, Paint()..color = Colors.cyan.withOpacity(0.6));
    }
  }

  void _drawSmoothPath(Canvas canvas) {
    final path = Path();
    var points = state.sampledPath!.points;
    if (points.isEmpty) return;

    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final paint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Only draw the path up to the animation progress if animation is playing
    double clipArcLength = state.sampledPath!.totalLength * state.animationProgress;
    
    // Instead of computing a sub-path, we can use a clipping region or just rely on the path metrics.
    // For simplicity, we draw the whole path but clip the canvas to the bounding rect of the segment, 
    // or we draw a PathMetric extracted subpath.
    // However, the spec doesn't require the Path itself to be animating, just the circles.
    // The instructions say: "Animate a progress value from 0 to 1 controlling circle visibility".
    // So we'll render the full path line.
    canvas.drawPath(path, paint);
  }

  void _drawCirclePacking(Canvas canvas) {
    if (state.circles.isEmpty) return;

    final circlePaint = Paint()
      ..color = Colors.pinkAccent.withOpacity(0.6)
      ..style = PaintingStyle.fill;
      
    final circleStrokePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    double clipArcLength = state.sampledPath!.totalLength * state.animationProgress;

    for (var circle in state.circles) {
      // If the circle's starting edge is beyond the current animation frontier, skip it.
      if (circle.arcLengthStart >= clipArcLength) {
        break;
      }

      // If the circle straddles the end of the total path (in final state) OR straddles the animation boundary
      bool needsClipping = circle.arcLengthEnd > clipArcLength;

      if (needsClipping) {
        // We perform a half-plane clip perpendicular to the path at clipArcLength.
        canvas.save();

        Offset clipPoint = state.sampledPath!.getPositionAt(clipArcLength);
        
        // Find tangent at the clip point using a tiny delta
        double delta = 0.5;
        double s1 = (clipArcLength - delta).clamp(0.0, state.sampledPath!.totalLength).toDouble();
        double s2 = (clipArcLength + delta).clamp(0.0, state.sampledPath!.totalLength).toDouble();
        
        Offset p1 = state.sampledPath!.getPositionAt(s1);
        Offset p2 = state.sampledPath!.getPositionAt(s2);
        
        Offset tangent = p2 - p1;
        double len = tangent.distance;
        if (len > 0) {
          tangent /= len;
        } else {
          // Fallback if tangent can't be computed
          tangent = const Offset(1, 0); 
        }
        
        // Perpendicular vector for the boundary line
        Offset normal = Offset(-tangent.dy, tangent.dx);
        
        // We want to keep everything BEFORE the clipPoint.
        // Construct a huge quad that represents the valid half-plane.
        // Moving backwards along the tangent from the clip point.
        const double side = 5000.0;
        
        Offset boundaryLeft = clipPoint + normal * side;
        Offset boundaryRight = clipPoint - normal * side;
        Offset backLeft = boundaryLeft - tangent * side;
        Offset backRight = boundaryRight - tangent * side;
        
        final clipPath = Path()
          ..moveTo(boundaryLeft.dx, boundaryLeft.dy)
          ..lineTo(boundaryRight.dx, boundaryRight.dy)
          ..lineTo(backRight.dx, backRight.dy)
          ..lineTo(backLeft.dx, backLeft.dy)
          ..close();

        canvas.clipPath(clipPath);
        
        // Draw the circle inside the clipped canvas
        canvas.drawCircle(circle.center, circle.radius, circlePaint);
        canvas.drawCircle(circle.center, circle.radius, circleStrokePaint);

        // Debug Clip Boundary visual
        if (state.showClipBoundary) {
          final clipLinePaint = Paint()
            ..color = Colors.redAccent
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke;
          canvas.drawLine(clipPoint + normal * 40, clipPoint - normal * 40, clipLinePaint);
        }

        canvas.restore();
      } else {
        // Draw normally
        canvas.drawCircle(circle.center, circle.radius, circlePaint);
        canvas.drawCircle(circle.center, circle.radius, circleStrokePaint);
      }
    }
  }

  void _drawPoints(Canvas canvas) {
    final candidatePaint = Paint()..color = Colors.orangeAccent;
    final otherPaint = Paint()..color = Colors.lightBlue;
    final reducedPaint = Paint()..color = Colors.greenAccent;
    
    // Reduced point
    if (state.reducedPoint != null) {
      canvas.drawCircle(state.reducedPoint!, 14, reducedPaint);
      canvas.drawCircle(state.reducedPoint!, 14, Paint()..color=Colors.white..style=PaintingStyle.stroke..strokeWidth=2);
      
      _drawLabel(canvas, "P1", state.reducedPoint!, Colors.black);
    }

    // Candidates
    for (var c in state.candidates) {
      canvas.drawCircle(c.position, 12, candidatePaint);
      canvas.drawCircle(c.position, 12, Paint()..color=Colors.white..style=PaintingStyle.stroke..strokeWidth=2);
      _drawLabel(canvas, c.label, c.position, Colors.black);
    }

    // Path points (P2-P5)
    for (var p in state.pathPoints) {
      canvas.drawCircle(p.position, 12, otherPaint);
      canvas.drawCircle(p.position, 12, Paint()..color=Colors.white..style=PaintingStyle.stroke..strokeWidth=2);
      _drawLabel(canvas, p.label, p.position, Colors.black);
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset center, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas, 
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2)
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; // AppState acts as Listenable
}

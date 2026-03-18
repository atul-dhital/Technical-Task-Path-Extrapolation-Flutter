import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../geometry/models.dart';

class PathPainter extends CustomPainter {
  final AppState state;

  PathPainter(this.state) : super(repaint: state);

  @override
  void paint(Canvas canvas, Size size) {
    if (state.sampledPath == null) return;
    
    _drawGrid(canvas, size);

    if (state.showDebug) {
      _drawDebugOverlays(canvas);
    }

    _drawSmoothPath(canvas);

    if (state.showCircles) {
      _drawCirclePacking(canvas);
    }
    
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

    final pcaPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
       
    Offset c = state.pcaLine!.centroid;
    Offset dir = state.pcaLine!.direction;
    canvas.drawLine(c - dir * 1000, c + dir * 1000, pcaPaint);

    final projPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeMiterLimit = 1
      ..strokeCap = StrokeCap.round;

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

    double clipArcLength = state.sampledPath!.totalLength * state.animationProgress;
    
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
      if (circle.arcLengthStart >= clipArcLength) {
        break;
      }

      bool needsClipping = circle.arcLengthEnd > clipArcLength;

      if (needsClipping) {
        canvas.save();

        Offset clipPoint = state.sampledPath!.getPositionAt(clipArcLength);
        
        double delta = _computeOptimalTangentDelta(clipArcLength, state.sampledPath!.totalLength);
        Offset tangent = state.sampledPath!.getTangentAt(clipArcLength, delta: delta);
        
        Offset normal = Offset(-tangent.dy, tangent.dx);
        
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
        
        canvas.drawCircle(circle.center, circle.radius, circlePaint);
        canvas.drawCircle(circle.center, circle.radius, circleStrokePaint);

        if (state.showClipBoundary) {
          final clipLinePaint = Paint()
            ..color = Colors.redAccent
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke;
          canvas.drawLine(clipPoint + normal * 40, clipPoint - normal * 40, clipLinePaint);
        }

        canvas.restore();
      } else {
        canvas.drawCircle(circle.center, circle.radius, circlePaint);
        canvas.drawCircle(circle.center, circle.radius, circleStrokePaint);
      }
    }
  }

  double _computeOptimalTangentDelta(double arcLength, double totalLength) {
    const double baseDelta = 0.5;
    const double maxDelta = 2.0;
    
    double distToStart = arcLength;
    double distToEnd = totalLength - arcLength;
    double minDistToBoundary = distToStart < distToEnd ? distToStart : distToEnd;
    
    if (minDistToBoundary < baseDelta) {
      return (minDistToBoundary * 0.4).clamp(baseDelta, maxDelta);
    }
    
    return baseDelta;
  }

  void _drawPoints(Canvas canvas) {
    final candidatePaint = Paint()..color = Colors.orangeAccent;
    final otherPaint = Paint()..color = Colors.lightBlue;
    final reducedPaint = Paint()..color = Colors.greenAccent;
    
    if (state.reducedPoint != null) {
      canvas.drawCircle(state.reducedPoint!, 14, reducedPaint);
      canvas.drawCircle(state.reducedPoint!, 14, Paint()..color=Colors.white..style=PaintingStyle.stroke..strokeWidth=2);
      
      _drawLabel(canvas, "P1", state.reducedPoint!, Colors.black);
    }

    for (var c in state.candidates) {
      canvas.drawCircle(c.position, 12, candidatePaint);
      canvas.drawCircle(c.position, 12, Paint()..color=Colors.white..style=PaintingStyle.stroke..strokeWidth=2);
      _drawLabel(canvas, c.label, c.position, Colors.black);
    }

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

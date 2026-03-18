import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../painters/path_painter.dart';
import '../geometry/models.dart';

class PathCanvasWidget extends StatefulWidget {
  final AppState state;

  const PathCanvasWidget({super.key, required this.state});

  @override
  State<PathCanvasWidget> createState() => _PathCanvasWidgetState();
}

class _PathCanvasWidgetState extends State<PathCanvasWidget> {
  int? _draggingCandidateIndex;
  int? _draggingPathPointIndex;
  
  static const double hitRadius = 25.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        Offset pos = details.localPosition;
        
        for (int i = 0; i < widget.state.candidates.length; i++) {
          if ((widget.state.candidates[i].position - pos).distance <= hitRadius) {
            _draggingCandidateIndex = i;
            return;
          }
        }
        
        for (int i = 0; i < widget.state.pathPoints.length; i++) {
          if ((widget.state.pathPoints[i].position - pos).distance <= hitRadius) {
            _draggingPathPointIndex = i;
            return;
          }
        }
      },
      onPanUpdate: (details) {
        if (_draggingCandidateIndex != null) {
          widget.state.moveCandidate(_draggingCandidateIndex!, details.localPosition);
        } else if (_draggingPathPointIndex != null) {
          widget.state.movePathPoint(_draggingPathPointIndex!, details.localPosition);
        }
      },
      onPanEnd: (details) {
        _draggingCandidateIndex = null;
        _draggingPathPointIndex = null;
      },
      child: ClipRect(
        child: CustomPaint(
          size: Size.infinite,
          painter: PathPainter(widget.state),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'state/app_state.dart';
import 'widgets/path_canvas.dart';

void main() {
  runApp(const PathExtrapolationApp());
}

class PathExtrapolationApp extends StatelessWidget {
  const PathExtrapolationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Path Extrapolation (Arch V2)',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent, brightness: Brightness.dark),
      ),
      home: const PathExtrapolationHome(),
    );
  }
}

class PathExtrapolationHome extends StatefulWidget {
  const PathExtrapolationHome({super.key});

  @override
  State<PathExtrapolationHome> createState() => _PathExtrapolationHomeState();
}

class _PathExtrapolationHomeState extends State<PathExtrapolationHome> with SingleTickerProviderStateMixin {
  final AppState _appState = AppState();
  late AnimationController _animController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _animController.addListener(() {
      if (_appState.enableAnimation) {
        _appState.setAnimationProgress(_animController.value);
      }
    });

    _animController.repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geometry Engine & Circle Packing'),
        elevation: 0,
        backgroundColor: Colors.black45,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (!_initialized) {
            _appState.initialize(Size(constraints.maxWidth, constraints.maxHeight));
            _initialized = true;
          }

          return Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Stack(
                    children: [
                      PathCanvasWidget(state: _appState),
                      const Positioned(
                        top: 16,
                        right: 16,
                        child: LegendWidget(),
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black45,
                child: AnimatedBuilder(
                  animation: _appState,
                  builder: (context, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Circle Radius: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Slider(
                                value: _appState.circleRadius,
                                min: 10,
                                max: 100,
                                onChanged: _appState.updateRadius,
                              ),
                            ),
                            Text('${_appState.circleRadius.toStringAsFixed(1)}px'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildToggle('Debug Overlays', _appState.showDebug, _appState.toggleDebug),
                            _buildToggle('Circle Packing', _appState.showCircles, _appState.toggleCircles),
                            _buildToggle('Clip Boundary', _appState.showClipBoundary, _appState.toggleClip),
                            _buildToggle('Animation', _appState.enableAnimation, () {
                              _appState.toggleAnimation();
                              if (_appState.enableAnimation) {
                                _animController.repeat();
                              } else {
                                _animController.stop();
                              }
                            }),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToggle(String label, bool value, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: value,
      onSelected: (_) => onTap(),
      selectedColor: Colors.blueAccent.withOpacity(0.3),
    );
  }
}

class LegendWidget extends StatelessWidget {
  const LegendWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legendItem(Colors.orangeAccent, 'Candidate Points (C1-C3)'),
          const SizedBox(height: 4),
          _legendItem(Colors.lightBlue, 'Path Points (P2-P5)'),
          const SizedBox(height: 4),
          _legendItem(Colors.greenAccent, 'Reduced Point (P1)'),
          const SizedBox(height: 4),
          _legendItem(Colors.pinkAccent, 'Packed Circles'),
        ],
      ),
    );
  }
  
  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}

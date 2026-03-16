# Technical Implementation Details

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│ UI Layer (main.dart, path_canvas.dart)                 │
│ - Interactive gestures                                  │
│ - Control panel & toggles                              │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────┴────────────────────────────────────┐
│ State Management (app_state.dart)                       │
│ - Centralized AppState with ChangeNotifier             │
│ - Triggers recomputation on any point change           │
│ - Caches geometry results                              │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┴─────────────────┐
        │                              │
┌───────▼─────────────┐    ┌──────────▼─────────────┐
│ Geometry Layer      │    │ Rendering Layer        │
│ (lib/geometry/)     │    │ (lib/painters/)        │
│                     │    │                        │
│ Pure mathematics    │    │ Canvas-based rendering │
│ No Flutter deps     │    │ Visualization          │
└─────────────────────┘    └────────────────────────┘
```

---

## State Flow Diagram

```
User Interaction (drag point)
        │
        ▼
moveCandidate() / movePathPoint()
        │
        ▼
recompute() ─┬─────────────────────┐
             │                     │
        ┌────▼────┐        ┌───────▼────────┐
        │   PCA   │        │ Spline Builder │
        │ Reduction│        │ (Catmull-Rom)  │
        └────┬────┘        └───────┬────────┘
             │                     │
        ┌────▼────────────────────▼────────┐
        │   Path Sampler                   │
        │   (Arc-Length Parameterization)  │
        └────┬────────────────────────────┘
             │
        ┌────▼──────────────┐
        │ Circle Packer     │
        │ (Edge-to-Edge)    │
        └────┬──────────────┘
             │
        ┌────▼──────────────────────┐
        │ notifyListeners()         │
        │ (Trigger widget rebuild)  │
        └────┬──────────────────────┘
             │
        ┌────▼──────────────────────────┐
        │ PathPainter.paint() renders   │
        │ - Path line                   │
        │ - Circles with clipping       │
        │ - Debug overlays              │
        └──────────────────────────────┘
```

---

## Detailed Algorithm Explanations

### 1. PCA Reduction Step

**Input**: List of candidate points, reference point P2  
**Output**: Single reduced point P1

**Algorithm**:

```
1. Compute centroid:
   centroid = (Σx / n, Σy / n)

2. Compute covariance matrix:
   cXX = Σ(x - centroid_x)² / n
   cYY = Σ(y - centroid_y)² / n
   cXY = Σ(x - centroid_x)(y - centroid_y) / n

3. Eigenvalue via characteristic equation:
   det = cXX * cYY - cXY²
   trace = cXX + cYY
   lambda1 = (trace + √(trace² - 4*det)) / 2

4. Eigenvector (principal direction):
   if cXY == 0:
       dir = (1, 0) if cXX > cYY else (0, 1)
   else:
       dir = (cXY, lambda1 - cXX)
       normalize dir

5. For each candidate:
       proj = centroid + (candidate - centroid) · dir * dir
       dist² = ||proj - P2||²
       if dist² > maxDist:
           maxDist = dist²
           selected = proj

6. Return selected
```

**Numerical Stability**:
- Negative discriminant is clamped to 0
- Zero-length vectors default to axis directions
- All comparisons use `>` rather than exact equality

---

### 2. Catmull-Rom Spline

**Input**: 5 control points (P1, P2, P3, P4, P5)  
**Output**: Dense list of sampled points (~400 points)

**Cubic Basis Functions** for $t \in [0, 1]$:

$$B_0(t) = -0.5 t^3 + t^2 - 0.5 t$$
$$B_1(t) = 1.5 t^3 - 2.5 t^2 + 1$$
$$B_2(t) = -1.5 t^3 + 2 t^2 + 0.5 t$$
$$B_3(t) = 0.5 t^3 - 0.5 t^2$$

**Position Formula**:

$$\mathbf{P}(t) = B_0(t) \mathbf{p}_0 + B_1(t) \mathbf{p}_1 + B_2(t) \mathbf{p}_2 + B_3(t) \mathbf{p}_3$$

**Phantom Point Construction**:
- Pre-phantom: $\mathbf{p}_0 = \mathbf{p}_1 - (\mathbf{p}_2 - \mathbf{p}_1)$
- Post-phantom: $\mathbf{p}_6 = \mathbf{p}_5 + (\mathbf{p}_5 - \mathbf{p}_4)$

This ensures the curve enters P1 and exits P5 tangentially.

**Sampling**:
```dart
for (segment 0 to 3) {
    for (t = 0 to 1, step 1/samplesPerSegment) {
        point = catmullRom(p0, p1, p2, p3, t)
        path.add(point)
    }
}
path.add(p_last)  // Ensure exact endpoint
```

---

### 3. Arc-Length Parameterization

**Input**: Dense spline points  
**Output**: SampledPath with cumulative arc lengths

**Algorithm**:

```
cumulative = [0.0]
total = 0.0

for i = 1 to points.length:
    dist = ||points[i] - points[i-1]||
    total += dist
    cumulative.add(total)

return SampledPath(points, cumulative, total)
```

**Position Lookup**:

```
getPositionAt(arcLength):
    1. Binary search to find index where cumulative[index] ≤ arcLength < cumulative[index+1]
    2. Linear interpolate: 
           t = (arcLength - cumulative[index]) / (cumulative[index+1] - cumulative[index])
           return points[index] + t * (points[index+1] - points[index])
```

**Tangent Computation**:

```
getTangentAt(arcLength, delta):
    p1 = getPositionAt(arcLength - delta)
    p2 = getPositionAt(arcLength + delta)
    tangent = (p2 - p1) / ||p2 - p1||
    if ||p2 - p1|| < epsilon:
        return (1, 0)  // fallback
    return tangent
```

---

### 4. Circle Packing

**Input**: SampledPath, circle radius  
**Output**: List of PackedCircle objects

**Algorithm**:

```
circles = []
currentArc = radius  // First circle center at s = r

while currentArc - radius < totalLength:
    center = sampledPath.getPositionAt(currentArc)
    circle = PackedCircle(
        center: center,
        radius: radius,
        arcLengthStart: currentArc - radius,
        arcLengthEnd: currentArc + radius
    )
    circles.add(circle)
    currentArc += 2 * radius  // Spacing: diameter
```

**Key Properties**:
- First circle boundary starts exactly at arc = 0
- Circles are spaced diameter (2r) apart in arc space
- Final circle may extend beyond totalLength (will be clipped)
- Placement is fully deterministic

---

### 5. Half-Plane Clipping

**Input**: Circle center, radius, clip arc length, sampled path  
**Output**: Clipped circle rendering

**Algorithm**:

```
clipPoint = sampledPath.getPositionAt(clipArcLength)
tangent = sampledPath.getTangentAt(clipArcLength, adaptiveDelta)
normal = rotate90(tangent) = (-tangent.y, tangent.x)

// Construct clipping quad (half-plane)
// Keep everything "before" the clip point (backward along tangent)
const side = 5000

boundaryLeft = clipPoint + normal * side
boundaryRight = clipPoint - normal * side
backLeft = boundaryLeft - tangent * side
backRight = boundaryRight - tangent * side

clipPath = Path()
    .moveTo(boundaryLeft)
    .lineTo(boundaryRight)
    .lineTo(backRight)
    .lineTo(backLeft)
    .close()

canvas.clipPath(clipPath)
canvas.drawCircle(circle.center, circle.radius, paint)
canvas.restore()
```

**Why Half-Plane Clipping?**
- Perpendicular boundary aligns with curve tangent
- Mathematically exact (not approximation)
- No per-pixel overhead
- Seamless animation as boundary moves

---

## Data Structures

### PathPoint
```dart
class PathPoint {
  Offset position;        // Mutable, updated during interaction
  final String label;     // "C1", "C2", "P1", "P2", etc.
}
```

### BestFitLine
```dart
class BestFitLine {
  Offset centroid;        // Center of candidate cluster
  Offset direction;       // Normalized principal eigenvector
  
  Offset project(Offset point) {
    // Project point onto line: centroid + (point-centroid)·dir * dir
  }
}
```

### SampledPath
```dart
class SampledPath {
  List<Offset> points;                // Dense spline points
  List<double> cumulativeLengths;     // Arc length at each point
  double totalLength;                 // Path length
  
  Offset getPositionAt(double arcLength);
  Offset getTangentAt(double arcLength, {double delta});
}
```

### PackedCircle
```dart
class PackedCircle {
  Offset center;          // Center position
  double radius;          // Circle radius (constant)
  double arcLengthStart;  // Arc length where leading edge starts
  double arcLengthEnd;    // Arc length where trailing edge ends
}
```

### AppState
```dart
class AppState extends ChangeNotifier {
  List<PathPoint> candidates;         // C1, C2, C3
  List<PathPoint> pathPoints;         // P2, P3, P4, P5
  Offset reducedPoint;                // P1 (computed)
  BestFitLine pcaLine;                // Debug visualization
  SampledPath sampledPath;            // Arc-parameterized path
  List<PackedCircle> circles;         // Packed circles
  
  bool showDebug, showCircles, showClipBoundary, enableAnimation;
  double circleRadius;
  double animationProgress;           // 0.0 to 1.0
  
  void recompute();                   // Triggers full geometry update
}
```

---

## Performance Characteristics

| Operation | Time Complexity | Notes |
|-----------|-----------------|-------|
| PCA | O(n) | n = candidate count (3) |
| Spline Sampling | O(m) | m = segments × samples (~400) |
| Arc Parameterization | O(m) | Single linear pass |
| Circle Packing | O(k) | k = number of circles (5–20) |
| Position Lookup | O(log m) | Binary search |
| Tangent Computation | O(1) | Two lookups + normalization |
| Rendering (paint) | O(k + m) | Draw circles + path |
| **Total per frame** | **O(m + k)** | ~5ms on modern devices |

**Memory Usage**:
- Dense spline points: ~400 Offsets (~6.4 KB)
- Cumulative lengths: ~400 doubles (~3.2 KB)
- Packed circles: ~10 objects (~1 KB)
- **Total**: < 20 KB (negligible)

---

## Error Handling & Edge Cases

### Division by Zero
```dart
// Arc parameterization: prevent division by segment length = 0
if (segmentLength <= 0) return points[index];

// Tangent normalization
double len = tangent.distance;
if (len > 1e-6) {
    tangent /= len;
} else {
    tangent = Offset(1, 0);  // Fallback
}
```

### Eigenvalue Computation
```dart
// Prevent NaN from negative discriminant
double disc = trace * trace - 4 * det;
if (disc < 0) disc = 0;
```

### Empty/Degenerate Inputs
```dart
// PCA with < 2 points
if (points.length == 1) return BestFitLine(points[0], Offset(1, 0));

// Circle packing on short path
if (totalLength < radius) return [];

// Tangent at boundaries
delta = _computeOptimalTangentDelta(arcLength, totalLength);
```

---

## Testing Strategy

### Unit Tests (Hypothetical)
- **PCA**: Verify eigenvalue computation, projection correctness
- **Spline**: Verify all 5 control points are on curve
- **Parameterization**: Verify arc lengths are monotonically increasing
- **Packing**: Verify circles are exactly `2r` apart

### Integration Tests
- Verify full pipeline: candidates → PCA → spline → sampling → packing
- Verify dragging updates all downstream computations

### Visual Tests (Manual)
- Observe spline passes through all control points
- Observe circles align edge-to-edge
- Observe clipping boundary is perpendicular to path

---

## Future Optimization Opportunities

1. **Memoization**: Cache arc-length lookups for frequently queried values
2. **Lazy Recomputation**: Only recompute affected geometry (e.g., circle packing only if radius changed)
3. **GPU Acceleration**: Use custom shader for efficient clipping
4. **Adaptive Sampling**: Reduce spline point density in straight sections, increase near curves
5. **Path Simplification**: Reduce spline points using Douglas-Peucker algorithm

---

## Debugging Tools

### Enable Debug Overlays
```dart
appState.showDebug = true;
```

Shows:
- PCA axis (white dashed line through candidates)
- Projection guides (cyan dashed lines from candidates to projections)
- Centroid point
- Projected points

### Inspect State
```dart
print("Reduced: ${appState.reducedPoint}");
print("Total Arc Length: ${appState.sampledPath?.totalLength}");
print("Circle Count: ${appState.circles.length}");
print("Animation Progress: ${appState.animationProgress}");
```

### Canvas Rendering Issues
Use Chrome DevTools → Elements → Canvas inspector to debug rendering.

---

**Last Updated**: March 2025

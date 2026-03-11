# Path Extrapolation Technical Task (Architecture V2)

This project strictly implements a geometric path extrapolation tool featuring PCA-based point reduction, Catmull-Rom spline generation, mathematically precise circle packing, and strict geometric clipping.

## Core Features Implemented

### 1. Reduction Step (`lib/geometry/pca_reduction.dart`)
- Takes 3 arbitrary candidate points and derives a reference axis using **Principal Component Analysis (PCA)**.
- Projects all candidates onto the optimal fit-line.
- Deterministically selects the projected point at the maximum Euclidean distance from `P2` to serve as the start of the path (`P1`).

### 2. Smooth 5-Point Path (`lib/geometry/spline_builder.dart`)
- Implements a pure **Catmull-Rom cubic spline** interpolation.
- Ensures the path mathematically passes through precisely the 5 control points (P1-P5) in order.
- Utilizes "phantom points" at the boundary to maintain smooth derivatives entering P1 and exiting P5.

### 3. Circle Packing (`lib/geometry/circle_packer.dart` & `path_sampler.dart`)
- **Arc-Length Parameterization**: The Catmull-Rom spline is uniformly sampled and parameterized by cumulative arc distance. 
- Pack circles iteratively along the parameter domain, placing the first circle's center at $r$ (ensuring boundary starts exactly at `P1`).
- Spacing is identically $2r$ in the arc space to guarantee geometric edge-to-edge constraint along the curve.

### 4. Exact End Clipping (`lib/painters/path_painter.dart`)
- Uses a mathematically derived half-plane clipping mask perpendicular to the curve's tangent at any given boundary threshold.
- The final circle is cleanly truncated precisely at the path endpoint (or at the current animation frontier) without overshoot, gaps, or flicker.

### 5. Architectural Engineering Constraints
- **Separation of Concerns**: Pure mathematics and point states live in `lib/geometry/` and do not depend on the Flutter rendering pipeline.
- No hidden mutations within `CustomPainter` render callbacks.

## Edge Case Handling

The geometric implementation inherently solves tricky cases:
*   **Vertical / Horizontal Collinear Sets**: PCA algorithm checks for zero variance bounds and defaults to axis vectors precisely, preventing `NaN` exceptions and cleanly extrapolating completely straight or axis-aligned lines.
*   **Tight Curvature Overlap**: Because circle centers iterate strictly via arc length integration (parameter distance) rather than Euclidean chord projection, circles maintain proper distribution and spacing no matter how convoluted the path twists.
*   **Zero/Tiny Paths**: Safety bounds catch segments that are smaller than the circle diameter and safely halt the iterator.

## Setup & Running 🚀

1. Ensure the Flutter SDK is installed and on your system path.
2. Clone or drop this folder into an IDE.
3. Run `flutter pub get`
4. Run `flutter run -d chrome` (or Windows/macOS/iOS/Android).

Enjoy the interactive canvas, debug overlays, and animations!

# Path Extrapolation and Circle Packing

Interactive Flutter application for geometric path extrapolation with deterministic PCA reduction, Catmull-Rom spline generation, arc-length parameterization, edge-to-edge circle packing, and exact endpoint clipping.

## Overview

This project demonstrates a complete geometry pipeline:

1. Reduce three candidate points into one point using PCA projection logic.
2. Build a smooth 5-point Catmull-Rom spline.
3. Reparameterize the spline by arc length.
4. Place circles at diameter spacing along the path.
5. Clip the final circle exactly at the endpoint using a tangent-based half-plane.

All geometry is recomputed in real time when points are dragged.

## Features

- Interactive drag controls for candidate and path points
- Deterministic PCA-based reduction from 3 candidates to 1 reduced point
- Smooth Catmull-Rom spline through P1-P5
- Arc-length lookup for stable spacing on curved paths
- Circle packing with center spacing = `2 * radius`
- Endpoint clipping perpendicular to local tangent
- Debug overlays: PCA axis, projections, clipping line
- Optional progressive animation of packed circles

## Tech Stack

- Flutter
- Dart
- CustomPainter for rendering
- ChangeNotifier for app state orchestration

## Project Structure

```text
lib/
	main.dart                      # App shell, controls, legend
	geometry/
		models.dart                  # Shared geometry models
		pca_reduction.dart           # PCA and candidate reduction logic
		spline_builder.dart          # Catmull-Rom spline sampling
		path_sampler.dart            # Arc-length sampling and tangent lookup
		circle_packer.dart           # Circle placement in arc domain
	state/
		app_state.dart               # Central state + recompute trigger
	painters/
		path_painter.dart            # Read-only drawing of all layers
	widgets/
		path_canvas.dart             # Pointer gestures and hit testing
test/
	geometry_test.dart             # Geometry-focused tests
```

## Prerequisites

- Flutter SDK 3.x (project lock indicates Flutter >= 3.18 prerelease range)
- Dart SDK 3.x

Verify installation:

```bash
flutter doctor
flutter --version
```

## Setup

```bash
flutter pub get
```

## Run

### Option A: Standard Flutter command

```bash
flutter run -d chrome
```

### Option B: If Flutter is not on PATH (Windows example)

```powershell
& "C:\Users\dhita\flutter\bin\flutter.bat" run -d chrome
```

### Option C: Web server target

```bash
flutter run -d web-server --web-hostname localhost --web-port 8080
```

## How to Use

- Drag orange points (`C1-C3`) to change candidate inputs.
- Drag blue points (`P2-P5`) to reshape the path.
- Observe green point (`P1`) recomputed from PCA reduction.
- Adjust radius slider to change packing density.
- Toggle overlays and clipping visualization for debugging.

## Algorithm Notes

### 1. PCA Reduction

- Computes centroid and covariance of candidates.
- Finds principal direction from dominant eigenvalue/eigenvector.
- Projects each candidate onto that axis.
- Selects projection farthest from `P2` as reduced point `P1`.

### 2. Spline Generation

- Uses Catmull-Rom cubic segments.
- Adds phantom points at both ends for smooth entry/exit tangents.
- Densely samples the curve for stable arc-length approximation.

### 3. Arc-Length Parameterization

- Builds cumulative distance table from sampled polyline points.
- Uses binary search for `O(log n)` position lookup at arc `s`.
- Uses finite differences for tangent estimation.

### 4. Circle Packing

- First circle center starts at `s = r` so boundary begins at path start.
- Next centers are spaced by `2r` in arc space.
- Handles short/degenerate paths safely.

### 5. Endpoint Clipping

- Computes tangent at endpoint.
- Builds perpendicular clip line through endpoint.
- Renders only the valid half-plane portion of final circles.

## Quality and Constraints

- Geometry is pure Dart inside `lib/geometry`.
- Rendering is read-only inside `path_painter.dart`.
- No state mutations inside paint routines.
- Deterministic output for identical inputs.
- Defensive handling for degenerate or near-zero cases.

## Testing

Run tests:

```bash
flutter test
```

For manual validation scenarios, see:

- `TESTING.md`
- `IMPLEMENTATION.md`
- `COMPLETION_SUMMARY.md`
- `INDEX.md`

## Known Notes

- On web, Flutter may show deprecation warnings for service worker/bootstrap APIs in `web/index.html`; these are non-blocking for current execution.
- Windows desktop target is not configured in this repository by default.

## License

MIT

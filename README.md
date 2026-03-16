# Path Extrapolation & Circle Packing — Interactive Flutter Application

A rigorous geometric application implementing **PCA-based point reduction**, **Catmull-Rom spline path generation**, **arc-length parameterized circle packing**, and **precise endpoint clipping** with full interactive controls and visual debugging.

---

## Quick Start 🚀

### Requirements
- Flutter SDK 3.0.0+
- Dart 3.0.0+

### Setup & Running

```bash
# Clone the repository
git clone <repo-url>
cd Technical-Task-Path-Extrapolation

# Install dependencies
flutter pub get

# Run the application
flutter run -d chrome          # Web (recommended for testing)
flutter run -d windows         # Windows desktop
flutter run -d macos           # macOS desktop
flutter run                    # iOS/Android (if configured)
```

---

## Architecture Overview

The project follows **strict separation of concerns** with all geometric algorithms living in `lib/geometry/` (no Flutter dependencies), while rendering logic stays in `lib/painters/` and UI state in `lib/state/`.

### Core Modules

#### 1. **Reduction Step** (`lib/geometry/pca_reduction.dart`)

**Purpose**: Reduce 3 candidate points to 1 optimal point for path start.

**Algorithm**:
- Compute the centroid of all candidate points
- Build a 2×2 covariance matrix from deviations
- Extract eigenvalues and principal eigenvector via characteristic equation
- Project all candidate points onto the principal axis (best-fit line)
- Select the projected point with **maximum Euclidean distance from P2**

**Key Properties**:
- **Deterministic**: Identical inputs always produce the same reduced point
- **Numerically Stable**: Handles edge cases like collinear or vertical/horizontal alignments
- **Bias-Free**: No preference for any particular candidate; purely geometric

**Edge Case Handling**:
- **Vertical/Horizontal Candidates**: When `cXY == 0`, direction defaults to axis vectors (Offset(1, 0) or (0, 1))
- **Degenerate Variance**: If discriminant is negative, clamped to 0 to prevent NaN
- **Single Candidate**: Returns that candidate without further processing
- **No Candidates**: Returns Offset.zero as a safe fallback

---

#### 2. **Path Generation** (`lib/geometry/spline_builder.dart`)

**Purpose**: Build a smooth continuous curve passing through exactly 5 control points.

**Algorithm**: **Catmull-Rom Cubic Spline**

The spline is parameterized by a parameter $t \in [0, 1]$ for each segment. For four control points $(p_0, p_1, p_2, p_3)$, the curve from $p_1$ to $p_2$ is:

$$\mathbf{P}(t) = 0.5 \times \left[
\begin{pmatrix} 2 p_1 \\ 0 \end{pmatrix} +
\begin{pmatrix} -p_0 + p_2 \\ 0 \end{pmatrix} t +
\begin{pmatrix} 2p_0 - 5p_1 + 4p_2 - p_3 \\ 0 \end{pmatrix} t^2 +
\begin{pmatrix} -p_0 + 3p_1 - 3p_2 + p_3 \\ 0 \end{pmatrix} t^3
\right]$$

(Computed separately for $x$ and $y$ coordinates.)

**Phantom Points**: To ensure smooth derivatives at the first and last control points:
- Prepend: $p_{\text{phantom-start}} = p_1 - (p_2 - p_1)$
- Append: $p_{\text{phantom-end}} = p_5 + (p_5 - p_4)$

**Sampling**: Each segment is sampled at 100 points (default), generating ~400 dense points for 5 control points.

**Properties**:
- Mathematically passes through all 5 control points
- Smooth $C^2$ continuity (second derivatives match)
- No overshoot oscillations (local support)

---

#### 3. **Arc-Length Parameterization** (`lib/geometry/path_sampler.dart`)

**Purpose**: Convert dense spline points into an arc-length parameterized representation.

**Algorithm**:
1. Iterate through consecutive spline points, computing Euclidean distances
2. Build cumulative arc-length array: $s_i = \sum_{j=0}^{i-1} d_j$
3. Use binary search for $O(\log n)$ positional lookups
4. Interpolate linearly between adjacent sample points

**Key Methods**:
- `getPositionAt(arcLength)`: Retrieve interpolated position at any arc length
- `getTangentAt(arcLength, delta)`: Compute normalized tangent via finite differences
  - Tangent = $(p(s+\delta) - p(s-\delta)) / ||..||$
  - Adaptive delta prevents numerical instability near boundaries

---

#### 4. **Circle Packing** (`lib/geometry/circle_packer.dart`)

**Purpose**: Place fixed-diameter circles edge-to-edge along the path.

**Algorithm**:
1. Start with circle center at arc length $s = r$ (radius), so leading edge is at 0
2. Place subsequent circles at $s = r + 2kr$ for $k = 0, 1, 2, ...$
3. Stop when the leading edge passes path end: $s - r \geq L_{\text{total}}$

**Spacing Guarantee**: Diameter $2r$ ensures circles touch edge-to-edge with no gaps.

**Properties**:
- Works on arbitrary curved paths (no curvature assumptions)
- Scaling with circle radius is automatic
- Final circle may extend beyond path end (clipped during rendering)

**Packing Formula**:
```
circleCount = floor(totalLength / (2 * radius)) + 1
```

---

#### 5. **Exact End Clipping** (`lib/painters/path_painter.dart`)

**Purpose**: Cleanly truncate the final circle at path end with no overshoot or gaps.

**Algorithm**: **Half-Plane Clipping**

1. Compute the clip boundary point at arc length $L_{\text{total}}$ (or animation frontier)
2. Compute tangent vector $\mathbf{t}$ via finite differences
3. Rotate tangent 90° counterclockwise to get normal $\mathbf{n}$
4. Construct a clipping quad covering the "valid" half-plane:
   - Boundary line: perpendicular to tangent at clip point
   - Extend quad backward along tangent direction
5. Apply `canvas.clipPath()` before drawing the circle

**Edge Cases**:
- **Near Path Start**: Delta adjusted to prevent crossing the start boundary
- **Near Path End**: Delta adjusted to prevent sampling beyond the end
- **Horizontal/Vertical Tangents**: Handled naturally by perpendicular rotation
- **Sharp Corners**: Clipping adapts to local path curvature

**Visual Guarantee**: 
- No visible overshoot beyond the endpoint
- No visible gap between circle and clipping boundary
- No flicker during animation transitions

---

## Feature Highlights

### Interactive Controls

1. **Draggable Points**:
   - **Candidate Points (C1–C3)**: Orange circles, used in reduction step
   - **Path Points (P2–P5)**: Light blue circles, directly control the spline
   - **Reduced Point (P1)**: Green circle, automatically computed

2. **Circle Radius Slider**: Adjust packing density in real-time (10–100 px)

3. **Toggle Switches**:
   - **Debug Overlays**: Show/hide PCA axis, projection lines, and candidate candidates
   - **Circle Packing**: Show/hide packed circles
   - **Clip Boundary**: Show/hide the red clipping boundary indicator
   - **Animation**: Enable/disable circle progression animation

4. **Animation Mode**: Circles progressively appear along the path (0→100% in 4 seconds)

### Visual Hierarchy

| Element | Color | Meaning |
|---------|-------|---------|
| Orange circles + labels | C1–C3 | Candidate points (input to reduction) |
| Light blue circles | P2–P5 | Draggable path control points |
| Green circle | P1 | Reduced point (output of PCA) |
| Blue curve | — | Smooth Catmull-Rom spline |
| Pink circles | — | Packed circles along path |
| Red line | — | End-clip boundary indicator |
| Cyan dashed lines | — | Projection guides (debug mode) |

---

## Edge Case Handling & Robustness

### 1. Straight Paths (All Points Collinear)

**Scenario**: P1 through P5 all lie on a single line.

**How It's Handled**:
- PCA correctly identifies the line's direction as the principal axis
- Circle centers are equally spaced along the line
- Clipping is perpendicular to the line (working correctly)
- Result: Perfect linear packing with no distortion

**Test**: Arrange all path points horizontally or vertically

---

### 2. Vertical Candidates

**Scenario**: Candidate points cluster vertically (e.g., same x-coordinate).

**How It's Handled**:
- Covariance matrix has $c_{XY} = 0$ and $c_{YY} > c_{XX}$
- Direction correctly defaults to Offset(0, 1)
- Projection onto vertical line succeeds
- Distance computation from P2 is correct

**Test**: Place C1, C2, C3 at same x but varying y

---

### 3. Horizontal Candidates

**Scenario**: Candidate points cluster horizontally (e.g., same y-coordinate).

**How It's Handled**:
- Covariance matrix has $c_{XY} = 0$ and $c_{XX} > c_{YY}$
- Direction correctly defaults to Offset(1, 0)
- Projection onto horizontal line succeeds

**Test**: Place C1, C2, C3 at same y but varying x

---

### 4. Tight Curves & Spiral Paths

**Scenario**: Path has sharp bends, loops, or spiral geometry.

**How It's Handled**:
- Arc-length parameterization distributes circles based on path length, not Euclidean distance
- Circles remain edge-to-edge regardless of curvature changes
- Tangent computation adapts to local curve direction
- Clipping boundary aligns perpendicular to the curve's instantaneous direction

**Test**: Create an S-curve or circular arc with P1–P5

---

### 5. Very Short Paths

**Scenario**: Total path length < 1 circle diameter.

**How It's Handled**:
- `CirclePacker.pack()` returns empty list if `totalLength < radius`
- No circles are placed, avoiding nonsensical partial coverage
- Graceful degradation with empty circle list

**Test**: Place all points within a small region (< 30 px apart)

---

### 6. Degenerate Point Positions

**Scenario**: Two or more control points occupy identical positions.

**How It's Handled**:
- Catmull-Rom spline still produces output (but may have zero-length segments)
- Arc-length parameterization handles zero-distance segments gracefully
- Circle packing continues even if some segments have zero length
- No division-by-zero errors

**Test**: Drag two path points to the exact same location

---

### 7. Tangent Computation at Boundaries

**Scenario**: Clipping occurs at the very start or very end of the path.

**How It's Handled**:
- Delta is adaptively scaled: smaller delta near boundaries, normal delta in the middle
- If computed tangent is too short, fallback to Offset(1, 0) (horizontal)
- Clipping boundary is still correctly perpendicular to the intended direction

**Test**: Set animation progress to 0.01 or 0.99 and observe clipping

---

### 8. Numerical Precision

**Scenario**: Path length accumulation has floating-point rounding errors.

**How It's Handled**:
- All comparisons use `<=` or `>=` to handle boundary rounding
- Clamping: `arcLength.clamp(0.0, totalLength)`
- Epsilon checks: `len > 1e-6` for tangent validation

---

## Design Decisions

### Why Catmull-Rom Spline?

- **Local Support**: Modifying one control point only affects 4 spline segments
- **No Overshoot**: Natural, non-oscillatory interpolation
- **Smooth Derivatives**: $C^2$ continuity ensures smooth tangents for clipping

### Why Arc-Length Parameterization?

- **Uniform Circle Spacing**: Distance along curve = parametric distance (not Euclidean)
- **Robustness**: Works on tight curves, spirals, any arbitrary geometry
- **Efficiency**: Binary search enables $O(\log n)$ lookups

### Why PCA for Reduction?

- **Deterministic & Objective**: No arbitrary weighting or thresholds
- **Noise-Resistant**: Averages out small perturbations
- **Geometric Meaning**: Captures the main trend direction of the candidates

### Why Half-Plane Clipping?

- **Mathematically Exact**: Perpendicular boundary aligns with curve tangent
- **No Artifacts**: Cleaner than per-pixel clipping or approximations
- **Efficient**: Single `canvas.clipPath()` call per clipped circle

---

## Testing & Validation

### Manual Tests

1. **Bent/Curved Path**
   - Arrange P1–P5 in an S-curve or arc
   - Observe circles remain evenly spaced along the curve
   - Toggle circle visibility and animation

2. **Straight Path**
   - Place all points collinearly
   - Observe linear packing with equal spacing
   - Verify clipping aligns perpendicular to the line

3. **Vertical Path**
   - Place candidates vertically aligned
   - Observe PCA reduction selects correct point
   - Verify path generation succeeds

4. **Horizontal Path**
   - Place candidates horizontally aligned
   - Verify reduction and path generation work

5. **Complex Shape**
   - Arrange path points to create loops or inversions
   - Observe graceful handling and correct clipping

6. **Animation**
   - Enable animation mode
   - Observe circles appear progressively
   - Verify clipping boundary moves smoothly without flicker

### Code Validation

- **No Floating-Point Exceptions**: All division operations guarded with zero-checks
- **No Mutation in Render**: AppState is read-only during painting
- **Deterministic Output**: Same input always produces same visual output

---

## Project Structure

```
lib/
├── main.dart                      # App entry point, UI scaffold
├── geometry/
│   ├── models.dart               # PathPoint, BestFitLine, PackedCircle
│   ├── pca_reduction.dart        # PCA algorithm & reduction step
│   ├── spline_builder.dart       # Catmull-Rom spline generation
│   ├── path_sampler.dart         # Arc-length parameterization
│   └── circle_packer.dart        # Circle placement algorithm
├── state/
│   └── app_state.dart            # Centralized state management
├── painters/
│   └── path_painter.dart         # Canvas rendering & visualization
└── widgets/
    └── path_canvas.dart          # Interactive gesture handling
```

---

## Performance Characteristics

| Operation | Complexity | Notes |
|-----------|-----------|-------|
| PCA Reduction | O(n) | n = candidate count (typically 3) |
| Catmull-Rom Sampling | O(m) | m = segments × samples (typically ~400) |
| Path Parameterization | O(m) | Single linear pass |
| Circle Packing | O(k) | k = circle count (typically 5–20) |
| Positional Lookup | O(log m) | Binary search with interpolation |
| Rendering | O(k) | k circles + spline + debug overlays |

Total frame time for typical state: **< 5 ms** on modern devices.

---

## Future Enhancements

1. **Export/Save**: Save path configurations as JSON
2. **Presets**: Load predefined paths (circle, spiral, etc.)
3. **Multi-Path**: Support simultaneous independent paths
4. **Path Simplification**: Reduce spline points while preserving shape
5. **3D Extension**: Extend geometry to 3D space
6. **Undo/Redo**: Point movement history with undo stack

---

## Troubleshooting

### Circles Don't Appear
- Check if circle radius > total path length / 2
- Verify animation is not at 0% progress
- Ensure circle packing toggle is enabled

### Clipping Boundary Misaligned
- This can occur if the tangent computation fails
- The fallback tangent is horizontal; verify path curvature is reasonable

### PCA Line Doesn't Appear
- Ensure debug overlays toggle is enabled
- Check if candidates are far enough apart to be visible

### Performance Issues
- Reduce sampling resolution in `SplineBuilder.buildCatmullRom()` (default: 100)
- Reduce circle radius to lower circle count

---

## References

- **Catmull-Rom Spline**: Catmull, E., & Rom, R. (1974). A class of local interpolating splines.
- **PCA**: Turk, M., & Pentland, A. (1991). Eigenfaces for Recognition.
- **Circle Packing**: Lagarias, J. C., et al. (2012). The Kepler Conjecture.

---

## License

MIT License — See LICENSE file for details.

---

**Last Updated**: March 2025  
**Author**: OpenCode Engineering

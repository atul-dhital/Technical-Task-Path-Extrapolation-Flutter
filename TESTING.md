# Testing Guide & Edge Case Demonstrations

This document provides step-by-step instructions for testing all core features and edge cases of the Path Extrapolation application.

---

## Test 1: Straight Horizontal Path

**Objective**: Verify circle packing works on a perfectly horizontal path.

**Setup**:
1. Launch the application
2. Clear any debug overlays or animations for clarity
3. Arrange path points in a horizontal line:
   - P1 (reduced): Will be computed automatically
   - P2: Drag to (300, 300)
   - P3: Drag to (450, 300)
   - P4: Drag to (600, 300)
   - P5: Drag to (750, 300)

**Expected Results**:
- The spline passes through all 5 points horizontally
- Circles are placed edge-to-edge horizontally
- Clipping boundary (red line) is perfectly vertical
- Circle spacing is uniform: diameter apart

**Validation Checks**:
- ✅ No visual gap between adjacent circles
- ✅ Path remains at y=300 throughout
- ✅ Clipping line is perpendicular to the path

---

## Test 2: Straight Vertical Path

**Objective**: Verify PCA handles vertical candidates and path remains vertical.

**Setup**:
1. Reset the canvas
2. Position candidates vertically (e.g., same x-coordinate):
   - C1: (100, 150)
   - C2: (100, 250)
   - C3: (100, 350)
3. Arrange path points vertically:
   - P2: (300, 100)
   - P3: (300, 250)
   - P4: (300, 400)
   - P5: (300, 550)

**Expected Results**:
- PCA line appears as a vertical dashed line in debug mode
- Reduced point P1 is correctly placed
- Circles stack vertically, edge-to-edge
- Clipping boundary is horizontal

**Validation Checks**:
- ✅ PCA doesn't crash (no NaN in computations)
- ✅ Reduced point is among the candidates' x-range
- ✅ All circles centered at x=300
- ✅ Animation still works smoothly

---

## Test 3: Bent/S-Curve Path

**Objective**: Verify circle packing adapts to curved paths.

**Setup**:
1. Create an S-shaped curve:
   - P2: (200, 150)
   - P3: (400, 250)
   - P4: (400, 400)
   - P5: (600, 500)
2. Adjust circle radius to ~20px for visibility

**Expected Results**:
- Circles follow the curve smoothly
- Despite the curve, circles remain edge-to-edge
- Final circle clips cleanly at P5
- Clipping boundary rotates to match curve tangent

**Validation Checks**:
- ✅ Circles don't overlap
- ✅ No visible gap between circles
- ✅ Tangent vectors align with curve direction
- ✅ Clipping boundary moves smoothly during animation

---

## Test 4: Spiral Path

**Objective**: Test circle packing on a spiral (most demanding case).

**Setup**:
1. Manually create a spiral by arranging points in a spiral pattern:
   - P1: (400, 300)
   - P2: (450, 300)
   - P3: (500, 350)
   - P4: (450, 400)
   - P5: (350, 350)
2. Set circle radius to ~18px

**Expected Results**:
- Circles follow the spiral path
- Even at tight turns, circles remain edge-to-edge
- No overshoot at the spiral center
- Clipping adapts to spiral tangent

**Validation Checks**:
- ✅ No circles overlapping or intersecting
- ✅ Arc-length parameterization keeps spacing consistent
- ✅ Path tangent is correctly computed at curves
- ✅ Clipping boundary aligns with spiral direction

---

## Test 5: Degenerate — Two Points Identical

**Objective**: Verify robustness when two control points overlap.

**Setup**:
1. Drag two path points to the same location (e.g., P3 and P4 to (500, 300))
2. Observe the canvas rendering

**Expected Results**:
- Spline still generates output (zero-length segment)
- Circle packing continues without errors
- Animation plays without glitches
- No division-by-zero errors in logs

**Validation Checks**:
- ✅ No crashes or exceptions
- ✅ Tangent computation has fallback behavior
- ✅ Canvas renders without artifacts

---

## Test 6: Very Short Path (< 1 Diameter)

**Objective**: Verify behavior when path is too short for circles.

**Setup**:
1. Cluster all path points very close together (within 40px of each other)
2. Observe circle packing behavior

**Expected Results**:
- No circles appear (or only a partial one)
- Path is still rendered clearly
- No visual glitches

**Validation Checks**:
- ✅ `CirclePacker.pack()` returns empty list
- ✅ Path line remains visible
- ✅ No exceptions thrown

---

## Test 7: Candidate Point Reduction (PCA)

**Objective**: Verify the reduction step selects the correct candidate projection.

**Setup**:
1. Enable "Debug Overlays" toggle
2. Position candidates in a line but NOT aligned with P2:
   - C1: (50, 100)
   - C2: (80, 150)
   - C3: (100, 200)
3. Position P2 far to the right: P2 = (700, 300)

**Expected Results**:
- PCA axis (white dashed line) shows the best-fit line through candidates
- Cyan projection lines connect each candidate to its projection
- Green point P1 (reduced point) is the projection **farthest from P2**
- Deterministically, the same input produces the same P1

**Validation Checks**:
- ✅ PCA line passes through centroid of candidates
- ✅ Projections are perpendicular to PCA line
- ✅ P1 is the rightmost (or farthest from P2) projection
- ✅ Toggling debug overlays shows/hides correctly

**To Verify Determinism**:
1. Note the position of P1
2. Drag one candidate slightly and return it to original position
3. P1 should return to the exact same position (no random variation)

---

## Test 8: Circle Radius Adjustment

**Objective**: Verify circle packing scales correctly with radius changes.

**Setup**:
1. Create a standard bent path
2. Drag the "Circle Radius" slider from 10px to 100px

**Expected Results**:
- Fewer circles appear as radius increases
- Circles remain edge-to-edge at all radii
- Circle count follows formula: `≈ totalLength / (2 * radius)`
- Clipping boundary scales and positions correctly

**Validation Checks**:
- ✅ Circle diameter increases with slider
- ✅ Spacing remains diameter apart (no gaps)
- ✅ First circle always starts at path beginning
- ✅ Animation still clips correctly

---

## Test 9: Animation & Clipping Dynamics

**Objective**: Verify animation progress correctly triggers clipping.

**Setup**:
1. Enable "Animation" toggle
2. Watch circles progressively appear over 4 seconds
3. At ~50% progress, toggle "Clip Boundary" to see the red line moving
4. At ~100% progress, observe final clipping at path end

**Expected Results**:
- Circles appear smoothly from left to right
- Clipping boundary (red line) moves along the path
- No flicker or jumping as circles appear
- Final circle smoothly clips to exact path end

**Validation Checks**:
- ✅ Animation progresses linearly (0→1 over 4 seconds)
- ✅ Each circle appears only after its center arc-length is reached
- ✅ Clipping line stays perpendicular throughout
- ✅ No visual artifacts at animation boundaries
- ✅ Toggling animation pauses/resumes correctly

---

## Test 10: Interactive Point Dragging

**Objective**: Verify real-time geometry updates as points are dragged.

**Setup**:
1. Disable animation for stability
2. Drag each candidate and path point individually
3. Observe real-time updates

**Expected Results**:
- Reduced point P1 updates instantly as candidates move
- Spline path updates as P2–P5 move
- Circles reposition along new path
- Clipping boundary adjusts to new path curvature

**Validation Checks**:
- ✅ No lag in response to dragging
- ✅ Geometry is recomputed at every frame
- ✅ No stale state carries over
- ✅ Spline passes through all 5 points (visually verify)

---

## Test 11: Toggle Controls

**Objective**: Verify all UI toggles work independently.

**Setup**:
1. Create a normal bent path with circles visible
2. Systematically toggle each control:
   - **Debug Overlays**: Should show/hide PCA line and projections
   - **Circle Packing**: Should show/hide pink circles
   - **Clip Boundary**: Should show/hide red clipping line
   - **Animation**: Should pause/resume circle progression

**Expected Results**:
- Each toggle independently controls its layer
- No side effects when toggling one control
- State is preserved when toggling back on

**Validation Checks**:
- ✅ All toggles are clickable
- ✅ Visual changes occur immediately
- ✅ No crashes when toggling during animation

---

## Test 12: Edge Case — Collinear Candidate Points

**Objective**: Verify PCA handles perfectly collinear candidates.

**Setup**:
1. Position all 3 candidates on a single line:
   - C1: (50, 100)
   - C2: (75, 150)
   - C3: (100, 200)
2. Position P2 off the line: (500, 300)

**Expected Results**:
- PCA correctly identifies the line direction
- All three projections fall on the same axis
- P1 is the projection farthest from P2
- No numerical instability or NaN values

**Validation Checks**:
- ✅ PCA line coincides with candidate line
- ✅ Covariance eigenvalue computation succeeds
- ✅ Reduction is deterministic

---

## Test 13: Boundary Behavior — Path Very Close to Canvas Edge

**Objective**: Verify clipping and rendering work correctly at canvas boundaries.

**Setup**:
1. Position path points very close to the canvas edge:
   - P2: (50, 50)
   - P3: (100, 100)
   - P4: (150, 50)
   - P5: (180, 100)
2. Set circle radius moderately (e.g., 20px)

**Expected Results**:
- Circles near edges are correctly clipped by canvas bounds
- Clipping boundary is correct even near edges
- No visual artifacts or overflow

**Validation Checks**:
- ✅ Circles don't mysteriously disappear
- ✅ Tangent computation works near canvas edges
- ✅ Clipping quad is properly constructed

---

## Test 14: Tangent Stability Near Path Endpoints

**Objective**: Verify tangent computation is stable at path start and end.

**Setup**:
1. Enable "Clip Boundary" toggle
2. Set animation progress to very near 0% (start):
   - If possible, pause animation and drag slider to 0.01
3. Observe clipping boundary

**Expected Results**:
- Clipping boundary appears correctly near the start
- Red line is perpendicular to path direction
- No jerky movements or singularities

**Then**:
4. Drag animation slider to 0.99 (near end)

**Expected Results**:
- Clipping boundary appears near the final point
- Tangent is correctly computed even at path end
- Final clipping is clean and exact

**Validation Checks**:
- ✅ Delta is adaptively adjusted at boundaries
- ✅ Fallback tangent (1, 0) is used only if necessary
- ✅ No flicker or numerical issues

---

## Test 15: Performance Under Extreme Values

**Objective**: Verify app remains responsive with extreme parameters.

**Setup**:
1. Set circle radius to maximum (100px)
2. Create a very long path spanning most of canvas
3. Enable animation
4. Drag points rapidly while animation runs

**Expected Results**:
- No frame drops or stuttering
- Calculations remain responsive
- Memory usage remains reasonable

**Validation Checks**:
- ✅ FPS remains smooth (> 30 FPS typical)
- ✅ No memory leaks during extended interaction
- ✅ Drag responsiveness is immediate

---

## Stress Test Checklist

- [ ] Straight path — circles edge-to-edge ✅
- [ ] Vertical path — PCA handles vertical candidates ✅
- [ ] Curved path — circles follow arc-length, not chord ✅
- [ ] Spiral path — tight curves work ✅
- [ ] Overlapping points — no crashes ✅
- [ ] Short path — graceful degradation ✅
- [ ] Candidate reduction — deterministic & correct ✅
- [ ] Circle radius — scales correctly ✅
- [ ] Animation — smooth clipping dynamics ✅
- [ ] Dragging — real-time updates ✅
- [ ] Toggles — independent control ✅
- [ ] Collinear candidates — PCA stable ✅
- [ ] Canvas boundaries — no artifacts ✅
- [ ] Endpoint tangents — stable & correct ✅
- [ ] Performance — responsive & smooth ✅

---

## Automated Validation (Optional)

For future test automation, consider:

```dart
void testReductionDeterminism() {
  List<Offset> candidates = [Offset(50, 100), Offset(75, 150), Offset(100, 200)];
  Offset p2 = Offset(500, 300);
  
  Offset result1 = ReductionStep.reduce(candidates, p2);
  Offset result2 = ReductionStep.reduce(candidates, p2);
  
  expect(result1.dx, result2.dx); // Exact match
  expect(result1.dy, result2.dy);
}

void testCircleSpacingAccuracy() {
  // Verify circles are exactly 2r apart along the path
  double radius = 20;
  List<PackedCircle> circles = CirclePacker.pack(sampledPath, radius);
  
  for (int i = 0; i < circles.length - 1; i++) {
    double spacing = circles[i + 1].arcLengthStart - circles[i].arcLengthEnd;
    expect(spacing, 0.0, epsilon: 0.1); // Should be 0 (touching)
  }
}
```

---

## Notes for Manual Testing

- Use Chrome DevTools to inspect canvas rendering if issues arise
- Enable "Debug Overlays" to understand geometric computations
- Test on both web (Chrome) and desktop (Windows/macOS) for compatibility
- Observe performance in DevTools Performance tab during animation

---

**Last Updated**: March 2025

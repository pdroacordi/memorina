class_name MemoryFieldMath extends RefCounted

## The shape of the memory field, in one place. See
## docs/design/03_mundo_e_ambiente.md sections 2 and 3: a point's memory runs
## from 0 (grey, and time stopped) to 1 (full colour, time running).
##
## IMPORTANT: source_distance() and disc_influence() are mirrored by functions
## of the same names in greyhush.gdshader, because GDScript and GLSL cannot
## share code. Change one and you must change the other. Every tunable here is
## pushed to the shader as a uniform - never re-type a number into the shader.
##
## The shader additionally roughens each boundary by angular sector, and dithers
## between quantisation bands. Both are rendering concerns; the CPU deliberately
## keeps a clean edge and a continuous value, because sampling is for time-stop
## and nothing in gameplay may depend on where a ragged sector fell.

enum Shape {
	CIRCLE,
	RECT,
	## A vertical stadium: a rectangle with semicircular caps. The closest
	## simple shape to a standing figure, and the reason it is here.
	CAPSULE,
}

## How far the shader's ragged edge may push a sector, as a fraction of feather.
const EDGE_JAGGEDNESS := 0.12
## How many angular sectors that raggedness is quantised into.
const EDGE_SECTORS := 12.0
## Feather used when a source leaves it at zero, as a fraction of its extent.
## Keeps an un-tuned zone from having a perfectly hard edge.
const DEFAULT_FEATHER_RATIO := 0.15

## Distance from a source's solid core, in pixels. Zero or negative inside the
## core, growing outward. `extent` is the core half-size: for a circle both
## components hold the radius, for a rect they hold half-width and half-height.
static func source_distance(offset: Vector2, extent: Vector2, shape: Shape) -> float:
	match shape:
		Shape.RECT:
			var d := Vector2(absf(offset.x) - extent.x, absf(offset.y) - extent.y)
			return Vector2(maxf(d.x, 0.0), maxf(d.y, 0.0)).length() + minf(maxf(d.x, d.y), 0.0)
		Shape.CAPSULE:
			# Collapse the straight section, then it is a circle problem.
			# extent.x is the cap radius, extent.y the half-height of the
			# straight part.
			var p := Vector2(offset.x, offset.y - clampf(offset.y, -extent.y, extent.y))
			return p.length() - extent.x
		_:
			return offset.length() - extent.x

## One source's contribution at `dist` from its core. Full `strength` inside the
## core, then a linear ramp to zero across `feather` pixels.
##
## `strength` may be negative: an authored patch, or a death mark, pushes the
## local memory DOWN.
static func disc_influence(dist: float, feather: float, strength: float) -> float:
	if dist <= 0.0:
		return strength
	if feather <= 0.0 or dist >= feather:
		return 0.0
	return strength * (1.0 - dist / feather)

## Where a point sits across the falloff band: 0 at the edge of the solid core,
## 1 at the outer limit. This is the value a falloff Curve is sampled at, so
## the curve's X axis always means the same thing regardless of zone size.
static func falloff_position(dist: float, feather: float) -> float:
	if feather <= 0.0:
		return 1.0 if dist > 0.0 else 0.0
	return clampf(dist / feather, 0.0, 1.0)

## The region's baseline plus every source, clamped back into 0..1.
static func combine(baseline: float, influences: PackedFloat32Array) -> float:
	var total := baseline
	for influence: float in influences:
		total += influence
	return clampf(total, 0.0, 1.0)

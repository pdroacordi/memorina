class_name MemoryFieldMath extends RefCounted

## Memory field rules; see docs/design/03_mundo_e_ambiente.md sections 2 and 3.
## Must match gh_shape_distance() and gh_influence() in greyhush_common.gdshaderinc.
## CPU sampling stays smooth; shader edge roughness and dithering are rendering only.

enum Shape {
	CIRCLE,
	RECT,
	## A vertical capsule with semicircular caps.
	CAPSULE,
}

## How far the shader's ragged edge may push a sector, as a fraction of feather.
const EDGE_JAGGEDNESS := 0.12
## How many angular sectors that raggedness is quantised into.
const EDGE_SECTORS := 12.0
## Default feather as a fraction of source extent.
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

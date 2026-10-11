class_name HelixFaces extends RefCounted

## The turning tower as flat-shaded polygons in draw order, pure (architecture/walkable-helix-stair, Revision).
## Screen px from the axis base. The wall and what hangs on it come first, then the floor's top, then every step face
## sorted far to near; nothing nearer than Ivo's plane is kept.

## Radians between the points of a curved edge.
const ARC_STEP := 0.12
## Px a highlight line sits below its block's top edge.
const LIGHT_OFFSET := 2.0
## Px between the joints of the gallery's planks.
const PLANK := 24.0


## One polygon: its screen points, fill, outline (alpha 0: none), an optional accent line, and its view depth.
class Face:
	var points := PackedVector2Array()
	var fill := Color.BLACK
	var line := Color(0, 0, 0, 0)
	var accent := PackedVector2Array()
	var accent_color := Color(0, 0, 0, 0)
	## View z of the centroid, and the largest view z of any point (Ivo's plane is walk_radius).
	var depth := 0.0
	var nearest := 0.0
	## The step it belongs to; -1 for the wall and its dressing, -2 for what lies in Ivo's plane (the front band, the gallery).
	var step := -1


## The faces of the tower turned by `phi`, seen from eye height `eye`, that can show between screen heights `top` and
## `bottom` (px from the axis base, down positive). The wall rises to `ceiling` px above the base.
static func build(shape: HelixStairShape, look: HelixLook, hand: int, phi: float, eye: float, top: float, bottom: float, ceiling: float) -> Array[Face]:
	var span := _world_span(shape, eye, top, bottom)
	var back: Array[Face] = []
	_wall(back, shape, look, hand, phi, eye, span, ceiling)
	_posts(back, shape, look, hand, phi, eye, span, ceiling)
	_beams(back, shape, look, hand, phi, eye, span)
	_slits(back, shape, look, hand, phi, eye, span)
	_floor(back, shape, look, hand, eye, span)
	var steps: Array[Face] = []
	for index: int in shape.step_count():
		_step(steps, shape, look, hand, phi, eye, span, index)
	_front_band(steps, shape, look, hand, phi, span)
	steps.sort_custom(func(a: Face, b: Face) -> bool: return a.depth < b.depth)
	back.append_array(steps)
	_gallery(back, shape, look, span)
	return back

## The stair's outer stringer cut by Ivo's plane, one band per turn crossing it: its top runs through the risers' feet,
## under every tread section, so it never rises over his feet.
static func _front_band(out: Array[Face], shape: HelixStairShape, look: HelixLook, hand: int, phi: float, span: Vector2) -> void:
	var w := shape.walk_radius
	var limit := acos(w / shape.wall_radius)
	var head := HelixMath.head_u(shape)
	var rise := shape.pitch / TAU
	var half_riser := shape.riser() * 0.5
	for lap: int in range(floori((-limit - phi) / TAU) - 1, ceili((head + limit - phi) / TAU) + 2):
		var lo := maxf(-limit, -phi - lap * TAU)
		var hi := minf(limit, head - phi - lap * TAU)
		if hi <= lo:
			continue
		var highest := -rise * (phi + hi + lap * TAU) + half_riser
		var lowest := -rise * (phi + lo + lap * TAU) + half_riser + look.band_depth
		if lowest < span.x or highest > span.y:
			continue
		var count := maxi(2, ceili((hi - lo) / ARC_STEP))
		var top := PackedVector2Array()
		var bottom := PackedVector2Array()
		for n: int in count + 1:
			var beta := lerpf(lo, hi, float(n) / count)
			var x := hand * w * tan(beta)
			var y := -rise * (phi + beta + lap * TAU) + half_riser
			top.append(Vector2(x, y))
			bottom.append(Vector2(x, y + look.band_depth))
		var face := Face.new()
		face.points = top.duplicate()
		for n: int in range(bottom.size() - 1, -1, -1):
			face.points.append(bottom[n])
		face.fill = look.stringer[1]
		face.line = look.stringer[2]
		face.accent = top
		face.accent_color = look.nosing
		face.depth = w - 0.001
		face.nearest = w
		face.step = -2
		out.append(face)

## The gallery's edge across the shell in Ivo's plane, under the plank tiles' top.
static func _gallery(out: Array[Face], shape: HelixStairShape, look: HelixLook, span: Vector2) -> void:
	var top := -shape.head_rise()
	if top + look.gallery_depth < span.x or top > span.y:
		return
	var half := HelixProjection.silhouette(shape)
	var face := Face.new()
	face.points = PackedVector2Array([Vector2(-half, top), Vector2(half, top), Vector2(half, top + look.gallery_depth), Vector2(-half, top + look.gallery_depth)])
	face.fill = look.gallery[0]
	face.line = look.gallery_line
	face.accent = PackedVector2Array([Vector2(-half, top + look.gallery_depth * 0.5), Vector2(half, top + look.gallery_depth * 0.5)])
	face.accent_color = look.gallery[1]
	face.depth = shape.walk_radius
	face.nearest = shape.walk_radius
	face.step = -2
	out.append(face)
	var x := -half + PLANK
	while x < half:
		var joint := Face.new()
		joint.points = PackedVector2Array([Vector2(x, top), Vector2(x + 2.0, top), Vector2(x + 2.0, top + look.gallery_depth), Vector2(x, top + look.gallery_depth)])
		joint.fill = look.gallery_line
		joint.depth = shape.walk_radius
		joint.nearest = shape.walk_radius
		joint.step = -2
		out.append(joint)
		x += PLANK

## The faces of step `index` alone, for the screw-symmetry test.
static func step_faces(shape: HelixStairShape, look: HelixLook, hand: int, phi: float, eye: float, index: int) -> Array[Face]:
	var faces: Array[Face] = []
	_step(faces, shape, look, hand, phi, eye, Vector2(-INF, INF), index)
	return faces

## The visible band of the wall: tower angles whose inner surface faces the eye.
static func visible_band(shape: HelixStairShape, phi: float) -> Vector2:
	var edge := acos(shape.wall_radius / shape.eye_distance)
	return Vector2(phi + edge, phi + TAU - edge)

## World heights (px, down positive) whose points can project between `top` and `bottom` for any depth kept.
static func _world_span(shape: HelixStairShape, eye: float, top: float, bottom: float) -> Vector2:
	var k := HelixProjection.scale_at(shape, -shape.wall_radius)
	return Vector2(eye + (top - eye) / k if top < eye else top, eye + (bottom - eye) / k if bottom > eye else bottom)

static func _wall(out: Array[Face], shape: HelixStairShape, look: HelixLook, hand: int, phi: float, eye: float, span: Vector2, ceiling: float) -> void:
	var band := visible_band(shape, phi)
	var r := shape.wall_radius
	var courses := ceili(ceiling / look.course_height)
	for course: int in courses:
		var y1 := -course * look.course_height
		var y0 := maxf(y1 - look.course_height, -ceiling)
		if y1 < span.x or y0 > span.y:
			continue
		var bounds := _course_bounds(look, r, course)
		var period := TAU
		for j: int in bounds.size() - 1:
			var lap := floorf((band.x - bounds[j + 1]) / period) + 1.0
			while bounds[j] + lap * period < band.y:
				var a := maxf(bounds[j] + lap * period, band.x)
				var b := minf(bounds[j + 1] + lap * period, band.y)
				if b > a:
					var face := _wall_patch(shape, hand, phi, eye, r, a, b, y0, y1)
					face.fill = look.stone[absi(hash(Vector3i(course, j, 7))) % look.stone.size()]
					face.line = look.mortar
					face.accent = _shifted(_arc(shape, hand, phi, eye, r, a, b, y0), LIGHT_OFFSET)
					face.accent_color = look.stone_light
					out.append(face)
				lap += 1.0

## Tower angles of one course's block joints, one full lap, staggered per course.
static func _course_bounds(look: HelixLook, r: float, course: int) -> PackedFloat32Array:
	var widths := PackedFloat32Array()
	var total := 0.0
	var circumference := TAU * r
	while total < circumference:
		var width := lerpf(look.block_min, look.block_max, _unit(course, widths.size()))
		widths.append(width)
		total += width
	var start := _unit(course, -1) * look.block_max / r
	var bounds := PackedFloat32Array([start])
	for width: float in widths:
		bounds.append(bounds[-1] + width * circumference / total / r)
	return bounds

static func _posts(out: Array[Face], shape: HelixStairShape, look: HelixLook, hand: int, phi: float, eye: float, span: Vector2, ceiling: float) -> void:
	var band := visible_band(shape, phi)
	var r := shape.wall_radius
	var half := look.post_width * 0.5 / r
	var y0 := maxf(-ceiling, span.x)
	var y1 := minf(0.0, span.y)
	if y1 <= y0:
		return
	for angle: float in look.posts:
		var centre := _into_band(angle, band)
		var a := maxf(centre - half, band.x)
		var b := minf(centre + half, band.y)
		if b <= a:
			continue
		var face := _wall_patch(shape, hand, phi, eye, r, a, b, y0, y1)
		face.fill = look.timber[0]
		face.line = look.timber_line
		out.append(face)

static func _beams(out: Array[Face], shape: HelixStairShape, look: HelixLook, hand: int, phi: float, eye: float, span: Vector2) -> void:
	var band := visible_band(shape, phi)
	for height: float in look.beams:
		var y1 := -height
		var y0 := y1 - look.beam_height
		if y1 < span.x or y0 > span.y:
			continue
		var face := _wall_patch(shape, hand, phi, eye, shape.wall_radius, band.x, band.y, y0, y1)
		face.fill = look.timber[1]
		face.line = look.timber_line
		out.append(face)

static func _slits(out: Array[Face], shape: HelixStairShape, look: HelixLook, hand: int, phi: float, eye: float, span: Vector2) -> void:
	var band := visible_band(shape, phi)
	var r := shape.wall_radius
	var half := look.slit_size.x * 0.5 / r
	for slit: Vector2 in look.slits:
		var y1 := -slit.y
		var y0 := y1 - look.slit_size.y
		if y1 < span.x or y0 > span.y:
			continue
		var centre := _into_band(slit.x, band)
		if centre - half < band.x or centre + half > band.y:
			continue
		var face := _wall_patch(shape, hand, phi, eye, r, centre - half, centre + half, y0, y1)
		face.fill = look.glass[0]
		face.line = look.slit_frame
		face.accent = _arc(shape, hand, phi, eye, r, centre - half, centre + half, y0 + look.slit_size.y * 0.6)
		face.accent_color = look.glass[1]
		out.append(face)

## The floor's top behind Ivo's plane: the disc's back arc closed by the cut.
static func _floor(out: Array[Face], shape: HelixStairShape, look: HelixLook, hand: int, eye: float, span: Vector2) -> void:
	if eye >= 0.0 or 0.0 < span.x or 0.0 > span.y:
		return
	var r := shape.wall_radius
	var edge := acos(shape.walk_radius / r)
	var points := PackedVector2Array()
	var count := ceili((TAU - 2.0 * edge) / ARC_STEP)
	for n: int in count + 1:
		var beta := edge + (TAU - 2.0 * edge) * n / count
		points.append(HelixProjection.project_polar(shape, hand, beta, r, 0.0, 0.0, eye))
	var face := Face.new()
	face.points = points
	face.fill = look.floor_tones[0]
	face.line = look.floor_line
	face.depth = -r
	out.append(face)

static func _step(out: Array[Face], shape: HelixStairShape, look: HelixLook, hand: int, phi: float, eye: float, span: Vector2, index: int) -> void:
	var delta := TAU / shape.steps_per_turn
	var a := index * delta
	var b := a + delta
	var top := -HelixMath.tread_rise(shape, index)
	var bottom := top + look.step_depth
	if bottom < span.x or top > span.y:
		return
	var inner := shape.inner_radius
	var outer := shape.wall_radius
	var eye_point := HelixProjection.eye_point(shape, eye)
	var middle := (a + b) * 0.5
	var shade := index % 2
	# Tread top and soffit.
	var top_ring := _ring(hand, phi, a, b, inner, outer, top)
	_add(out, shape, eye, eye_point, top_ring, Vector3(0, -1, 0), look.tread[shade], Color(0, 0, 0, 0), index,
			_edge3(hand, phi, a, inner, outer, top), look.nosing)
	_add(out, shape, eye, eye_point, _ring(hand, phi, a, b, inner, outer, bottom), Vector3(0, 1, 0), look.soffit[shade], Color(0, 0, 0, 0), index)
	# Riser at the low end, back face at the high end.
	_add(out, shape, eye, eye_point, _radial(hand, phi, a, inner, outer, top, bottom), _tangent(hand, a - phi) * -1.0, look.riser[shade], Color(0, 0, 0, 0), index)
	_add(out, shape, eye, eye_point, _radial(hand, phi, b, inner, outer, top, bottom), _tangent(hand, b - phi), look.riser[1], Color(0, 0, 0, 0), index)
	# The inner and outer stringer faces.
	var radial_out := _radial_normal(hand, middle - phi)
	_add(out, shape, eye, eye_point, _band(hand, phi, a, b, inner, top, bottom), radial_out * -1.0, look.stringer[1], Color(0, 0, 0, 0), index)
	_add(out, shape, eye, eye_point, _band(hand, phi, a, b, outer, top, bottom), radial_out, look.stringer[1], Color(0, 0, 0, 0), index)
	# The cut through Ivo's plane: the thick band across the front.
	var cut := _cut(shape, hand, phi, a, b, top, bottom)
	if not cut.is_empty():
		var face := Face.new()
		for point: Vector3 in cut:
			face.points.append(HelixProjection.project(shape, point, eye))
		face.fill = look.stringer[0]
		face.line = look.stringer[2]
		face.depth = shape.walk_radius
		face.nearest = shape.walk_radius
		face.step = index
		out.append(face)

## Clips `points` to Ivo's plane and behind, culls it when `normal` faces away from the eye, and adds it.
static func _add(out: Array[Face], shape: HelixStairShape, eye: float, eye_point: Vector3, points: PackedVector3Array, normal: Vector3,
		fill: Color, line: Color, index: int, accent: PackedVector3Array = PackedVector3Array(), accent_color := Color(0, 0, 0, 0)) -> void:
	var kept := clip(points, shape.walk_radius)
	if kept.size() < 3:
		return
	var centre := Vector3.ZERO
	var nearest := -INF
	for point: Vector3 in kept:
		centre += point
		nearest = maxf(nearest, point.z)
	centre /= kept.size()
	if (eye_point - centre).dot(normal) <= 0.0:
		return
	var face := Face.new()
	for point: Vector3 in kept:
		face.points.append(HelixProjection.project(shape, point, eye))
	face.fill = fill
	face.line = line
	face.depth = centre.z
	face.nearest = nearest
	face.step = index
	var accent_kept := clip(accent, shape.walk_radius) if accent.size() >= 2 else PackedVector3Array()
	if accent_kept.size() >= 2:
		for point: Vector3 in accent_kept:
			face.accent.append(HelixProjection.project(shape, point, eye))
		face.accent_color = accent_color
	out.append(face)

## Keeps the part of polygon `points` with z at most `plane` (Sutherland-Hodgman against one plane).
static func clip(points: PackedVector3Array, plane: float) -> PackedVector3Array:
	var kept := PackedVector3Array()
	var count := points.size()
	for n: int in count:
		var current := points[n]
		var previous := points[(n + count - 1) % count]
		var current_in := current.z <= plane
		var previous_in := previous.z <= plane
		if current_in != previous_in:
			var t := (plane - previous.z) / (current.z - previous.z)
			kept.append(previous.lerp(current, t))
		if current_in:
			kept.append(current)
	return kept

## A horizontal annular sector from angle `a` to `b`, radii `inner` to `outer`, at height `y`.
static func _ring(hand: int, phi: float, a: float, b: float, inner: float, outer: float, y: float) -> PackedVector3Array:
	var points := PackedVector3Array()
	var count := maxi(1, ceili((b - a) / ARC_STEP))
	for n: int in count + 1:
		points.append(HelixProjection.view_point(hand, lerpf(a, b, float(n) / count), outer, y, phi))
	for n: int in range(count, -1, -1):
		points.append(HelixProjection.view_point(hand, lerpf(a, b, float(n) / count), inner, y, phi))
	return points

## A vertical radial face at angle `theta` from `inner` to `outer`, heights `y0` to `y1`.
static func _radial(hand: int, phi: float, theta: float, inner: float, outer: float, y0: float, y1: float) -> PackedVector3Array:
	return PackedVector3Array([
		HelixProjection.view_point(hand, theta, inner, y0, phi), HelixProjection.view_point(hand, theta, outer, y0, phi),
		HelixProjection.view_point(hand, theta, outer, y1, phi), HelixProjection.view_point(hand, theta, inner, y1, phi),
	])

## A vertical curved band at radius `r` from angle `a` to `b`, heights `y0` to `y1`.
static func _band(hand: int, phi: float, a: float, b: float, r: float, y0: float, y1: float) -> PackedVector3Array:
	var points := PackedVector3Array()
	var count := maxi(1, ceili((b - a) / ARC_STEP))
	for n: int in count + 1:
		points.append(HelixProjection.view_point(hand, lerpf(a, b, float(n) / count), r, y0, phi))
	for n: int in range(count, -1, -1):
		points.append(HelixProjection.view_point(hand, lerpf(a, b, float(n) / count), r, y1, phi))
	return points

## The radial edge at angle `theta` and height `y`: a tread's nosing.
static func _edge3(hand: int, phi: float, theta: float, inner: float, outer: float, y: float) -> PackedVector3Array:
	return PackedVector3Array([HelixProjection.view_point(hand, theta, inner, y, phi), HelixProjection.view_point(hand, theta, outer, y, phi)])

## The section of a step's block by Ivo's plane, as a rectangle in that plane; empty where the block does not reach it.
static func _cut(shape: HelixStairShape, hand: int, phi: float, a: float, b: float, top: float, bottom: float) -> PackedVector3Array:
	var w := shape.walk_radius
	var limit := acos(w / shape.wall_radius)
	var b0 := wrapf(a - phi, -PI, PI)
	var b1 := b0 + (b - a)
	var lo := maxf(b0, -limit)
	var hi := minf(b1, limit)
	if hi <= lo:
		return PackedVector3Array()
	var x0 := hand * w * tan(lo)
	var x1 := hand * w * tan(hi)
	return PackedVector3Array([Vector3(x0, top, w), Vector3(x1, top, w), Vector3(x1, bottom, w), Vector3(x0, bottom, w)])

## The face of the wall at radius `r` from angle `a` to `b`, heights `y0` to `y1`, projected.
static func _wall_patch(shape: HelixStairShape, hand: int, phi: float, eye: float, r: float, a: float, b: float, y0: float, y1: float) -> Face:
	var face := Face.new()
	var count := maxi(1, ceili((b - a) / ARC_STEP))
	var nearest := -INF
	for n: int in count + 1:
		var point := HelixProjection.view_point(hand, lerpf(a, b, float(n) / count), r, y0, phi)
		nearest = maxf(nearest, point.z)
		face.points.append(HelixProjection.project(shape, point, eye))
	for n: int in range(count, -1, -1):
		face.points.append(HelixProjection.project_polar(shape, hand, lerpf(a, b, float(n) / count), r, y1, phi, eye))
	face.depth = HelixProjection.view_point(hand, (a + b) * 0.5, r, 0.0, phi).z
	face.nearest = nearest
	return face

## The projected arc at radius `r` from angle `a` to `b` at height `y`.
static func _arc(shape: HelixStairShape, hand: int, phi: float, eye: float, r: float, a: float, b: float, y: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := maxi(1, ceili((b - a) / ARC_STEP))
	for n: int in count + 1:
		points.append(HelixProjection.project_polar(shape, hand, lerpf(a, b, float(n) / count), r, y, phi, eye))
	return points

static func _shifted(points: PackedVector2Array, dy: float) -> PackedVector2Array:
	var moved := PackedVector2Array()
	for point: Vector2 in points:
		moved.append(point + Vector2(0.0, dy))
	return moved

## The tangent of increasing tower angle at view angle `beta`.
static func _tangent(hand: int, beta: float) -> Vector3:
	return Vector3(hand * cos(beta), 0.0, -sin(beta))

## The outward radial direction at view angle `beta`.
static func _radial_normal(hand: int, beta: float) -> Vector3:
	return Vector3(hand * sin(beta), 0.0, cos(beta))

## `angle` moved by whole turns into the band, or as near its middle as it gets.
static func _into_band(angle: float, band: Vector2) -> float:
	var middle := (band.x + band.y) * 0.5
	return angle + roundf((middle - angle) / TAU) * TAU

## A stable 0..1 value for a course and an index.
static func _unit(course: int, index: int) -> float:
	return float(absi(hash(Vector2i(course, index))) % 1000) / 1000.0

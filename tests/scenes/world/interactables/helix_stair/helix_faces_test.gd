class_name HelixFacesTest extends GdUnitTestSuite

## The tower's faces: steps far to near after the wall and the floor, back faces culled, no step outside the stair,
## the tread under the feet within half a riser, and nothing nearer than Ivo's plane over his capsule.

const SHAPE := preload("res://resources/world/helix/bell_tower_helix.tres")
const LOOK := preload("res://resources/world/helix/bell_tower_look.tres")
const CEILING := 1440.0
const HALF_SCREEN := 180.0


func _faces(phi: float, eye: float) -> Array[HelixFaces.Face]:
	return HelixFaces.build(SHAPE, LOOK, 1, phi, eye, eye - HALF_SCREEN, eye + HALF_SCREEN, CEILING)

func test_steps_come_after_the_wall_far_to_near() -> void:
	var faces := _faces(3.0, -500.0)
	var seen_step := false
	var last := -INF
	for face: HelixFaces.Face in faces:
		if face.step == -2:
			continue
		if face.step < 0:
			assert_bool(seen_step).is_false()
			continue
		seen_step = true
		assert_float(face.depth).is_greater_equal(last)
		last = face.depth
	assert_bool(seen_step).is_true()

func test_a_tread_seen_from_below_is_culled() -> void:
	# Step 0's tread top lies 5 px above the base: from an eye below it only its soffit can show.
	var from_below := HelixFaces.step_faces(SHAPE, LOOK, 1, 0.0, 100.0, 0)
	var from_above := HelixFaces.step_faces(SHAPE, LOOK, 1, 0.0, -400.0, 0)
	assert_bool(from_below.any(func(face: HelixFaces.Face) -> bool: return face.fill == LOOK.tread[0])).is_false()
	assert_bool(from_above.any(func(face: HelixFaces.Face) -> bool: return face.fill == LOOK.tread[0])).is_true()

func test_no_step_lies_outside_the_stair() -> void:
	for face: HelixFaces.Face in _faces(HelixMath.head_u(SHAPE), -1120.0):
		assert_int(face.step).is_less(SHAPE.step_count())
	for face: HelixFaces.Face in _faces(0.0, -100.0):
		assert_int(face.step).is_greater_equal(-2)

func test_the_tread_under_the_feet_is_within_half_a_riser() -> void:
	for n: int in 200:
		var u := HelixMath.head_u(SHAPE) * n / 200.0
		var tread := HelixMath.tread_rise(SHAPE, HelixMath.step_at(SHAPE, u))
		var rise := -HelixMath.feet(SHAPE, u).y
		assert_float(absf(tread - rise)).is_less_equal(SHAPE.riser() * 0.5 + 0.001)

func test_nothing_nearer_than_ivos_plane_covers_him() -> void:
	var samples := roundi(SHAPE.turns * 64.0)
	for n: int in samples + 1:
		var u := HelixMath.head_u(SHAPE) * n / samples
		var feet := HelixMath.feet(SHAPE, u)
		var capsule := Rect2(feet.x - 11.0, feet.y - 54.0, 22.0, 54.0)
		for face: HelixFaces.Face in _faces(u, feet.y - 64.0):
			var bounds := Rect2(face.points[0], Vector2.ZERO)
			for point: Vector2 in face.points:
				bounds = bounds.expand(point)
			if bounds.intersects(capsule):
				assert_float(face.nearest).is_less_equal(SHAPE.walk_radius + 0.001)

func test_clip_keeps_the_far_side_of_the_plane() -> void:
	var square := PackedVector3Array([Vector3(0, 0, 0), Vector3(10, 0, 0), Vector3(10, 0, 20), Vector3(0, 0, 20)])
	var kept := HelixFaces.clip(square, 10.0)
	assert_int(kept.size()).is_equal(4)
	for point: Vector3 in kept:
		assert_float(point.z).is_less_equal(10.0)

func test_the_gallery_and_the_front_band_lie_in_ivos_plane() -> void:
	var head := HelixMath.head_u(SHAPE)
	var faces := _faces(head, -1120.0)
	var gallery := faces.filter(func(face: HelixFaces.Face) -> bool: return face.step == -2)
	assert_array(gallery).is_not_empty()
	assert_bool(faces.back().step == -2).is_true()
	var band := _faces(3.0, -500.0).filter(func(face: HelixFaces.Face) -> bool: return face.fill == LOOK.stringer[1] and face.depth > SHAPE.walk_radius - 0.01)
	assert_array(band).is_not_empty()

func test_the_handrail_stands_behind_ivos_plane_and_only_where_the_look_has_one() -> void:
	var stone := preload("res://resources/world/helix/lighthouse_look.tres")
	var shape := preload("res://resources/world/helix/lighthouse_helix.tres")
	for phi: float in [0.0, 1.0, 2.5, 4.0]:
		var rails := HelixFaces.build(shape, stone, 1, phi, -300.0, -480.0, -120.0, 1440.0).filter(
				func(face: HelixFaces.Face) -> bool: return face.fill == stone.rail)
		assert_array(rails).is_not_empty()
		for face: HelixFaces.Face in rails:
			assert_float(face.nearest).is_less_equal(shape.inner_radius + 0.001)
	assert_bool(_faces(1.0, -300.0).any(func(face: HelixFaces.Face) -> bool: return face.fill == LOOK.rail)).is_false()

## Joined stairs count wall courses from the tower's lowest foot: the upper flight's wall above its foot is the lower
## flight's wall moved by the rise, block for block.
func test_a_stair_on_anothers_head_continues_its_wall_courses() -> void:
	var stone := preload("res://resources/world/helix/lighthouse_look.tres")
	var shape := preload("res://resources/world/helix/lighthouse_helix.tres")
	var rise := shape.head_rise()
	var turn := HelixMath.head_u(shape)
	var phi := 1.3
	var eye := -60.0
	var upper := HelixFaces.build(shape, stone, 1, phi, eye, eye - HALF_SCREEN, eye + HALF_SCREEN, 800.0, rise, turn)
	var lower := HelixFaces.build(shape, stone, 1, phi + turn, eye - rise, eye - rise - HALF_SCREEN, eye - rise + HALF_SCREEN, 1440.0)
	var lower_walls: Array[PackedVector2Array] = []
	for face: HelixFaces.Face in lower:
		if face.step == -1 and stone.stone.has(face.fill):
			lower_walls.append(face.points)
	var compared := 0
	for face: HelixFaces.Face in upper:
		if face.step != -1 or not stone.stone.has(face.fill) or face.points.size() == 0:
			continue
		var lowest := -INF
		for point: Vector2 in face.points:
			lowest = maxf(lowest, point.y)
		if lowest > -30.0:
			continue
		var moved := PackedVector2Array()
		for point: Vector2 in face.points:
			moved.append(point - Vector2(0.0, rise))
		var found := lower_walls.any(func(points: PackedVector2Array) -> bool:
			if points.size() != moved.size():
				return false
			for n: int in points.size():
				if points[n].distance_to(moved[n]) > 0.01:
					return false
			return true)
		assert_bool(found).is_true()
		compared += 1
	assert_int(compared).is_greater(10)

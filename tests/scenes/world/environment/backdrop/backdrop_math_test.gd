class_name BackdropMathTest extends GdUnitTestSuite

## A layer stands at its authored pose at the reference camera, moves by (1 - scroll) of the camera on each
## axis, lands where Parallax2D puts it wherever its parent is, and covers everything the room's camera shows.

const HALF := Vector2(320.0, 180.0)
const FILL := BackdropLayer.Fill


func test_the_reference_camera_draws_the_anchor_where_it_is() -> void:
	var anchor := Vector2(400.0, -53.0)
	var ref := BackdropMath.reference_centre(anchor, 191.0, HALF)
	assert_vector(BackdropMath.anchor_position(anchor, ref, ref, Vector2(0.3, 0.2))).is_equal(anchor)

func test_scroll_one_is_pinned_to_the_world() -> void:
	var anchor := Vector2(0.0, 100.0)
	var ref := BackdropMath.reference_centre(anchor, 191.0, HALF)
	for camera: Vector2 in [Vector2(-900.0, 40.0), Vector2(2500.0, -1300.0)]:
		assert_vector(BackdropMath.anchor_position(anchor, ref, camera, Vector2.ONE)).is_equal(anchor)

## A far layer keeps its horizon at eye level however high or low the camera goes.
func test_vertical_scroll_zero_keeps_the_horizon_at_eye_level() -> void:
	var anchor := Vector2(0.0, 100.0)
	var ref := BackdropMath.reference_centre(anchor, 191.0, HALF)
	for y: float in [-2000.0, 0.0, 777.0]:
		var camera := Vector2(50.0, y)
		var drawn := BackdropMath.anchor_position(anchor, ref, camera, Vector2(0.1, 0.0))
		assert_float(drawn.y - (camera.y - HALF.y)).is_equal_approx(191.0, 0.001)

func test_the_axes_are_independent() -> void:
	var anchor := Vector2(10.0, 20.0)
	var ref := BackdropMath.reference_centre(anchor, 180.0, HALF)
	var moved_x := BackdropMath.anchor_position(anchor, ref, ref + Vector2(100.0, 0.0), Vector2(0.5, 0.0))
	assert_float(moved_x.y).is_equal_approx(anchor.y, 0.001)
	var moved_y := BackdropMath.anchor_position(anchor, ref, ref + Vector2(0.0, 100.0), Vector2(0.0, 0.5))
	assert_float(moved_y.x).is_equal_approx(anchor.x, 0.001)

## WORLD-04: the offset puts the layer where the model says, whatever the parent's global position.
func test_the_scroll_offset_lands_the_anchor_under_any_parent() -> void:
	var scroll := Vector2(0.2, 0.1)
	for parent: Vector2 in [Vector2.ZERO, Vector2(12160.0, 6000.0)]:
		var anchor := parent + Vector2(300.0, -53.0)
		var ref := BackdropMath.reference_centre(anchor, 191.0, HALF)
		var offset := BackdropMath.scroll_offset(anchor, ref, parent, scroll, HALF)
		var camera := anchor + Vector2(700.0, -420.0)
		# Parallax2D: local position = screen_offset * (1 - scroll) + scroll_offset.
		var placed := parent + (camera - HALF) * (Vector2.ONE - scroll) + offset
		assert_vector(placed).is_equal_approx(BackdropMath.anchor_position(anchor, ref, camera, scroll), Vector2(0.001, 0.001))

func test_moving_the_room_moves_nothing_on_screen() -> void:
	var scroll := Vector2(0.4, 0.2)
	var screen: Array[Vector2] = []
	for shift: Vector2 in [Vector2.ZERO, Vector2(12160.0, 6000.0)]:
		var anchor := shift + Vector2(0.0, -53.0)
		var ref := BackdropMath.reference_centre(anchor, 191.0, HALF)
		var camera := shift + Vector2(500.0, -100.0)
		screen.append(BackdropMath.anchor_position(anchor, ref, camera, scroll) - (camera - HALF))
	assert_vector(screen[0]).is_equal_approx(screen[1], Vector2(0.001, 0.001))

## Whatever the camera shows of the room, at zoom 1 and 1.5, lies inside the layer's cover.
func test_the_cover_holds_every_view_the_room_allows() -> void:
	for bounds: Rect2 in [Rect2(0.0, -768.0, 1920.0, 1152.0), Rect2(0.0, 0.0, 400.0, 200.0)]:
		var anchor := Vector2(0.0, 288.0)
		var ref := BackdropMath.reference_centre(anchor, 191.0, HALF)
		for scroll: Vector2 in [Vector2(0.1, 0.05), Vector2(0.8, 0.4), Vector2.ONE]:
			var cover := BackdropMath.cover_rect(bounds, anchor, ref, scroll, HALF, 0.0)
			assert_vector(Vector2(cover.position)).is_equal(Vector2(cover.position).floor())
			for zoom: float in [1.0, 1.5]:
				var half := HALF / zoom
				for corner: Vector2 in _camera_corners(bounds, half):
					var drawn := BackdropMath.anchor_position(anchor, ref, corner, scroll)
					var view := Rect2(corner - half - drawn, half * 2.0)
					assert_bool(Rect2(cover).grow(0.01).encloses(view)) \
						.override_failure_message("view %s outside cover %s" % [view, cover]).is_true()

func test_clip_to_fills_trims_none_sides_and_unrepeated_columns() -> void:
	var cover := Rect2i(-100, -400, 2000, 900)
	var strip := Vector2i(1024, 346)
	assert_object(BackdropMath.clip_to_fills(cover, strip, 229, FILL.EDGE, FILL.EDGE, true)).is_equal(cover)
	var clipped := BackdropMath.clip_to_fills(cover, strip, 229, FILL.NONE, FILL.EDGE, true)
	assert_int(clipped.position.y).is_equal(-229)
	clipped = BackdropMath.clip_to_fills(cover, strip, 229, FILL.REPEAT, FILL.NONE, false)
	assert_int(clipped.end.y).is_equal(346 - 229)
	assert_int(clipped.position.x).is_equal(0)
	assert_int(clipped.end.x).is_equal(1024)

func test_art_rows_fill_by_edge_repeat_or_nothing() -> void:
	assert_int(BackdropMath.art_row(0, 346, FILL.NONE, FILL.NONE)).is_equal(0)
	assert_int(BackdropMath.art_row(345, 346, FILL.NONE, FILL.NONE)).is_equal(345)
	assert_int(BackdropMath.art_row(-1, 346, FILL.NONE, FILL.EDGE)).is_equal(-1)
	assert_int(BackdropMath.art_row(-1, 346, FILL.EDGE, FILL.NONE)).is_equal(0)
	assert_int(BackdropMath.art_row(346, 346, FILL.NONE, FILL.EDGE)).is_equal(345)
	assert_int(BackdropMath.art_row(346, 346, FILL.NONE, FILL.NONE)).is_equal(-1)
	assert_int(BackdropMath.art_row(-1, 346, FILL.REPEAT, FILL.NONE)).is_equal(345)
	assert_int(BackdropMath.art_row(-3 * 346 - 1, 346, FILL.REPEAT, FILL.NONE)).is_equal(345)
	assert_int(BackdropMath.art_row(346 * 2 + 5, 346, FILL.NONE, FILL.REPEAT)).is_equal(5)

func test_art_columns_repeat_or_stop() -> void:
	assert_int(BackdropMath.art_col(-1, 1024, true)).is_equal(1023)
	assert_int(BackdropMath.art_col(2048 + 3, 1024, true)).is_equal(3)
	assert_int(BackdropMath.art_col(-1, 1024, false)).is_equal(-1)
	assert_int(BackdropMath.art_col(1024, 1024, false)).is_equal(-1)
	assert_int(BackdropMath.art_col(17, 1024, false)).is_equal(17)

func _camera_corners(bounds: Rect2, half: Vector2) -> Array[Vector2]:
	var low := bounds.position + half
	var high := bounds.end - half
	for axis: int in 2:
		if low[axis] > high[axis]:
			low[axis] = bounds.get_center()[axis]
			high[axis] = low[axis]
	return [low, high, Vector2(low.x, high.y), Vector2(high.x, low.y)]

# Exactly one room draws every backdrop pixel near a seam (architecture/backdrop-seams).
func _owners(rooms: Array[Rect2], point: Vector2) -> int:
	var count := 0
	for room: Rect2 in rooms:
		var others: Array[Rect2] = []
		for other: Rect2 in rooms:
			if other != room and room.grow(1.0).intersects(other):
				others.append(other)
		if BackdropMath.keeps(point, room, others, RoomRing.WIDTH):
			count += 1
	return count

func _nearest_distance(rooms: Array[Rect2], point: Vector2) -> float:
	var nearest := INF
	for room: Rect2 in rooms:
		nearest = minf(nearest, BackdropMath.rect_distance(room, point))
	return nearest

func _assert_one_owner(rooms: Array[Rect2], points: PackedVector2Array) -> void:
	for point: Vector2 in points:
		var inside := false
		for room: Rect2 in rooms:
			inside = inside or room.has_point(point)
		if inside or _nearest_distance(rooms, point) <= RoomRing.WIDTH:
			assert_int(_owners(rooms, point)).override_failure_message("%d owners at %s" % [_owners(rooms, point), point]).is_equal(1)

func test_side_by_side_rooms_share_every_seam_pixel_once() -> void:
	var rooms: Array[Rect2] = [Rect2(0, 0, 640, 384), Rect2(640, 0, 640, 384)]
	_assert_one_owner(rooms, PackedVector2Array([Vector2(600.5, 100.5), Vector2(639.5, 200.5), Vector2(640.5, 200.5), Vector2(671.5, 50.5)]))

## A seam is a hard cut: the last pixel column before it is the left room's, the first after it the right room's.
func test_a_seam_is_a_hard_cut() -> void:
	var left := Rect2(0, 0, 640, 384)
	var right := Rect2(640, 0, 640, 384)
	var lefts: Array[Rect2] = [left]
	var rights: Array[Rect2] = [right]
	for y: float in [0.5, 100.5, 383.5]:
		assert_bool(BackdropMath.keeps(Vector2(639.5, y), left, rights, RoomRing.WIDTH)).is_true()
		assert_bool(BackdropMath.keeps(Vector2(639.5, y), right, lefts, RoomRing.WIDTH)).is_false()
		assert_bool(BackdropMath.keeps(Vector2(640.5, y), right, lefts, RoomRing.WIDTH)).is_true()
		assert_bool(BackdropMath.keeps(Vector2(640.5, y), left, rights, RoomRing.WIDTH)).is_false()

func test_a_corner_of_four_rooms_has_one_owner_per_pixel() -> void:
	var rooms: Array[Rect2] = [Rect2(0, 0, 640, 384), Rect2(640, 0, 640, 384), Rect2(0, 384, 640, 384), Rect2(640, 384, 640, 384)]
	_assert_one_owner(rooms, PackedVector2Array([Vector2(630.5, 380.5), Vector2(650.5, 390.5), Vector2(639.5, 384.5), Vector2(640.5, 383.5)]))

## A room against the void keeps its whole rect, and draws the void within its ring.
func test_a_room_against_the_void_keeps_its_edge_and_its_ring() -> void:
	var rooms: Array[Rect2] = [Rect2(0, 0, 640, 384)]
	_assert_one_owner(rooms, PackedVector2Array([Vector2(0.5, 0.5), Vector2(639.5, 383.5), Vector2(-100.5, -100.5), Vector2(700.5, 200.5)]))
	var none: Array[Rect2] = []
	assert_bool(BackdropMath.keeps(Vector2(320.5, -150.5), rooms[0], none, RoomRing.WIDTH)).is_true()
	assert_bool(BackdropMath.keeps(Vector2(320.5, -170.5), rooms[0], none, RoomRing.WIDTH)).is_false()

## bugs/the-ring-tie-wedge-draws-a-hard-diagonal-between-two-backdrops: over two open tops side by side, the seam runs
## on straight up, not on a 45-degree line: a pixel over a room's columns is that room's.
func test_the_seam_runs_straight_over_two_open_tops() -> void:
	var left := Rect2(0, 0, 640, 384)
	var right := Rect2(640, 0, 640, 384)
	var lefts: Array[Rect2] = [left]
	var rights: Array[Rect2] = [right]
	for point: Vector2 in [Vector2(660.5, -60.5), Vector2(700.5, -150.5), Vector2(641.5, -20.5), Vector2(640.5, -159.5)]:
		assert_bool(BackdropMath.keeps(point, right, lefts, RoomRing.WIDTH)).is_true()
		assert_bool(BackdropMath.keeps(point, left, rights, RoomRing.WIDTH)).is_false()
	for point: Vector2 in [Vector2(620.5, -60.5), Vector2(580.5, -150.5), Vector2(639.5, -159.5)]:
		assert_bool(BackdropMath.keeps(point, left, rights, RoomRing.WIDTH)).is_true()
	var rooms: Array[Rect2] = [left, right]
	var points := PackedVector2Array()
	for y: float in [-0.5, -40.5, -100.5, -159.5]:
		for x: float in [600.5, 630.5, 639.5, 640.5, 650.5, 700.5]:
			points.append(Vector2(x, y))
	_assert_one_owner(rooms, points)

## bugs/the-ring-dividing-line-leaves-a-one-pixel-diagonal-hole-above-a-seam: two rooms' quads place one pixel a hair
## apart; judged by its pixel centre, it still has exactly one owner, on the old diagonal tie line included.
func test_two_quads_that_disagree_on_a_pixel_give_it_one_owner() -> void:
	# The inner corner between a tall room and a short one beside it: the gaps tie on a diagonal through pixel centres.
	var tall := Rect2(0, 0, 640, 768)
	var short := Rect2(640, 384, 640, 384)
	var talls: Array[Rect2] = [tall]
	var shorts: Array[Rect2] = [short]
	for d: int in range(0, 150, 7):
		for noise: Vector2 in [Vector2(0.0004, -0.0003), Vector2(-0.0004, 0.0003), Vector2(0.0003, 0.0004)]:
			var exact := Vector2(640.5 + d, 383.5 - d)
			var by_tall := BackdropMath.pixel_centre(exact + noise)
			var by_short := BackdropMath.pixel_centre(exact - noise)
			var count := int(BackdropMath.keeps(by_tall, tall, shorts, RoomRing.WIDTH)) \
				+ int(BackdropMath.keeps(by_short, short, talls, RoomRing.WIDTH))
			assert_int(count).is_equal(1)

## bugs/the-drawn-frame-correction-flips-between-candidates-and-drops-ivo-out-of-frame: the void beside a short room and
## above it, next to a taller one, has one owner everywhere: the nearer room.
func test_the_void_between_a_tall_and_a_short_room_has_one_owner() -> void:
	var rooms: Array[Rect2] = [Rect2(0, 0, 640, 768), Rect2(640, 384, 640, 384)]
	var points := PackedVector2Array()
	for y: float in [230.5, 300.5, 383.5]:
		for x: float in [641.5, 700.5, 800.5, 1270.5]:
			points.append(Vector2(x, y))
	_assert_one_owner(rooms, points)
	# Above the short room's columns the void is the short room's: the tall room's edge runs on straight up.
	var others: Array[Rect2] = [rooms[1]]
	var tall: Array[Rect2] = [rooms[0]]
	for point: Vector2 in [Vector2(640.5, 300.5), Vector2(660.5, 300.5), Vector2(900.5, 230.5)]:
		assert_bool(BackdropMath.keeps(point, rooms[1], tall, RoomRing.WIDTH)).is_true()
		assert_bool(BackdropMath.keeps(point, rooms[0], others, RoomRing.WIDTH)).is_false()
	assert_bool(BackdropMath.keeps(Vector2(639.5, 300.5), rooms[0], others, RoomRing.WIDTH)).is_true()

## bugs/a-ring-corner-diagonal-shows-a-rock-wall-in-the-mills-sky-on-a-jump: over a wide room's open top beside a tall room
## standing on its other half, the void is the wide room's up to the tall room's edge, never a 45-degree wedge of the tall
## room's backdrop.
func test_an_l_corner_continues_the_edge_straight_up() -> void:
	var wide := Rect2(0, 0, 1280, 384)
	var tall := Rect2(640, -1920, 640, 1920)
	var walls: Array[Rect2] = [tall]
	var floors: Array[Rect2] = [wide]
	for point: Vector2 in [Vector2(639.5, -0.5), Vector2(620.5, -60.5), Vector2(500.5, -159.5), Vector2(639.5, -150.5)]:
		assert_bool(BackdropMath.keeps(point, wide, walls, RoomRing.WIDTH)).is_true()
		assert_bool(BackdropMath.keeps(point, tall, floors, RoomRing.WIDTH)).is_false()
	# Past the wide room's ring the tall room draws the void beside it, so there is no hole.
	assert_bool(BackdropMath.keeps(Vector2(620.5, -200.5), tall, floors, RoomRing.WIDTH)).is_true()
	assert_bool(BackdropMath.keeps(Vector2(620.5, -200.5), wide, walls, RoomRing.WIDTH)).is_false()
	var rooms: Array[Rect2] = [wide, tall]
	var points := PackedVector2Array()
	for y: float in [-0.5, -60.5, -159.5, -160.5, -200.5]:
		for x: float in [481.5, 560.5, 620.5, 639.5]:
			points.append(Vector2(x, y))
	_assert_one_owner(rooms, points)

## Under a short room's floor beside a deeper room, the deeper room's backdrop goes on down: ground, not the short room's
## sky; the boundary is the deeper room's ring limit, straight.
func test_under_a_floor_the_deeper_neighbour_goes_on_down() -> void:
	var deep := Rect2(0, 0, 640, 768)
	var short := Rect2(640, 0, 640, 384)
	var shorts: Array[Rect2] = [short]
	var deeps: Array[Rect2] = [deep]
	for point: Vector2 in [Vector2(640.5, 384.5), Vector2(700.5, 420.5), Vector2(799.5, 543.5)]:
		assert_bool(BackdropMath.keeps(point, deep, shorts, RoomRing.WIDTH)).is_true()
		assert_bool(BackdropMath.keeps(point, short, deeps, RoomRing.WIDTH)).is_false()
	assert_bool(BackdropMath.keeps(Vector2(800.5, 420.5), short, deeps, RoomRing.WIDTH)).is_true()
	var rooms: Array[Rect2] = [deep, short]
	var points := PackedVector2Array()
	for y: float in [384.5, 450.5, 543.5]:
		for x: float in [640.5, 799.5, 800.5, 1000.5]:
			points.append(Vector2(x, y))
	_assert_one_owner(rooms, points)

func test_over_top_is_above_the_rooms_top_edge_only() -> void:
	var room := Rect2(0, 0, 640, 384)
	assert_bool(BackdropMath.over_top(Vector2(320.5, -0.5), room)).is_true()
	assert_bool(BackdropMath.over_top(Vector2(-100.5, -40.5), room)).is_true()
	assert_bool(BackdropMath.over_top(Vector2(320.5, 0.5), room)).is_false()
	assert_bool(BackdropMath.over_top(Vector2(700.5, 200.5), room)).is_false()

func test_a_room_past_the_ring_owns_no_void() -> void:
	var near := Rect2(0, 0, 640, 384)
	var far := Rect2(0, 600, 640, 384)
	var rooms: Array[Rect2] = [near, far]
	# 200 px below the near room and 16 px above the far one: the far room's columns hold it and it is within its ring.
	assert_int(BackdropMath.void_owner(Vector2(320.5, 584.5), rooms, RoomRing.WIDTH)).is_equal(1)
	assert_int(BackdropMath.void_owner(Vector2(320.5, 1200.5), rooms, RoomRing.WIDTH)).is_equal(-1)

## Ring 0: the room's own rect, nothing past it.
func test_ring_zero_is_the_room_clip() -> void:
	var own := Rect2(0, 0, 640, 384)
	var others: Array[Rect2] = [Rect2(640, 0, 640, 384)]
	assert_bool(BackdropMath.keeps(Vector2(639.5, 10.0), own, others, 0.0)).is_true()
	assert_bool(BackdropMath.keeps(Vector2(640.5, 10.0), own, others, 0.0)).is_false()
	assert_bool(BackdropMath.keeps(Vector2(320.0, -0.5), own, others, 0.0)).is_false()

func test_one_set_at_one_horizon_is_the_same_picture() -> void:
	var valley := preload("res://resources/world/backdrops/village_valley.tres")
	var caves := preload("res://resources/world/backdrops/ice_caves.tres")
	# Every valley layer repeats across, so only the horizon's y matters.
	assert_bool(BackdropMath.same_picture(valley, Vector2(0, 235), valley, Vector2(-1280, 235))).is_true()
	assert_bool(BackdropMath.same_picture(valley, Vector2(0, 235), valley, Vector2(0, -1685))).is_false()
	# A cave wall repeats both ways: placed from world 0 whatever the anchor.
	assert_bool(BackdropMath.same_picture(caves, Vector2(0, 235), caves, Vector2(640, -1685))).is_true()
	assert_bool(BackdropMath.same_picture(valley, Vector2(0, 235), caves, Vector2(0, 235))).is_false()

func test_a_layer_with_a_side_edge_compares_the_anchors_x() -> void:
	var layer := BackdropLayer.new()
	layer.repeat_x = false
	var strip := BackdropSet.new()
	strip.layers = [layer]
	assert_bool(BackdropMath.same_picture(strip, Vector2(0, 10), strip, Vector2(640, 10))).is_false()
	assert_bool(BackdropMath.same_picture(strip, Vector2(640, 10), strip, Vector2(640, 10))).is_true()

func test_a_repeating_axis_is_placed_from_world_zero() -> void:
	assert_vector(BackdropMath.layer_anchor(Vector2(1920, 235), true, false)).is_equal(Vector2(0, 235))
	assert_vector(BackdropMath.layer_anchor(Vector2(1920, 235), true, true)).is_equal(Vector2.ZERO)
	assert_vector(BackdropMath.layer_anchor(Vector2(1920, 235), false, false)).is_equal(Vector2(1920, 235))

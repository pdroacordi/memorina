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

# Exactly one room draws every backdrop pixel near a seam, for every jitter cell (architecture/backdrop-seams).
func _owners(rooms: Array[Rect2], point: Vector2, jitter: Vector2) -> int:
	var count := 0
	for room: Rect2 in rooms:
		var others: Array[Rect2] = []
		for other: Rect2 in rooms:
			if other != room and room.grow(1.0).intersects(other):
				others.append(other)
		if BackdropMath.keeps(point, jitter, room, others):
			count += 1
	return count

func _assert_one_owner(rooms: Array[Rect2], points: PackedVector2Array) -> void:
	for y: int in 4:
		for x: int in 4:
			var jitter := BackdropMath.seam_jitter(Vector2i(x, y), Backdrop.SEAM_BAND)
			for point: Vector2 in points:
				var inside := false
				for room: Rect2 in rooms:
					inside = inside or room.has_point(point)
				if inside:
					assert_int(_owners(rooms, point, jitter)).is_equal(1)

func test_side_by_side_rooms_share_every_seam_pixel_once() -> void:
	var rooms: Array[Rect2] = [Rect2(0, 0, 640, 384), Rect2(640, 0, 640, 384)]
	_assert_one_owner(rooms, PackedVector2Array([Vector2(600.5, 100.5), Vector2(639.5, 200.5), Vector2(640.5, 200.5), Vector2(671.5, 50.5)]))

func test_a_corner_of_four_rooms_has_one_owner_per_pixel() -> void:
	var rooms: Array[Rect2] = [Rect2(0, 0, 640, 384), Rect2(640, 0, 640, 384), Rect2(0, 384, 640, 384), Rect2(640, 384, 640, 384)]
	_assert_one_owner(rooms, PackedVector2Array([Vector2(630.5, 380.5), Vector2(650.5, 390.5), Vector2(639.5, 384.5), Vector2(640.5, 383.5)]))

## A room against the void keeps its whole rect: a jitter into nothing is its own.
func test_a_room_against_the_void_keeps_its_edge() -> void:
	var rooms: Array[Rect2] = [Rect2(0, 0, 640, 384)]
	_assert_one_owner(rooms, PackedVector2Array([Vector2(0.5, 0.5), Vector2(639.5, 383.5)]))

func test_the_jitter_is_symmetric_and_within_half_the_band() -> void:
	var levels := {}
	for y: int in 4:
		for x: int in 4:
			var jitter := BackdropMath.seam_jitter(Vector2i(x, y), Backdrop.SEAM_BAND)
			assert_bool(absf(jitter.x) <= 32.0 and absf(jitter.y) <= 32.0).is_true()
			levels[jitter.x] = true
	assert_int(levels.size()).is_equal(16)

func test_band_zero_is_the_room_clip() -> void:
	var own := Rect2(0, 0, 640, 384)
	var others: Array[Rect2] = [Rect2(640, 0, 640, 384)]
	assert_bool(BackdropMath.keeps(Vector2(639.5, 10.0), BackdropMath.seam_jitter(Vector2i(3, 1), 0.0), own, others)).is_true()
	assert_bool(BackdropMath.keeps(Vector2(640.5, 10.0), BackdropMath.seam_jitter(Vector2i(3, 1), 0.0), own, others)).is_false()

func test_a_repeating_axis_is_placed_from_world_zero() -> void:
	assert_vector(BackdropMath.layer_anchor(Vector2(1920, 235), true, false)).is_equal(Vector2(0, 235))
	assert_vector(BackdropMath.layer_anchor(Vector2(1920, 235), true, true)).is_equal(Vector2.ZERO)
	assert_vector(BackdropMath.layer_anchor(Vector2(1920, 235), false, false)).is_equal(Vector2(1920, 235))

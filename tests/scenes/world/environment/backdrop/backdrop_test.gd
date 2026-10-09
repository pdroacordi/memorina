class_name BackdropTest extends GdUnitTestSuite

## The Backdrop builds one Parallax2D per layer, and the camera puts each where BackdropMath says, at zoom
## 1 and 1.5, for a room at the origin and one far from it (WORLD-04).

const SET := preload("res://resources/world/backdrops/pine_woods.tres")
const HALF := Vector2(320.0, 180.0)

var _camera: Camera2D


func before_test() -> void:
	_camera = auto_free(Camera2D.new()) as Camera2D
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	add_child(_camera)
	_camera.make_current()

func _room_at(origin: Vector2) -> Room:
	var room := auto_free(Room.new()) as Room
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(1920.0, 768.0)
	shape.shape = rect
	shape.position = rect.size * 0.5
	room.add_child(shape)
	room.position = origin
	add_child(room)
	return room

func _backdrop_in(room: Room, horizon_y: float) -> Backdrop:
	var contents := Node2D.new()
	room.add_child(contents)
	var backdrop := Backdrop.new()
	backdrop.horizon_y = horizon_y
	backdrop.backdrop_set = SET
	contents.add_child(backdrop)
	return backdrop

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().process_frame

func test_one_parallax_per_layer_in_order() -> void:
	var backdrop := _backdrop_in(_room_at(Vector2.ZERO), 235.0)
	assert_int(backdrop.get_child_count()).is_equal(SET.layers.size())
	for i: int in SET.layers.size():
		var parallax := backdrop.get_child(i) as Parallax2D
		assert_vector(parallax.scroll_scale).is_equal(SET.layers[i].scroll_scale)

func test_layers_land_where_the_model_says_at_both_zooms() -> void:
	var room := _room_at(Vector2.ZERO)
	var backdrop := _backdrop_in(room, 235.0)
	for zoom: float in [1.0, 1.5]:
		_camera.zoom = Vector2(zoom, zoom)
		_camera.position = Vector2(1100.0, 300.0)
		await _frames(3)
		_assert_layers(backdrop)

## Same camera relative to the room, room at the origin or at (12160, 6000): same picture.
func test_a_room_far_from_the_origin_looks_the_same() -> void:
	var on_screen: Array[PackedVector2Array] = []
	for origin: Vector2 in [Vector2.ZERO, Vector2(12160.0, 6000.0)]:
		var backdrop := _backdrop_in(_room_at(origin), 235.0)
		_camera.zoom = Vector2.ONE
		_camera.position = origin + Vector2(900.0, 260.0)
		await _frames(3)
		var points := PackedVector2Array()
		for parallax: Node in backdrop.get_children():
			points.append((parallax as Node2D).global_position - (_camera.get_screen_center_position() - HALF))
		on_screen.append(points)
		backdrop.get_parent().queue_free()
	for i: int in on_screen[0].size():
		assert_vector(on_screen[0][i]).is_equal_approx(on_screen[1][i], Vector2(0.5, 0.5))

func test_without_a_room_it_builds_from_the_preview_bounds() -> void:
	var holder := auto_free(Node2D.new()) as Node2D
	add_child(holder)
	var backdrop := Backdrop.new()
	backdrop.backdrop_set = SET
	holder.add_child(backdrop)
	assert_int(backdrop.get_child_count()).is_equal(SET.layers.size())

func test_setting_the_set_again_rebuilds_once() -> void:
	var backdrop := _backdrop_in(_room_at(Vector2.ZERO), 235.0)
	backdrop.backdrop_set = SET
	backdrop.backdrop_set = SET
	await _frames(1)
	assert_int(backdrop.get_child_count()).is_equal(SET.layers.size())

func _assert_layers(backdrop: Backdrop) -> void:
	var anchor := backdrop.global_position + Vector2(0.0, backdrop.horizon_y)
	var ref := BackdropMath.reference_centre(anchor, SET.horizon_screen_y, HALF)
	var centre := _camera.get_screen_center_position()
	for i: int in SET.layers.size():
		var parallax := backdrop.get_child(i) as Parallax2D
		var expected := BackdropMath.anchor_position(anchor, ref, centre, SET.layers[i].scroll_scale)
		assert_vector(parallax.global_position).override_failure_message(
				"layer %d at zoom %s: %s, expected %s" % [i, _camera.zoom, parallax.global_position, expected]) \
			.is_equal_approx(expected, Vector2(0.5, 0.5))

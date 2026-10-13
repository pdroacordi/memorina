class_name BackdropTest extends GdUnitTestSuite

## The Backdrop builds one Parallax2D per layer, and the camera puts each where BackdropMath says, at zoom
## 1 and 1.5, for a room at the origin and one far from it (WORLD-04).

const SET := preload("res://resources/world/backdrops/village_valley.tres")
const CAVES := preload("res://resources/world/backdrops/ice_caves.tres")
const HALF := Vector2(320.0, 180.0)

var _camera: Camera2D


func before_test() -> void:
	SaveSystem.begin("", true)
	_camera = auto_free(Camera2D.new()) as Camera2D
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	add_child(_camera)
	_camera.make_current()

func after_test() -> void:
	SaveSystem.begin("", true)

# A region at `origin` showing SET at `horizon_y` px below it.
func _region_at(origin: Vector2, horizon_y: float) -> Region:
	var region := auto_free(Region.new()) as Region
	# A scene path keys the region quietly (SceneKey warns for a bare node).
	region.scene_file_path = "res://scenes/world/rooms/home_village.tscn"
	region.backdrop_set = SET
	region.horizon_y = horizon_y
	var memory := RegionMemory.new()
	memory.name = "Memory"
	region.add_child(memory)
	region.position = origin
	add_child(region)
	return region

func _room_in(region: Region, at: Vector2) -> Room:
	var room := Room.new()
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(1920.0, 768.0)
	shape.shape = rect
	shape.position = rect.size * 0.5
	room.add_child(shape)
	room.position = at
	region.add_child(room)
	return room

func _room_at(origin: Vector2) -> Room:
	return _room_in(_region_at(origin, 235.0), Vector2.ZERO)

func _backdrop_in(room: Room, own: BackdropSet = null) -> Backdrop:
	var contents := Node2D.new()
	room.add_child(contents)
	var backdrop := Backdrop.new()
	backdrop.backdrop_set = own
	contents.add_child(backdrop)
	return backdrop

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().process_frame

func test_one_parallax_per_layer_in_order() -> void:
	var backdrop := _backdrop_in(_room_at(Vector2.ZERO))
	assert_int(backdrop.get_child_count()).is_equal(SET.layers.size())
	for i: int in SET.layers.size():
		var parallax := backdrop.get_child(i) as Parallax2D
		assert_vector(parallax.scroll_scale).is_equal(SET.layers[i].scroll_scale)

func test_layers_land_where_the_model_says_at_both_zooms() -> void:
	var room := _room_at(Vector2.ZERO)
	var backdrop := _backdrop_in(room)
	for zoom: float in [1.0, 1.5]:
		_camera.zoom = Vector2(zoom, zoom)
		_camera.position = Vector2(1100.0, 300.0)
		await _frames(3)
		_assert_layers(backdrop)

## Same camera relative to the room, room at the origin or at (12160, 6000): the same vertical pose. A repeating layer is
## phased on the world, so its x differs by design (architecture/backdrop-seams); a layer that does not repeat keeps it.
func test_a_room_far_from_the_origin_keeps_its_vertical_pose() -> void:
	var on_screen: Array[PackedVector2Array] = []
	for origin: Vector2 in [Vector2.ZERO, Vector2(12160.0, 6000.0)]:
		var backdrop := _backdrop_in(_room_at(origin))
		_camera.zoom = Vector2.ONE
		_camera.position = origin + Vector2(900.0, 260.0)
		await _frames(3)
		var points := PackedVector2Array()
		for parallax: Node in backdrop.get_children():
			points.append((parallax as Node2D).global_position - (_camera.get_screen_center_position() - HALF))
		on_screen.append(points)
		backdrop.get_parent().get_parent().get_parent().queue_free()
	for i: int in on_screen[0].size():
		assert_float(on_screen[0][i].y).is_equal_approx(on_screen[1][i].y, 0.5)
		if not SET.layers[i].repeat_x:
			assert_float(on_screen[0][i].x).is_equal_approx(on_screen[1][i].x, 0.5)

func test_without_a_room_it_builds_from_the_preview_bounds() -> void:
	var holder := auto_free(Node2D.new()) as Node2D
	add_child(holder)
	var backdrop := Backdrop.new()
	backdrop.backdrop_set = SET
	holder.add_child(backdrop)
	assert_int(backdrop.get_child_count()).is_equal(SET.layers.size())

## The camera may yield into the room's ring (RoomRing.reach), so its backdrop draws the void it is nearest there; the
## shader keeps the room's own bounds to judge that.
func test_a_room_draws_its_ring() -> void:
	var room := _room_at(Vector2.ZERO)
	var backdrop := _backdrop_in(room)
	var bounds := room.get_bounds()
	var material := _material_of(backdrop)
	assert_that(material.get_shader_parameter(&"room_rect")).is_equal(Vector4(bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y))
	assert_float(material.get_shader_parameter(&"ring")).is_equal(RoomRing.WIDTH)
	# A seam is a hard cut: no band.
	assert_that(material.get_shader_parameter(&"seam_band")).is_null()

func _material_of(backdrop: Backdrop) -> ShaderMaterial:
	var quad := backdrop.get_child(0).get_node("Art") as MeshInstance2D
	return quad.material as ShaderMaterial

func test_setting_the_set_again_rebuilds_once() -> void:
	var backdrop := _backdrop_in(_room_at(Vector2.ZERO), CAVES)
	backdrop.backdrop_set = CAVES
	backdrop.backdrop_set = CAVES
	await _frames(1)
	assert_int(backdrop.get_child_count()).is_equal(CAVES.layers.size() + SET.layers.size())

## With no override a room shows its region's set; an override wins.
func test_the_region_set_shows_unless_overridden() -> void:
	var region := _region_at(Vector2.ZERO, 235.0)
	var plain := _backdrop_in(_room_in(region, Vector2.ZERO))
	assert_int(plain.get_child_count()).is_equal(SET.layers.size())
	var cave := _backdrop_in(_room_in(region, Vector2(1920.0, 0.0)), CAVES)
	# The override draws under the room's top, the region's set over it.
	assert_int(cave.get_child_count()).is_equal(CAVES.layers.size() + SET.layers.size())
	var parts: Array = []
	for child: Node in cave.get_children():
		parts.append(((child.get_node("Art") as MeshInstance2D).material as ShaderMaterial).get_shader_parameter(&"part"))
	assert_array(parts).is_equal([Backdrop.Part.UNDER_TOP, Backdrop.Part.OVER_TOP, Backdrop.Part.OVER_TOP, Backdrop.Part.OVER_TOP, Backdrop.Part.OVER_TOP])
	assert_that(_material_of(plain).get_shader_parameter(&"part")).is_equal(Backdrop.Part.ALL)
	assert_object(Backdrop.shown_set(null, region)).is_same(SET)
	assert_object(Backdrop.shown_set(CAVES, region)).is_same(CAVES)
	assert_object(Backdrop.shown_set(null, null)).is_null()

## Two rooms of one region, one stacked over the other, place every layer from one horizon: the same pixels at the seam.
func test_rooms_of_one_region_share_its_horizon() -> void:
	var region := _region_at(Vector2(0.0, 100.0), 235.0)
	var low := _backdrop_in(_room_in(region, Vector2.ZERO))
	var high := _backdrop_in(_room_in(region, Vector2(0.0, -768.0)))
	_camera.position = Vector2(900.0, 0.0)
	await _frames(3)
	for i: int in SET.layers.size():
		var a := low.get_child(i) as Parallax2D
		var b := high.get_child(i) as Parallax2D
		assert_vector(a.global_position).is_equal_approx(_expected(low, i), Vector2(0.5, 0.5))
		assert_vector(b.global_position).is_equal_approx(_expected(high, i), Vector2(0.5, 0.5))
		assert_float(_expected(low, i).y).is_equal_approx(_expected(high, i).y, 0.001)

func _expected(backdrop: Backdrop, i: int) -> Vector2:
	var region := backdrop.get_parent().get_parent().get_parent() as Region
	var anchor := BackdropMath.layer_anchor(Vector2(backdrop.global_position.x, region.global_position.y + region.horizon_y),
			SET.layers[i].repeat_x, SET.layers[i].repeats_y())
	var ref := BackdropMath.reference_centre(anchor, SET.horizon_screen_y, HALF)
	return BackdropMath.anchor_position(anchor, ref, _camera.get_screen_center_position(), SET.layers[i].scroll_scale)

func _assert_layers(backdrop: Backdrop) -> void:
	for i: int in SET.layers.size():
		var parallax := backdrop.get_child(i) as Parallax2D
		var expected := _expected(backdrop, i)
		assert_vector(parallax.global_position).override_failure_message(
				"layer %d at zoom %s: %s, expected %s" % [i, _camera.zoom, parallax.global_position, expected]) \
			.is_equal_approx(expected, Vector2(0.5, 0.5))

class_name RoomEdgesTest extends GdUnitTestSuite

## Bands only over open first-row runs with no room above, no wall on a seam, and, in the real world, slabs that cover
## exactly the 16 px outside the rooms and bands (systems/rooms "Edges").

const IVO := "res://scenes/characters/ivo/ivo.tscn"
const GAME := "res://scenes/world/game.tscn"
const REGION_SCRIPT := preload("res://scenes/world/rooms/region.gd")
const DEBUG_TRIALS := preload("res://scenes/world/debug/debug_trials.gd")
## Px between watertight samples.
const SAMPLE := 8.0
## Px around each room and band the watertight test samples.
const AROUND := 24.0

## 10 columns, 4 rows, top at y 0.
var _low := Rect2(0, 0, 320, 128)


func _closed(pattern: String) -> PackedByteArray:
	var bytes := PackedByteArray()
	for c: String in pattern:
		bytes.append(1 if c == "#" else 0)
	return bytes

func _in_slab(walls: Array[Rect2], point: Vector2) -> bool:
	return walls.any(func(wall: Rect2) -> bool: return wall.has_point(point))

func test_a_band_lies_only_over_open_columns_with_nothing_above() -> void:
	var above := Rect2(192, -384, 128, 384)
	var bands := RoomEdges.bands([_low, above] as Array[Rect2], [_closed("#..#.....#"), _closed("####")] as Array[PackedByteArray])
	assert_array(bands).contains_exactly([Rect2(32, -152, 64, 152), Rect2(128, -152, 64, 152)])

func test_a_one_way_roof_void_or_solid_first_row_cell_closes_its_column() -> void:
	var text := "[room]\norigin = 0, 0\ntileset = legacy\n\n[grid]\nS=^...S_\nSSSSSSSS\n\n[secret]\n....S...\n........\n"
	var parsed := RoomMapParser.parse(text, RoomLegend.load_default(), "fixture.room")
	assert_array(Array(parsed.errors)).is_empty()
	assert_array(Array(RoomEdges.closed_top(parsed.map))).contains_exactly([1, 1, 1, 0, 0, 0, 1, 1])

func test_no_wall_on_a_shared_edge_or_corner() -> void:
	var beside := Rect2(320, 0, 320, 128)
	var corner := Rect2(640, 128, 320, 128)
	var rooms: Array[Rect2] = [_low, beside, corner]
	var walls := RoomEdges.walls(rooms, [] as Array[Rect2])
	for y: float in [0.5, 64.5, 127.5]:
		assert_bool(_in_slab(walls, Vector2(319.5, y))).is_false()
		assert_bool(_in_slab(walls, Vector2(320.5, y))).is_false()
	assert_bool(_in_slab(walls, Vector2(639.5, 127.5))).is_false()
	assert_bool(_in_slab(walls, Vector2(640.5, 128.5))).is_false()
	# Outside both rooms at the corner contact, within 16 px of each.
	assert_bool(_in_slab(walls, Vector2(645.5, 120.5))).is_true()
	assert_bool(_in_slab(walls, Vector2(635.5, 135.5))).is_true()

func test_rooms_32_px_apart_are_walled_across_the_gap_without_entering_either() -> void:
	var apart := Rect2(352, 0, 320, 128)
	var rooms: Array[Rect2] = [_low, apart]
	var walls := RoomEdges.walls(rooms, [] as Array[Rect2])
	for x: float in [320.5, 335.5, 336.5, 351.5]:
		assert_bool(_in_slab(walls, Vector2(x, 64.5))).is_true()
	for wall: Rect2 in walls:
		for room: Rect2 in rooms:
			assert_bool(wall.intersection(room).has_area()).is_false()

## The tall room's side faces the short room's band (no wall), then the void above the band (wall).
func test_a_tall_room_beside_a_short_rooms_band() -> void:
	var tall := Rect2(0, -128, 320, 256)
	var short := Rect2(320, 0, 320, 128)
	var rooms: Array[Rect2] = [tall, short]
	var bands := RoomEdges.bands(rooms, [_closed("##########"), _closed("..........")] as Array[PackedByteArray])
	assert_array(bands).contains_exactly([Rect2(320, -152, 320, 152)])
	var walls := RoomEdges.walls(rooms, bands)
	assert_bool(_in_slab(walls, Vector2(319.5, -100.5))).is_false()
	assert_bool(_in_slab(walls, Vector2(320.5, -100.5))).is_false()
	assert_bool(_in_slab(walls, Vector2(310.5, -140.5))).is_true()
	assert_bool(_in_slab(walls, Vector2(330.5, -160.5))).is_true()
	assert_bool(_in_slab(walls, Vector2(100.5, -135.5))).is_true()

func test_a_closed_top_is_walled_flush() -> void:
	var walls := RoomEdges.walls([_low] as Array[Rect2], [] as Array[Rect2])
	assert_bool(_in_slab(walls, Vector2(100.5, -0.5))).is_true()
	assert_bool(_in_slab(walls, Vector2(100.5, 0.5))).is_false()

## Changing RoomRing.WIDTH or the camera's margin changes the ceiling (architecture/world-edges-from-the-room-list).
func test_the_ceiling_keeps_ivo_and_the_camera_margin_inside_the_ring() -> void:
	var camera := GameCamera.new()
	var margin := camera.subject_margin
	camera.free()
	assert_float(RoomEdges.CEILING_RISE + margin).is_equal(RoomRing.WIDTH)

## A full jump from RoomRing.FLOOR_ROWS under an open top never meets the ceiling.
func test_a_full_jump_from_floor_rows_down_clears_the_ceiling() -> void:
	var ivo := (load(IVO) as PackedScene).instantiate()
	var height := ((ivo.get_node("CollisionShape2D") as CollisionShape2D).shape as CapsuleShape2D).height
	ivo.free()
	var head := RoomRing.FLOOR_ROWS * RoomMap.CELL_PX - MapGuide.ivo_reach().peak() - height
	assert_float(head).is_greater(-RoomEdges.CEILING_RISE)

## Every room game.tscn places and every trial room: a point in a room or band is in no slab, a point outside them within
## THICKNESS px is in one, and no slab overlaps a room or band. Judged by distance, not by how the slabs were built.
func test_the_real_world_is_watertight() -> void:
	var rooms: Array[Rect2] = []
	var closed: Array[PackedByteArray] = []
	_load_world(rooms, closed)
	assert_int(rooms.size()).is_greater(50)
	var bands := RoomEdges.bands(rooms, closed)
	var walls := RoomEdges.walls(rooms, bands)
	var allowed: Array[Rect2] = rooms.duplicate()
	allowed.append_array(bands)
	var failures: Array[String] = []
	for wall: Rect2 in walls:
		for rect: Rect2 in allowed:
			if wall.intersection(rect).has_area():
				failures.append("slab %s overlaps %s" % [wall, rect])
	for rect: Rect2 in allowed:
		var area := rect.grow(AROUND)
		var near_allowed := allowed.filter(func(other: Rect2) -> bool: return area.grow(AROUND).intersects(other))
		var near_walls := walls.filter(func(wall: Rect2) -> bool: return area.grow(1.0).intersects(wall))
		var y := area.position.y + 0.5
		while y < area.end.y and failures.size() < 20:
			var x := area.position.x + 0.5
			while x < area.end.x:
				var point := Vector2(x, y)
				if _distance(rect, point) <= AROUND:
					var inside := near_allowed.any(func(other: Rect2) -> bool: return other.has_point(point))
					var walled := near_walls.any(func(wall: Rect2) -> bool: return wall.has_point(point))
					if inside and walled:
						failures.append("%s is in a room or band and in a slab" % point)
					elif not inside and not walled and _nearest(near_allowed, point) < RoomEdges.THICKNESS:
						failures.append("%s is outside, within %.1f px, and in no slab" % [point, _nearest(near_allowed, point)])
				x += SAMPLE
			y += SAMPLE
	assert_array(failures).is_empty()

# Px from `point` to `rect` along the larger axis (0 inside): the slabs are square-cornered.
func _distance(rect: Rect2, point: Vector2) -> float:
	var dx := maxf(maxf(rect.position.x - point.x, point.x - rect.end.x), 0.0)
	var dy := maxf(maxf(rect.position.y - point.y, point.y - rect.end.y), 0.0)
	return maxf(dx, dy)

func _nearest(rects: Array, point: Vector2) -> float:
	var best := INF
	for rect: Rect2 in rects:
		best = minf(best, _distance(rect, point))
	return best

# Every room game.tscn places, and the song trials DebugTrials mounts: its bounds and its closed first row.
func _load_world(rooms: Array[Rect2], closed: Array[PackedByteArray]) -> void:
	var state := (load(GAME) as PackedScene).get_state()
	for i: int in state.get_node_count():
		if _property(state, i, &"script") == DEBUG_TRIALS:
			var trials := DEBUG_TRIALS.new() as DebugTrials
			var regions: Array = _property(state, i, &"regions", trials.regions)
			var origin: Vector2 = _property(state, i, &"origin", trials.origin)
			var spacing: Vector2 = _property(state, i, &"spacing", trials.spacing)
			trials.free()
			for k: int in regions.size():
				_add_region(regions[k] as PackedScene, origin + spacing * k, rooms, closed)
		var scene := state.get_node_instance(i)
		if scene == null or scene.get_state().get_node_count() == 0 or _property(scene.get_state(), 0, &"script") != REGION_SCRIPT:
			continue
		_add_region(scene, _property(state, i, &"position", _property(scene.get_state(), 0, &"position", Vector2.ZERO)), rooms, closed)

func _add_region(scene: PackedScene, at: Vector2, rooms: Array[Rect2], closed: Array[PackedByteArray]) -> void:
	var region := scene.instantiate() as Node2D
	for child: Node in region.get_children():
		if child is Room:
			var room := child as Room
			var shape := room.get_node("CollisionShape2D") as CollisionShape2D
			var size := (shape.shape as RectangleShape2D).size
			rooms.append(Rect2(at + room.position + shape.position - size * 0.5, size))
			var map := room.map()
			assert_object(map).override_failure_message("%s has no map" % room.id()).is_not_null()
			closed.append(RoomEdges.closed_top(map) if map != null else PackedByteArray())
	region.free()

func _property(state: SceneState, node: int, property: StringName, fallback: Variant = null) -> Variant:
	for j: int in state.get_node_property_count(node):
		if state.get_node_property_name(node, j) == property:
			return state.get_node_property_value(node, j)
	return fallback

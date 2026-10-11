class_name HelixStairTest extends GdUnitTestSuite

## HelixStair.check: a clear column up the axis (one-ways pass), a gallery at the head, the shell's inner faces at the
## silhouette; the built stair puts its ends on the axis and turns with its rider.

const STAIR := preload("res://scenes/world/interactables/helix_stair/helix_stair.tscn")
const SHAPE_PATH := "res://resources/world/helix/bell_tower_helix.tres"
const BELL_TOWER := "res://scenes/world/rooms/home_village/contents/village_bell_tower.room"
## The bell tower's `@` cell.
const CELL := Vector2i(10, 44)


func _rows() -> PackedStringArray:
	var text := FileAccess.get_file_as_string(BELL_TOWER)
	return text.get_slice("[grid]\n", 1).get_slice("\n\n", 0).split("\n")

func _map(rows: PackedStringArray) -> RoomMap:
	var text := "[room]\norigin = 0, 0\ntileset = village\n\n[grid]\n%s\n\n[entities]\n%d,%d = {\"shape\": \"%s\"}\n" % [
			"\n".join(rows), CELL.x, CELL.y, SHAPE_PATH]
	var result := RoomMapParser.parse(text, RoomLegend.load_default(), "inline.room")
	return result.map

func _put(rows: PackedStringArray, cell: Vector2i, symbol: String) -> void:
	rows[cell.y] = rows[cell.y].substr(0, cell.x) + symbol + rows[cell.y].substr(cell.x + 1)

func _check(rows: PackedStringArray, params: Dictionary = {"shape": SHAPE_PATH}) -> String:
	return "\n".join(HelixStair.check(CELL, params, _map(rows)))

func test_the_bell_tower_stair_rides_clear() -> void:
	assert_str(_check(_rows())).is_empty()

func test_solid_ground_in_the_column_is_refused() -> void:
	var rows := _rows()
	_put(rows, Vector2i(10, 30), "S")
	assert_str(_check(rows)).contains("meets solid ground")

func test_one_way_planks_in_the_column_pass() -> void:
	var rows := _rows()
	_put(rows, Vector2i(9, 30), "-")
	_put(rows, Vector2i(10, 30), "-")
	assert_str(_check(rows)).not_contains("meets solid ground")

func test_a_head_without_a_gallery_is_refused() -> void:
	var rows := _rows()
	for col: int in range(6, 14):
		_put(rows, Vector2i(col, 10), ".")
	assert_str(_check(rows)).contains("no gallery")

func test_a_short_gallery_is_refused() -> void:
	var rows := _rows()
	for col: int in range(11, 14):
		_put(rows, Vector2i(col, 10), ".")
	assert_str(_check(rows)).contains("px of gallery")

func test_a_shell_face_off_the_silhouette_is_refused() -> void:
	var rows := _rows()
	_put(rows, Vector2i(13, 20), "S")
	assert_str(_check(rows)).contains("silhouette")

func test_a_foot_without_a_floor_is_refused() -> void:
	var rows := _rows()
	_put(rows, Vector2i(9, 45), ".")
	assert_str(_check(rows)).contains("the foot")

func test_a_missing_shape_or_a_bad_hand_is_refused() -> void:
	assert_str(_check(_rows(), {"shape": "res://nowhere.tres"})).contains("not a HelixStairShape")
	assert_str(_check(_rows(), {"shape": SHAPE_PATH, "hand": 2})).contains("hand")

func _stair() -> HelixStair:
	var stair := STAIR.instantiate() as HelixStair
	add_child(stair)
	auto_free(stair)
	return stair

func test_the_ends_stand_on_the_axis() -> void:
	var stair := _stair()
	assert_that((stair.get_node("Foot") as Node2D).global_position).is_equal(stair.feet_global(0.0))
	assert_that((stair.get_node("Head") as Node2D).global_position).is_equal(stair.feet_global(stair.head_u()))
	assert_float((stair.get_node("Head") as Node2D).global_position.x).is_equal(stair.to_global(HelixStair.AXIS).x)
	assert_int((stair.get_node("Foot") as CollisionObject2D).collision_layer).is_equal(Climbable.LAYER)

func test_the_reach_ends_are_the_floor_and_the_gallery_beside_the_axis() -> void:
	assert_array(_stair().reach_ends(CELL)).contains_exactly([Vector2i(9, 44), Vector2i(10, 9)])

func test_the_tower_turns_with_its_rider_and_rests_at_an_end() -> void:
	var stair := _stair()
	stair.set_rider_angle(2.5)
	assert_float(stair.angle()).is_equal(2.5)
	stair.clear_rider(true)
	assert_float(stair.angle()).is_equal(stair.head_u())
	stair.clear_rider(false)
	assert_float(stair.angle()).is_equal(0.0)

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

func test_the_lighthouse_stairs_ride_clear() -> void:
	var path := "res://scenes/world/rooms/frost_edge/contents/lighthouse_interior.room"
	var map := RoomMapParser.parse(FileAccess.get_file_as_string(path), RoomLegend.load_default(), path).map
	var stairs := 0
	for placed: Dictionary in map.entities:
		if placed.symbol == "@":
			stairs += 1
			assert_str("\n".join(HelixStair.check(placed.cell, placed.params, map))).is_empty()
	assert_int(stairs).is_equal(2)

## Two lighthouse stairs on one axis, the second's foot on the first's head, as siblings.
func _tower() -> Array[HelixStair]:
	var holder := auto_free(Node2D.new()) as Node2D
	var shape := load("res://resources/world/helix/lighthouse_helix.tres") as HelixStairShape
	var stairs: Array[HelixStair] = []
	for n: int in 2:
		var stair := STAIR.instantiate() as HelixStair
		stair.shape = shape
		stair.position = Vector2(336.0, 1440.0 - n * shape.head_rise())
		holder.add_child(stair)
		stairs.append(stair)
	# Added whole, as RoomMapNode adds its entities.
	add_child(holder)
	return stairs

func test_a_stair_on_anothers_head_continues_it() -> void:
	var tower := _tower()
	assert_object(tower[0].above()).is_same(tower[1])
	assert_object(tower[1].below()).is_same(tower[0])
	assert_object(tower[0].below()).is_null()
	assert_object(tower[1].above()).is_null()

func test_the_stairs_of_one_tower_turn_as_one() -> void:
	var tower := _tower()
	tower[0].set_rider_angle(2.0)
	assert_float(tower[1].angle()).is_equal_approx(2.0 - tower[0].head_u(), 0.0001)
	tower[1].set_rider_angle(1.5)
	assert_float(tower[0].angle()).is_equal_approx(tower[0].head_u() + 1.5, 0.0001)
	tower[1].clear_rider(false)
	assert_float(tower[0].angle()).is_equal_approx(tower[0].head_u(), 0.0001)
	assert_float(tower[1].angle()).is_equal_approx(0.0, 0.0001)

func test_a_view_under_another_stair_stops_at_its_head() -> void:
	var tower := _tower()
	var art_rise := int(tower[0].shape.head_rise()) / HelixView.ART_SCALE
	assert_int(tower[0].view().viewport().size.y).is_equal(art_rise)
	assert_float(tower[0].view().sprite().global_position.y).is_equal(tower[1].global_position.y)

func test_a_stair_joining_later_still_stops_the_view_below_at_its_head() -> void:
	var holder := auto_free(Node2D.new()) as Node2D
	add_child(holder)
	var shape := load("res://resources/world/helix/lighthouse_helix.tres") as HelixStairShape
	var lower := STAIR.instantiate() as HelixStair
	lower.shape = shape
	lower.position = Vector2(336.0, 1440.0)
	holder.add_child(lower)
	var upper := STAIR.instantiate() as HelixStair
	upper.shape = shape
	upper.position = lower.position - Vector2(0.0, shape.head_rise())
	holder.add_child(upper)
	assert_object(lower.above()).is_same(upper)
	assert_int(lower.view().viewport().size.y).is_equal(int(shape.head_rise()) / HelixView.ART_SCALE)
	assert_int(lower.get_children().filter(func(child: Node) -> bool: return child is HelixView).size()).is_equal(1)

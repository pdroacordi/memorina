class_name RoomMapNodeTest extends GdUnitTestSuite

## Entity links resolve regardless of the order in the room file.

const ROOM := """[room]
origin = 0, 0

[grid]
......
.G..P.
######

[entities]
1,1 = {"id": "door", "trigger_path": "plate"}
4,1 = {"id": "plate"}
"""

func test_a_link_to_an_entity_listed_later_resolves() -> void:
	var result := RoomMapParser.parse(ROOM, RoomLegend.load_default())
	assert_bool(result.ok()).is_true()
	var room := RoomMapNode.new()
	room.map = result.map
	add_child(room)
	auto_free(room)
	var plate := room.get_node("Entities/plate") as PressurePlate
	assert_object(plate).is_not_null()
	assert_int(plate.activated.get_connections().size()).is_equal(1)

const POOL := """[room]
origin = 0, 0

[grid]
#....#
#....#
#....#
######

[water]
.rrrr.
.~~~~.
.~~~~.
......
"""

## A reach above pool water pours one rising pool that stands at the water painted under it.
func test_a_pool_with_a_reach_rests_at_its_water() -> void:
	var result := RoomMapParser.parse(POOL, RoomLegend.load_default())
	assert_bool(result.ok()).is_true()
	var room := RoomMapNode.new()
	room.map = result.map
	add_child(room)
	auto_free(room)
	var layer := room.get_node("Water_~") as WaterLayer
	assert_int(layer.get_child_count()).is_equal(1)
	var pool := layer.get_child(0)
	assert_object(pool.get_node_or_null("Rain")).is_not_null()
	var water := pool.get_node("Water") as WaterBody
	assert_float(water.rest_depth).is_equal(32.0)

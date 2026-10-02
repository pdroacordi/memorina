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

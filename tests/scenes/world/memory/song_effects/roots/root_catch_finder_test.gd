class_name RootCatchFinderTest extends GdUnitTestSuite

## Roots seize what hangs between earth walls, never from stone, and only across a short gap.

func _map(rows: String) -> RoomMap:
	var result := RoomMapParser.parse("[grid]\n" + rows, RoomLegend.load_default())
	assert(result.ok(), str(result.errors))
	return result.map

func test_earth_on_both_sides_is_found() -> void:
	var map := _map("#....#\n######\n")
	assert_int(RootCatchFinder.earth_face(map, Vector2i(2, 0), -1, 3)).is_equal(0)
	assert_int(RootCatchFinder.earth_face(map, Vector2i(3, 0), 1, 3)).is_equal(5)

func test_stone_never_roots() -> void:
	var map := _map("S....#\n######\n")
	assert_int(RootCatchFinder.earth_face(map, Vector2i(2, 0), -1, 3)).is_equal(-1)

func test_a_wall_too_far_is_not_found() -> void:
	var map := _map("#.....\n######\n")
	assert_int(RootCatchFinder.earth_face(map, Vector2i(4, 0), -1, 2)).is_equal(-1)

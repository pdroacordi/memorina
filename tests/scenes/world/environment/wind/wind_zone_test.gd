class_name WindZoneTest extends GdUnitTestSuite

## The current's reach for the reachability audit: its box, and the downwind edge where it sets Ivo down.

const WIND := preload("res://scenes/world/environment/wind/wind_zone.tscn")

func _zone(direction: Vector2) -> WindZone:
	var zone := auto_free(WIND.instantiate()) as WindZone
	zone.size = Vector2(96, 64)
	zone.direction = direction
	return zone

func test_the_box_covers_its_cells() -> void:
	assert_int(_zone(Vector2.LEFT).reach_cells(RoomMap.new(), Vector2(48, 64)).size()).is_equal(6)

func test_a_current_sets_ivo_down_on_its_downwind_side() -> void:
	var at := Vector2(48, 64)
	assert_array(_zone(Vector2.LEFT).reach_exit_cells(RoomMap.new(), at)).contains_exactly_in_any_order([Vector2i(0, 0), Vector2i(0, 1)])
	assert_array(_zone(Vector2.RIGHT).reach_exit_cells(RoomMap.new(), at)).contains_exactly_in_any_order([Vector2i(2, 0), Vector2i(2, 1)])
	assert_array(_zone(Vector2.UP).reach_exit_cells(RoomMap.new(), at)).contains_exactly_in_any_order([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])

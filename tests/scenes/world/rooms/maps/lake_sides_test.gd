class_name LakeSidesTest extends GdUnitTestSuite

## A lake row that runs off a room side meets solid ground in the room beyond, so no lake end shows against air or the
## ring (WORLD-29, systems/water; the parser checks every end inside a room).

const LAKE := "w"


func test_every_lake_row_off_a_side_meets_the_next_rooms_ground() -> void:
	var loaded := ReachWorldLoader.load_world()
	var grid := loaded.grid
	var problems := PackedStringArray()
	var checked := 0
	for index: int in grid.room_count():
		var id := grid.room_id(index)
		var map: RoomMap = loaded.maps.get(id)
		if map == null or not map.water.has(LAKE):
			continue
		var origin := grid.room_rect(index).position - map.origin
		for point: Vector2 in map.water[LAKE]:
			var cell := Vector2i(point)
			var local := cell - map.origin
			for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT]:
				if map.contains(cell + step):
					continue
				checked += 1
				var beyond := origin + cell + step
				if grid.room_at(beyond) < 0 or grid.flags(beyond) & ReachGrid.SOLID == 0:
					problems.append("%s: lake row %d runs off its %s side into %s" % [id, local.y, "west" if step.x < 0 else "east", "no room" if grid.room_at(beyond) < 0 else "%s's air" % grid.room_id(grid.room_at(beyond))])
	assert_int(checked).is_greater(0)
	assert_array(problems).is_empty()

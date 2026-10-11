class_name FloaterTest extends GdUnitTestSuite

## The floater's reach for the reachability audit: up to the top of its own pit's water, through open cells only.

const FLOATER := preload("res://scenes/world/interactables/floater/floater.tscn")

func _rows(cells: Array[Vector2i]) -> Array[int]:
	var rows: Array[int] = []
	for cell: Vector2i in cells:
		if not cell.y in rows:
			rows.append(cell.y)
	rows.sort()
	return rows

func _reach(grid: PackedStringArray, water: PackedStringArray, cell: Vector2i) -> Array[Vector2i]:
	var floater := auto_free(FLOATER.instantiate()) as Floater
	return floater.reach_cells(ReachFixture.map(grid, water), RoomMapNode.entity_position(cell, RoomLegendEntry.Anchor.FEET))

func test_it_rises_to_the_top_of_its_basin() -> void:
	var cells := _reach(PackedStringArray([
		"#........#",
		"#........#",
		"##......##",
		"##......##",
		"##########",
	]), PackedStringArray([
		"..........",
		"..........",
		"..rrrrrr..",
		"..rrrrrr..",
		"..........",
	]), Vector2i(4, 3))
	assert_array(_rows(cells)).is_equal([2, 3, 4])

func test_a_dry_log_stays_where_it_lies() -> void:
	var cells := _reach(PackedStringArray([
		"#..........#",
		"#..........#",
		"############",
	]), PackedStringArray(), Vector2i(3, 1))
	assert_array(_rows(cells)).is_equal([2])

func test_water_past_a_lid_does_not_lift_it() -> void:
	var cells := _reach(PackedStringArray([
		"##......##",
		"##SSSSSS##",
		"##......##",
		"##......##",
		"##########",
	]), PackedStringArray([
		"..rrrrrr..",
		"..........",
		"..rrrrrr..",
		"..rrrrrr..",
		"..........",
	]), Vector2i(4, 3))
	assert_array(_rows(cells)).is_equal([2, 3, 4])

class_name LedgeDropTest extends GdUnitTestSuite

## LedgeDrop drops only over a droppable ledge with two open rows under every footing column; RoomMap and ReachGrid
## classify every cell alike.

const IVO_HEIGHT := 54.0

const SPAN := [
	"..........",
	"..........",
	".#..======",
	"..........",
	"..........",
	"##########",
]

func _map(rows: Array) -> RoomMap:
	return ReachFixture.map(PackedStringArray(rows))

func _allows(map: RoomMap, first: int, last: int, row: int = 2) -> bool:
	return LedgeDrop.allows_at(map.drop_cell, first, last, row, IVO_HEIGHT)

func test_a_body_of_54_px_needs_two_rows() -> void:
	assert_int(LedgeDrop.clearance_rows(IVO_HEIGHT)).is_equal(2)

func test_mid_span_drops() -> void:
	assert_bool(_allows(_map(SPAN), 6, 6)).is_true()
	assert_bool(_allows(_map(SPAN), 6, 7)).is_true()

func test_a_heel_over_air_drops() -> void:
	assert_bool(_allows(_map(SPAN), 3, 4)).is_true()

func test_a_heel_on_earth_refuses() -> void:
	var rows := SPAN.duplicate()
	rows[2] = ".#.#======"
	assert_bool(_allows(_map(rows), 3, 4)).is_false()

func test_no_ledge_under_the_feet_refuses() -> void:
	assert_bool(_allows(_map(SPAN), 2, 3)).is_false()

func test_a_plank_and_a_roof_never_drop() -> void:
	for symbol: String in ["-", "^"]:
		var rows := SPAN.duplicate()
		rows[2] = ".#.." + symbol.repeat(6)
		assert_bool(_allows(_map(rows), 6, 6)).override_failure_message(symbol).is_false()

func test_ground_or_a_ledge_within_two_rows_below_refuses() -> void:
	for row: int in [3, 4]:
		for symbol: String in ["#", "=", "-"]:
			var rows := SPAN.duplicate()
			rows[row] = "......" + symbol + "..."
			var map := _map(rows)
			assert_bool(_allows(map, 6, 6)).override_failure_message("%s at row %d" % [symbol, row]).is_false()
			assert_bool(_allows(map, 7, 7)).is_true()

func test_water_below_is_open() -> void:
	var water := PackedStringArray(["..........", "..........", "..........", "~~~~~~~~~~", "~~~~~~~~~~", ".........."])
	var map := ReachFixture.map(PackedStringArray(SPAN), water)
	assert_bool(_allows(map, 6, 6)).is_true()

func test_rows_off_the_map_refuse() -> void:
	var rows := ["..........", "..........", "....======", ".........."]
	assert_bool(_allows(_map(rows), 6, 6)).is_false()

func test_the_rule_wants_a_droppable_footing() -> void:
	var open: Array[LedgeDrop.Cell] = [LedgeDrop.Cell.OPEN]
	var below: Array[Array] = [[LedgeDrop.Cell.OPEN, LedgeDrop.Cell.OPEN]]
	assert_bool(LedgeDrop.allows(open, below)).is_false()
	var none: Array[LedgeDrop.Cell] = []
	assert_bool(LedgeDrop.allows(none, [])).is_false()

func test_only_a_droppable_ledge_is_droppable() -> void:
	var rows := SPAN.duplicate()
	rows[3] = "....------"
	var map := _map(rows)
	assert_bool(map.is_droppable(Vector2i(6, 2))).is_true()
	assert_bool(map.is_droppable(Vector2i(6, 3))).is_false()
	assert_bool(map.is_droppable(Vector2i(1, 2))).is_false()
	assert_bool(map.is_droppable(Vector2i(0, 0))).is_false()

func test_the_legend_marks_only_the_earth_ledge_droppable() -> void:
	var legend := RoomLegend.load_default()
	for entry: RoomLegendEntry in legend.entries:
		assert_bool(entry.droppable).override_failure_message(entry.symbol).is_equal(entry.symbol == "=")

func test_a_droppable_symbol_that_is_no_ledge_is_refused() -> void:
	var legend := RoomLegend.new()
	var entry := RoomLegendEntry.new()
	entry.symbol = "#"
	entry.droppable = true
	legend.entries.append(entry)
	assert_bool(" ".join(legend.problems()).contains("droppable")).is_true()

func test_the_grid_classifies_every_cell_like_the_map() -> void:
	var rows := PackedStringArray([
		"..........",
		"..^^......",
		".#..======",
		"...-......",
		"..S...=...",
		"##########",
	])
	var map := ReachFixture.map(rows)
	var grid := ReachFixture.grid(rows, Vector2i(0, 4))
	var problems := PackedStringArray()
	for y: int in range(-1, rows.size() + 1):
		for x: int in range(-1, rows[0].length() + 1):
			var cell := Vector2i(x, y)
			if map.drop_cell(cell) != grid.drop_cell(cell, 0):
				problems.append("%s: map %d, grid %d" % [cell, map.drop_cell(cell), grid.drop_cell(cell, 0)])
	assert_array(Array(problems)).is_empty()

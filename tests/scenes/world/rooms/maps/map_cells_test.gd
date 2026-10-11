class_name MapCellsTest extends GdUnitTestSuite

## The cells a moving floor or a box covers on the room grid.

func test_a_floor_spans_the_cells_its_top_passes() -> void:
	var cells := MapCells.floor_cells(0.0, 64.0, 64.0, 128.0)
	assert_array(cells).contains_exactly_in_any_order([Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4), Vector2i(1, 2), Vector2i(1, 3), Vector2i(1, 4)])

func test_a_floor_top_rounds_to_the_nearest_line() -> void:
	assert_array(MapCells.floor_cells(0.0, 32.0, 50.0, 50.0)).contains_exactly([Vector2i(0, 2)])

func test_a_box_covers_every_cell_it_overlaps() -> void:
	assert_array(MapCells.box_cells(Rect2(16, 0, 32, 40))).contains_exactly_in_any_order([Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)])

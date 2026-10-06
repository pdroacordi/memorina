class_name MapOutlineTest extends GdUnitTestSuite

## The map's geometry for a grid: fill runs, merged edges, concave notches and the pixel ink.


## `rows` drawn as text: '#' seen, '.' not.
func _grid(rows: Array[String]) -> MapGrid:
	var grid := MapGrid.new(Vector2i(rows[0].length(), rows.size()))
	for row: int in rows.size():
		for col: int in rows[row].length():
			if rows[row][col] == "#":
				grid.mark_cells(Rect2i(col, row, 1, 1))
	return grid

func _edge_keys(grid: MapGrid) -> Array[String]:
	var keys: Array[String] = []
	for edge: MapOutline.Edge in MapOutline.edges(grid):
		keys.append("%s %d %s %s" % [edge.start, edge.length, "h" if edge.horizontal else "v", edge.inside])
	keys.sort()
	return keys

func test_an_empty_grid_has_no_geometry() -> void:
	var grid := _grid([".."])
	assert_array(MapOutline.fill_runs(grid)).is_empty()
	assert_array(MapOutline.edges(grid)).is_empty()
	assert_dict(MapOutline.notches(grid)).is_empty()

func test_a_block_is_one_fill_rect_and_four_edges() -> void:
	var grid := _grid(["....", ".##.", ".##.", "...."])
	assert_array(MapOutline.fill_runs(grid)).contains_exactly([Rect2i(1, 1, 2, 2)])
	assert_array(_edge_keys(grid)).contains_exactly_in_any_order([
		"(1, 1) 2 h (0, 1)",
		"(1, 3) 2 h (0, -1)",
		"(1, 1) 2 v (1, 0)",
		"(3, 1) 2 v (-1, 0)",
	])
	assert_dict(MapOutline.notches(grid)).is_empty()

## Runs merge down only while the span is the same.
func test_runs_merge_down_while_the_span_matches() -> void:
	var grid := _grid(["###.", "###.", "#...", "##.#"])
	assert_array(MapOutline.fill_runs(grid)).contains_exactly_in_any_order([
		Rect2i(0, 0, 3, 2),
		Rect2i(0, 2, 1, 1),
		Rect2i(0, 3, 2, 1),
		Rect2i(3, 3, 1, 1),
	])

## The L's step is one merged edge per side, and its inner corner is a notch toward the unseen cell.
func test_an_l_has_one_notch_at_its_inner_corner() -> void:
	var grid := _grid(["#.", "##"])
	assert_array(_edge_keys(grid)).contains_exactly_in_any_order([
		"(0, 0) 1 h (0, 1)",
		"(1, 1) 1 h (0, 1)",
		"(0, 2) 2 h (0, -1)",
		"(0, 0) 2 v (1, 0)",
		"(1, 0) 1 v (-1, 0)",
		"(2, 1) 1 v (-1, 0)",
	])
	var notches := MapOutline.notches(grid)
	assert_array(notches.keys()).contains_exactly([Vector2i(1, 1)])
	assert_object(notches[Vector2i(1, 1)]).is_equal(Vector2i(1, -1))

## A hole's edges face outward from it, toward the seen cells around it.
func test_a_hole_is_edged_from_the_outside() -> void:
	var grid := _grid(["###", "#.#", "###"])
	var keys := _edge_keys(grid)
	assert_array(keys).contains(["(1, 1) 1 h (0, -1)", "(1, 2) 1 h (0, 1)", "(1, 1) 1 v (-1, 0)", "(2, 1) 1 v (1, 0)"])
	assert_int(MapOutline.notches(grid).size()).is_equal(4)

## Cells that touch only at a corner are two shapes: no notch between them.
func test_diagonal_neighbours_have_no_notch() -> void:
	var grid := _grid(["#.", ".#"])
	assert_dict(MapOutline.notches(grid)).is_empty()
	assert_int(MapOutline.edges(grid).size()).is_equal(8)

## The ink sits on the inside of the boundary, so a 2x2 block at 4 px per cell is an 8x8 ring.
func test_the_ink_lies_inside_the_seen_area() -> void:
	var grid := _grid(["##", "##"])
	var pixels := _pixels(_ink(grid, 4))
	assert_int(pixels.size()).is_equal(28)
	for pixel: Vector2i in pixels:
		assert_bool(Rect2i(0, 0, 8, 8).has_point(pixel)).is_true()
	assert_bool(pixels.has(Vector2i(0, 0))).is_true()
	assert_bool(pixels.has(Vector2i(7, 7))).is_true()
	assert_bool(pixels.has(Vector2i(1, 1))).is_false()

## The notch closes the inner corner of the L, which the two edges alone touch only diagonally.
func test_the_ink_closes_the_inner_corner() -> void:
	var grid := _grid(["#.", "##"])
	var pixels := _pixels(_ink(grid, 4))
	assert_bool(pixels.has(Vector2i(3, 3))).is_true()
	assert_bool(pixels.has(Vector2i(3, 4))).is_true()
	assert_bool(pixels.has(Vector2i(4, 4))).is_true()
	assert_bool(pixels.has(Vector2i(4, 3))).is_false()

## At one pixel per cell the ink is the boundary cells themselves.
func test_at_one_pixel_per_cell_the_ink_is_the_boundary() -> void:
	var grid := _grid(["###", "###", "###"])
	var pixels := _pixels(_ink(grid, 1))
	assert_int(pixels.size()).is_equal(8)
	assert_bool(pixels.has(Vector2i(1, 1))).is_false()

func _ink(grid: MapGrid, px: int) -> Array[Rect2i]:
	return MapOutline.ink(MapOutline.edges(grid), MapOutline.notches(grid), px)

func _pixels(rects: Array[Rect2i]) -> Dictionary[Vector2i, bool]:
	var pixels: Dictionary[Vector2i, bool] = {}
	for rect: Rect2i in rects:
		for y: int in range(rect.position.y, rect.end.y):
			for x: int in range(rect.position.x, rect.end.x):
				pixels[Vector2i(x, y)] = true
	return pixels

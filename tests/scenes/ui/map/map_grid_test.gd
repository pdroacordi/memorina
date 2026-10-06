class_name MapGridTest extends GdUnitTestSuite

## A room's seen cells: the centre rule, the byte format and the remap of a resized room.

const CELL := MapGrid.CELL_PX


func test_dims_round_up_to_whole_cells() -> void:
	assert_object(MapGrid.dims_for(Rect2(-403.75, -237, 1920, 602))).is_equal(Vector2i(30, 10))
	assert_object(MapGrid.dims_for(Rect2(0, 0, 640, 360))).is_equal(Vector2i(10, 6))
	assert_object(MapGrid.dims_for(Rect2(0, 0, 65, 64))).is_equal(Vector2i(2, 1))

func test_a_new_grid_has_seen_nothing() -> void:
	var grid := MapGrid.new(Vector2i(30, 10))
	assert_bool(grid.is_empty()).is_true()
	assert_bool(grid.is_seen(0, 0)).is_false()

## A cell counts only when its centre was inside the view.
func test_a_cell_is_seen_when_its_centre_was_in_the_rect() -> void:
	var grid := MapGrid.new(Vector2i(10, 10))
	grid.mark_rect(Rect2(CELL * 0.5, CELL * 0.5, CELL, CELL))
	assert_bool(grid.is_seen(0, 0)).is_true()
	assert_bool(grid.is_seen(1, 1)).is_false()
	assert_bool(grid.is_seen(1, 0)).is_false()

func test_a_rect_that_only_overlaps_a_cell_does_not_reveal_it() -> void:
	var grid := MapGrid.new(Vector2i(10, 10))
	grid.mark_rect(Rect2(0, 0, CELL * 0.49, CELL * 0.49))
	assert_bool(grid.is_empty()).is_true()

## A 640x360 view at the room's top-left covers 10x5 centres plus the half row: 10x6.
func test_a_view_marks_the_cells_whose_centres_it_shows() -> void:
	var grid := MapGrid.new(Vector2i(30, 10))
	grid.mark_rect(Rect2(0, 0, 640, 360))
	assert_object(grid.cells_in(Rect2(0, 0, 640, 360))).is_equal(Rect2i(0, 0, 10, 6))
	assert_bool(grid.is_seen(9, 5)).is_true()
	assert_bool(grid.is_seen(10, 0)).is_false()
	assert_bool(grid.is_seen(0, 6)).is_false()

## A 602 px room has a 10th row whose centre (608) is past the room: the frame, held inside the room, could never show it.
func test_a_cut_last_cell_counts_by_the_centre_of_its_part_in_the_room() -> void:
	var grid := MapGrid.new(Vector2i(30, 10))
	var room := Vector2(1920, 602)
	assert_object(grid.cells_in(Rect2(0, 242, 640, 360), room)).is_equal(Rect2i(0, 4, 10, 6))
	assert_object(grid.cells_in(Rect2(0, 242, 640, 346), room)).is_equal(Rect2i(0, 4, 10, 5))
	assert_object(grid.cells_in(Rect2(0, 242, 640, 360))).is_equal(Rect2i(0, 4, 10, 5))
	assert_bool(grid.mark_rect(Rect2(1280, 242, 640, 360), room)).is_true()
	assert_bool(grid.is_seen(29, 9)).is_true()

## A room cut mid-cell on both axes: the partial column counts too.
func test_a_cut_last_column_counts_the_same_way() -> void:
	var grid := MapGrid.new(Vector2i(2, 1))
	assert_object(grid.cells_in(Rect2(0, 0, 100, 64), Vector2(100, 64))).is_equal(Rect2i(0, 0, 2, 1))
	assert_object(grid.cells_in(Rect2(0, 0, 81, 64), Vector2(100, 64))).is_equal(Rect2i(0, 0, 1, 1))

func test_a_rect_past_the_room_is_clipped_to_the_grid() -> void:
	var grid := MapGrid.new(Vector2i(4, 2))
	assert_object(grid.cells_in(Rect2(-500, -500, 5000, 5000))).is_equal(Rect2i(0, 0, 4, 2))
	assert_object(grid.cells_in(Rect2(1000, 1000, 50, 50)).size).is_equal(Vector2i.ZERO)

func test_marking_reports_a_change_only_for_new_cells() -> void:
	var grid := MapGrid.new(Vector2i(10, 10))
	assert_bool(grid.mark_rect(Rect2(0, 0, 128, 128))).is_true()
	assert_bool(grid.mark_rect(Rect2(0, 0, 128, 128))).is_false()
	assert_bool(grid.mark_rect(Rect2(0, 0, 192, 128))).is_true()

func test_the_bytes_are_a_header_then_the_bits() -> void:
	var grid := MapGrid.new(Vector2i(3, 3))
	grid.mark_cells(Rect2i(0, 0, 1, 1))
	grid.mark_cells(Rect2i(2, 2, 1, 1))
	var bytes := grid.to_bytes()
	assert_int(bytes.size()).is_equal(MapGrid.HEADER_BYTES + 2)
	assert_int(bytes.decode_u16(0)).is_equal(3)
	assert_int(bytes.decode_u16(2)).is_equal(3)
	assert_int(bytes[4]).is_equal(0b0000_0001)
	assert_int(bytes[5]).is_equal(0b0000_0001)

func test_bytes_round_trip() -> void:
	var grid := MapGrid.new(Vector2i(30, 10))
	grid.mark_rect(Rect2(300, 100, 640, 360))
	var back := MapGrid.from_bytes(grid.to_bytes(), Vector2i(30, 10))
	assert_object(back.to_bytes()).is_equal(grid.to_bytes())
	assert_bool(back.is_seen(5, 2)).is_true()

func test_empty_or_malformed_bytes_give_an_empty_grid() -> void:
	assert_bool(MapGrid.from_bytes(PackedByteArray(), Vector2i(4, 4)).is_empty()).is_true()
	assert_bool(MapGrid.from_bytes(PackedByteArray([1, 2]), Vector2i(4, 4)).is_empty()).is_true()
	var truncated := MapGrid.new(Vector2i(4, 4)).to_bytes()
	truncated.resize(truncated.size() - 1)
	var grid := MapGrid.from_bytes(truncated, Vector2i(4, 4))
	assert_bool(grid.is_empty()).is_true()
	assert_int(grid.cols).is_equal(4)

## A room that grew or shrank keeps its cells by (col, row) where both sizes overlap.
func test_a_resized_room_keeps_the_cells_both_sizes_share() -> void:
	var old := MapGrid.new(Vector2i(4, 3))
	old.mark_cells(Rect2i(0, 0, 1, 1))
	old.mark_cells(Rect2i(3, 2, 1, 1))
	old.mark_cells(Rect2i(1, 1, 1, 1))
	var grown := MapGrid.from_bytes(old.to_bytes(), Vector2i(6, 5))
	assert_bool(grown.is_seen(0, 0)).is_true()
	assert_bool(grown.is_seen(3, 2)).is_true()
	assert_bool(grown.is_seen(1, 1)).is_true()
	assert_bool(grown.is_seen(4, 0)).is_false()
	var shrunk := MapGrid.from_bytes(old.to_bytes(), Vector2i(2, 2))
	assert_bool(shrunk.is_seen(0, 0)).is_true()
	assert_bool(shrunk.is_seen(1, 1)).is_true()
	assert_int(shrunk.to_bytes().size()).is_equal(MapGrid.HEADER_BYTES + 1)

func test_out_of_range_cells_are_never_seen() -> void:
	var grid := MapGrid.new(Vector2i(2, 2))
	grid.mark_cells(Rect2i(0, 0, 2, 2))
	assert_bool(grid.is_seen(-1, 0)).is_false()
	assert_bool(grid.is_seen(2, 0)).is_false()
	assert_bool(grid.is_seen(0, 2)).is_false()

func test_padded_cells_are_a_byte_per_cell_inside_an_unseen_border() -> void:
	var grid := MapGrid.new(Vector2i(3, 2))
	grid.mark_cells(Rect2i(0, 0, 1, 1))
	grid.mark_cells(Rect2i(2, 1, 1, 1))
	var cells := grid.padded_cells()
	assert_int(cells.size()).is_equal(5 * 4)
	assert_array(Array(cells)).is_equal([
		0, 0, 0, 0, 0,
		0, 1, 0, 0, 0,
		0, 0, 0, 1, 0,
		0, 0, 0, 0, 0,
	])

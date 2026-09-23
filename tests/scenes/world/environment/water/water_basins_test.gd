class_name WaterBasinsTest extends GdUnitTestSuite

## Painted water, read the way water poured into the shape would settle: one
## flat surface per body at its highest row, columns as deep as they run down
## from it, and anything a surface cannot reach reported rather than drawn.

# Cells from rows of text, top row first: '#' is painted. `origin` is the cell
# of the text's top-left character.
func _cells(rows: Array[String], origin := Vector2i.ZERO) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in rows.size():
		for x in rows[y].length():
			if rows[y][x] == "#":
				cells.append(origin + Vector2i(x, y))
	return cells

func test_nothing_painted_is_no_water() -> void:
	var built := WaterBasins.build([])
	assert_int(built.basins.size()).is_equal(0)
	assert_int(built.unreachable.size()).is_equal(0)

func test_a_single_cell_is_a_body_one_cell_deep() -> void:
	var built := WaterBasins.build([Vector2i(3, -2)])
	assert_int(built.basins.size()).is_equal(1)
	var basin := built.basins[0]
	assert_int(basin.left).is_equal(3)
	assert_int(basin.surface).is_equal(-2)
	assert_array(Array(basin.depths)).is_equal([1])

func test_a_rectangle_is_one_body_of_even_depth() -> void:
	var built := WaterBasins.build(_cells(["####", "####", "####"], Vector2i(-2, 5)))
	assert_int(built.basins.size()).is_equal(1)
	var basin := built.basins[0]
	assert_int(basin.left).is_equal(-2)
	assert_int(basin.surface).is_equal(5)
	assert_int(basin.width()).is_equal(4)
	assert_array(Array(basin.depths)).is_equal([3, 3, 3, 3])
	assert_int(built.unreachable.size()).is_equal(0)

func test_a_stepped_basin_is_one_body_with_a_stepped_floor() -> void:
	var built := WaterBasins.build(_cells([
		"#####",
		"#####",
		"  ###",
		"   # ",
	]))
	assert_int(built.basins.size()).is_equal(1)
	assert_array(Array(built.basins[0].depths)).is_equal([2, 2, 3, 4, 3])
	assert_int(built.basins[0].deepest()).is_equal(4)

func test_two_pits_are_two_bodies_ordered_left_to_right() -> void:
	var built := WaterBasins.build(_cells(["##   ###", "##   ###"]))
	assert_int(built.basins.size()).is_equal(2)
	assert_int(built.basins[0].left).is_equal(0)
	assert_int(built.basins[1].left).is_equal(5)
	assert_int(built.basins[1].width()).is_equal(3)

func test_pits_at_different_heights_keep_their_own_surface() -> void:
	var built := WaterBasins.build(_cells(["      ##", "##    ##", "##      "]))
	assert_int(built.basins.size()).is_equal(2)
	# Ordered top row first.
	assert_int(built.basins[0].surface).is_equal(0)
	assert_int(built.basins[0].left).is_equal(6)
	assert_int(built.basins[1].surface).is_equal(1)

func test_water_under_a_ledge_cannot_be_reached_by_the_surface() -> void:
	# The right-hand cell sits below the surface row with nothing above it in
	# the shape: a pocket under terrain, which a side view cannot flood.
	var built := WaterBasins.build(_cells(["## ", "###"]))
	assert_int(built.basins.size()).is_equal(1)
	assert_array(Array(built.basins[0].depths)).is_equal([2, 2])
	assert_array(built.unreachable).is_equal([Vector2i(2, 1)])

func test_a_u_bend_is_two_bodies_and_its_tunnel_is_reported() -> void:
	var built := WaterBasins.build(_cells(["# #", "###"]))
	assert_int(built.basins.size()).is_equal(2)
	assert_array(Array(built.basins[0].depths)).is_equal([2])
	assert_array(Array(built.basins[1].depths)).is_equal([2])
	assert_array(built.unreachable).is_equal([Vector2i(1, 1)])

func test_a_gap_in_a_column_ends_its_depth() -> void:
	# A column's water runs unbroken down from the surface; a cell below a gap
	# is not part of it.
	var built := WaterBasins.build(_cells(["##", "# ", "##"]))
	assert_array(Array(built.basins[0].depths)).is_equal([3, 1])
	assert_array(built.unreachable).is_equal([Vector2i(1, 2)])

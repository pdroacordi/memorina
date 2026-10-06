class_name MapOutline
extends RefCounted
## The geometry the map draws for one MapGrid: fill rectangles and the ink line along the seen area's edge.
## Scans read `MapGrid.padded_cells()` by index; see docs/knowledge/systems/map.md (Performance).


## Seen cells as rectangles in cell units: one per horizontal run, merged down while the run below has the same span.
static func fill_runs(grid: MapGrid) -> Array[Rect2i]:
	var cells := grid.padded_cells()
	var width := grid.cols + 2
	var runs: Array[Rect2i] = []
	# Index in `runs` of each run that reached the previous row, keyed by (first col, width).
	var open: Dictionary[Vector2i, int] = {}
	for row: int in grid.rows:
		var base := (row + 1) * width + 1
		var still_open: Dictionary[Vector2i, int] = {}
		var col := 0
		while col < grid.cols:
			if cells[base + col] == 0:
				col += 1
				continue
			var first := col
			# The unseen border stops the run.
			while cells[base + col] == 1:
				col += 1
			var span := Vector2i(first, col - first)
			if open.has(span):
				runs[open[span]].size.y += 1
				still_open[span] = open[span]
			else:
				runs.append(Rect2i(first, row, span.y, 1))
				still_open[span] = runs.size() - 1
		open = still_open
	return runs

## Every boundary segment, merged where collinear neighbours share the same inside.
static func edges(grid: MapGrid) -> Array[Edge]:
	var cells := grid.padded_cells()
	var width := grid.cols + 2
	var found: Array[Edge] = []
	for row: int in grid.rows + 1:
		# Padded rows `row` and `row + 1` hold grid rows `row - 1` (above the line) and `row` (below it).
		var above := row * width + 1
		var below := above + width
		var col := 0
		while col < grid.cols:
			var side := cells[below + col] - cells[above + col]
			if side == 0:
				col += 1
				continue
			var first := col
			while col < grid.cols and cells[below + col] - cells[above + col] == side:
				col += 1
			found.append(Edge.new(Vector2i(first, row), col - first, true, Vector2i(0, side)))
	for col: int in grid.cols + 1:
		var row := 0
		while row < grid.rows:
			var left := (row + 1) * width + col
			var side := cells[left + 1] - cells[left]
			if side == 0:
				row += 1
				continue
			var first := row
			while row < grid.rows and cells[(row + 1) * width + col + 1] - cells[(row + 1) * width + col] == side:
				row += 1
			found.append(Edge.new(Vector2i(col, first), row - first, false, Vector2i(side, 0)))
	return found

## Grid points of the concave corners, each with the unit diagonal toward its one unseen cell.
## An ink line drawn inside both edges leaves the cell diagonal to it uninked there.
static func notches(grid: MapGrid) -> Dictionary[Vector2i, Vector2i]:
	var cells := grid.padded_cells()
	var width := grid.cols + 2
	var found: Dictionary[Vector2i, Vector2i] = {}
	for row: int in grid.rows + 1:
		for col: int in grid.cols + 1:
			# Padded (col, row) is the cell up and left of grid point (col, row).
			var upper := row * width + col
			var lower := upper + width
			var upper_right := cells[upper + 1]
			var lower_left := cells[lower]
			var lower_right := cells[lower + 1]
			if cells[upper] + upper_right + lower_left + lower_right != 3:
				continue
			found[Vector2i(col, row)] = Vector2i(
				1 if upper_right + lower_right < 2 else -1,
				1 if lower_left + lower_right < 2 else -1)
	return found

## The ink line in pixels at `px` per cell: 1 px rects on the inside of every edge, plus each notch's pixel.
static func ink(edge_list: Array[Edge], corners: Dictionary[Vector2i, Vector2i], px: int) -> Array[Rect2i]:
	var rects: Array[Rect2i] = []
	for edge: Edge in edge_list:
		var at := edge.start * px
		if edge.horizontal:
			rects.append(Rect2i(at.x, at.y - (1 if edge.inside.y < 0 else 0), edge.length * px, 1))
		else:
			rects.append(Rect2i(at.x - (1 if edge.inside.x < 0 else 0), at.y, 1, edge.length * px))
	for point: Vector2i in corners:
		var toward := corners[point]
		rects.append(Rect2i(point * px + Vector2i(-1 if toward.x > 0 else 0, -1 if toward.y > 0 else 0), Vector2i.ONE))
	return rects


## A boundary segment between seen and unseen cells, in cell units.
class Edge:
	## Grid point where the segment starts (its top or left end).
	var start: Vector2i
	## Cells covered.
	var length: int
	var horizontal: bool
	## Unit step from the segment to its seen side.
	var inside: Vector2i

	func _init(edge_start: Vector2i, edge_length: int, is_horizontal: bool, edge_inside: Vector2i) -> void:
		start = edge_start
		length = edge_length
		horizontal = is_horizontal
		inside = edge_inside

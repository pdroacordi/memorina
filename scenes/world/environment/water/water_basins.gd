class_name WaterBasins extends RefCounted

## Painted water cells, grouped into the bodies they describe. Pure logic: it
## knows cells, not pixels, tiles or scenes, so every rule for what a painted
## shape means is tested here. WaterLayer turns the result into water.
##
## A body of water has ONE flat surface, so a painted shape is read like water
## poured into it: each 4-connected group of cells fills up to its highest row,
## the surface. Every contiguous run of columns that reaches that row is one
## body, and each column is as deep as its cells run unbroken down from the
## surface - so a stepped basin is one body with a stepped floor. A cell no
## surface can reach (under a ceiling of terrain, or below a gap) cannot hold
## water in a side view; it is reported, never silently drawn.

var basins: Array[Basin] = []
## Cells that belong to no body, in the order they were found.
var unreachable: Array[Vector2i] = []

static func build(cells: Array[Vector2i]) -> WaterBasins:
	var result := WaterBasins.new()
	var painted := {}
	for cell: Vector2i in cells:
		painted[cell] = true
	var seen := {}
	for cell: Vector2i in _sorted(cells):
		if seen.has(cell):
			continue
		result._pour(_component(cell, painted, seen))
	result.basins.sort_custom(func(a: Basin, b: Basin) -> bool:
		return a.surface < b.surface or (a.surface == b.surface and a.left < b.left))
	return result

func _pour(component: Array[Vector2i]) -> void:
	var cells := {}
	var surface := component[0].y
	for cell: Vector2i in component:
		cells[cell] = true
		surface = mini(surface, cell.y)
	var columns: Array[int] = []
	for cell: Vector2i in component:
		if cell.y == surface:
			columns.append(cell.x)
	columns.sort()
	var claimed := {}
	var run_start := 0
	for i in columns.size():
		var last_of_run := i == columns.size() - 1 or columns[i + 1] != columns[i] + 1
		if not last_of_run:
			continue
		var basin := Basin.new()
		basin.left = columns[run_start]
		basin.surface = surface
		for x in range(columns[run_start], columns[i] + 1):
			var depth := 0
			while cells.has(Vector2i(x, surface + depth)):
				claimed[Vector2i(x, surface + depth)] = true
				depth += 1
			basin.depths.append(depth)
		basins.append(basin)
		run_start = i + 1
	for cell: Vector2i in _sorted(component):
		if not claimed.has(cell):
			unreachable.append(cell)

static func _component(start: Vector2i, painted: Dictionary, seen: Dictionary) -> Array[Vector2i]:
	var found: Array[Vector2i] = [start]
	seen[start] = true
	var next := 0
	while next < found.size():
		var cell := found[next]
		next += 1
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbour := cell + step
			if painted.has(neighbour) and not seen.has(neighbour):
				seen[neighbour] = true
				found.append(neighbour)
	return found

# Row by row, left to right: the order a reader scans a map, so warnings and
# ties come out the same every run.
static func _sorted(cells: Array[Vector2i]) -> Array[Vector2i]:
	var sorted := cells.duplicate()
	sorted.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x))
	return sorted

## One body of water, in cells.
class Basin:
	## Column of the body's leftmost cell.
	var left := 0
	## Row of the body's surface: its highest painted row.
	var surface := 0
	## Cells of water in each column, left to right, counted from the surface.
	var depths := PackedInt32Array()

	func width() -> int:
		return depths.size()

	func deepest() -> int:
		var most := 0
		for depth: int in depths:
			most = maxi(most, depth)
		return most

class_name WaterBasins extends RefCounted

## Groups painted cells into reachable water bodies; cells without a surface are reported.

const NEIGHBOURS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var basins: Array[Basin] = []
var _covers := true
## Cells that belong to no body, in the order they were found.
var unreachable: Array[Vector2i] = []

## `reach` cells are where Chuva brings the water above the painted rest (docs/knowledge/architecture/a-pool-rests-below-its-painted-reach.md).
## `covers`: water under the ground joins its body as covered columns; a lake, seen from above, has none.
static func build(cells: Array[Vector2i], reach: Array[Vector2i] = [], shell_reach: Array[Vector2i] = [], covers := true) -> WaterBasins:
	var result := WaterBasins.new()
	result._covers = covers
	var painted: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in cells:
		painted[cell] = true
	# Each reach cell, true where rain raises the water to it.
	var reached: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in reach:
		painted[cell] = true
		reached[cell] = true
	for cell: Vector2i in shell_reach:
		painted[cell] = true
		reached[cell] = false
	var all := cells + reach + shell_reach
	var seen: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in _sorted(all):
		if seen.has(cell):
			continue
		result._pour(_component(cell, painted, seen), reached)
	result.basins.sort_custom(func(a: Basin, b: Basin) -> bool:
		return a.surface < b.surface or (a.surface == b.surface and a.left < b.left))
	return result

func _pour(component: Array[Vector2i], reached: Dictionary[Vector2i, bool]) -> void:
	var cells: Dictionary[Vector2i, bool] = {}
	var surface := component[0].y
	for cell: Vector2i in component:
		cells[cell] = true
		surface = mini(surface, cell.y)
	var columns: Array[int] = []
	for cell: Vector2i in component:
		if cell.y == surface:
			columns.append(cell.x)
	columns.sort()
	var claimed: Dictionary[Vector2i, bool] = {}
	var first := basins.size()
	var run_start := 0
	for i in columns.size():
		var last_of_run := i == columns.size() - 1 or columns[i + 1] != columns[i] + 1
		if not last_of_run:
			continue
		var basin := Basin.new()
		basin.left = columns[run_start]
		basin.surface = surface
		var rest_row := 0
		var has_rest := false
		for x in range(columns[run_start], columns[i] + 1):
			var depth := 0
			while cells.has(Vector2i(x, surface + depth)):
				var cell := Vector2i(x, surface + depth)
				claimed[cell] = true
				if reached.get(cell, false):
					basin.rains = true
				if not reached.has(cell) and (not has_rest or cell.y < rest_row):
					rest_row = cell.y
					has_rest = true
				depth += 1
			basin.depths.append(depth)
		basin.tops.resize(basin.depths.size())
		basin.rest = rest_row - surface if has_rest else basin.deepest()
		basins.append(basin)
		run_start = i + 1
	for index in range(first, basins.size()):
		if _covers:
			_cover(basins[index], cells, claimed)
	for cell: Vector2i in _sorted(component):
		if not claimed.has(cell):
			unreachable.append(cell)

# Water under the ground beside an open run (a flooded passage) joins the body as covered columns, each one unbroken
# run of cells under a ceiling (bugs/well-water-stands-in-the-air-at-a-passage-mouth).
static func _cover(basin: Basin, cells: Dictionary[Vector2i, bool], claimed: Dictionary[Vector2i, bool]) -> void:
	var found: Dictionary[Vector2i, bool] = {}
	var frontier: Array[Vector2i] = []
	for cell: Vector2i in claimed:
		if cell.x >= basin.left and cell.x < basin.left + basin.width():
			frontier.append(cell)
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for step: Vector2i in NEIGHBOURS:
			var next := cell + step
			if cells.has(next) and not claimed.has(next) and not found.has(next):
				found[next] = true
				frontier.append(next)
	var rows: Dictionary[int, Array] = {}
	for cell: Vector2i in found:
		if not rows.has(cell.x):
			rows[cell.x] = []
		rows[cell.x].append(cell.y)
	for direction: int in [-1, 1]:
		var x := basin.left - 1 if direction < 0 else basin.left + basin.width()
		while rows.has(x):
			var ys: Array = rows[x]
			ys.sort()
			if ys[-1] - ys[0] + 1 != ys.size():
				break
			if direction < 0:
				basin.left = x
				basin.tops.insert(0, ys[0] - basin.surface)
				basin.depths.insert(0, ys[-1] + 1 - basin.surface)
			else:
				basin.tops.append(ys[0] - basin.surface)
				basin.depths.append(ys[-1] + 1 - basin.surface)
			for y: int in ys:
				claimed[Vector2i(x, y)] = true
			x += direction

static func _component(start: Vector2i, painted: Dictionary[Vector2i, bool],
		seen: Dictionary[Vector2i, bool]) -> Array[Vector2i]:
	var found: Array[Vector2i] = [start]
	seen[start] = true
	var next := 0
	while next < found.size():
		var cell := found[next]
		next += 1
		for step: Vector2i in NEIGHBOURS:
			var neighbour := cell + step
			if painted.has(neighbour) and not seen.has(neighbour):
				seen[neighbour] = true
				found.append(neighbour)
	return found

# Row-major traversal keeps warnings and ties deterministic.
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
	## Rows from the surface down to each column's floor, left to right.
	var depths := PackedInt32Array()
	## Rows from the surface down to each column's first water cell: 0 for an open column, more under a ceiling.
	var tops := PackedInt32Array()
	## Rows from the surface down to the water at rest: 0 without reach, deepest() when all of it is reach (dry).
	var rest := 0
	## Whether Chuva raises it (a rain reach); false for water only a shell raises, or with no reach.
	var rains := false

	func width() -> int:
		return depths.size()

	func deepest() -> int:
		var most := 0
		for depth: int in depths:
			most = maxi(most, depth)
		return most

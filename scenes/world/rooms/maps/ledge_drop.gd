class_name LedgeDrop extends RefCounted

## Whether a body standing on a droppable ledge may drop through it; the game and the reach audit share this rule
## (architecture/drop-through-ledges).

## OPEN: nothing a body stands on (air, water, a secret). STOPS: ground, a ledge that is not droppable, off the map.
enum Cell { OPEN, DROPPABLE, STOPS }

## Rows under the ledge a body `body_height` px tall needs open, so it lands with its whole body below the ledge.
static func clearance_rows(body_height: float) -> int:
	return ceili(body_height / RoomMap.CELL_PX)

## `footing` is the cell under the feet in each column the body stands over; `below[i]` the rows under footing column
## i, nearest first. True when every footing cell is OPEN or DROPPABLE, one is DROPPABLE, and every row below is OPEN.
static func allows(footing: Array[Cell], below: Array[Array]) -> bool:
	if footing.is_empty() or not Cell.DROPPABLE in footing:
		return false
	for i: int in footing.size():
		if footing[i] == Cell.STOPS:
			return false
		for under: Cell in below[i]:
			if under != Cell.OPEN:
				return false
	return true

## allows() over columns `first`..`last` with the ledge at `row`; `classify` maps a Vector2i cell to a Cell.
static func allows_at(classify: Callable, first: int, last: int, row: int, body_height: float) -> bool:
	var footing: Array[Cell] = []
	var below: Array[Array] = []
	var rows := clearance_rows(body_height)
	for x: int in range(first, last + 1):
		footing.append(classify.call(Vector2i(x, row)) as Cell)
		var column: Array[Cell] = []
		for depth: int in range(1, rows + 1):
			column.append(classify.call(Vector2i(x, row + depth)) as Cell)
		below.append(column)
	return allows(footing, below)

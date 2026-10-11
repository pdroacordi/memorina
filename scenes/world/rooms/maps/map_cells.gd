class_name MapCells extends RefCounted

## Map cells a moving floor covers, for anything that reports its footprint on the room grid (RoomMap.CELL_PX).

## Support rows of a floor whose top moves between `top_a` and `top_b` px, over `left`..`right` px: the cell under each
## top line it passes, rounded to the nearest line.
static func floor_cells(left: float, right: float, top_a: float, top_b: float) -> Array[Vector2i]:
	var cell := float(RoomMap.CELL_PX)
	var cells: Array[Vector2i] = []
	var row_a := roundi(minf(top_a, top_b) / cell)
	var row_b := roundi(maxf(top_a, top_b) / cell)
	for x: int in range(floori(left / cell), ceili(right / cell)):
		for y: int in range(row_a, row_b + 1):
			cells.append(Vector2i(x, y))
	return cells

## The cells a rectangle in map px overlaps.
static func box_cells(rect: Rect2) -> Array[Vector2i]:
	var cell := float(RoomMap.CELL_PX)
	var cells: Array[Vector2i] = []
	for y: int in range(floori(rect.position.y / cell), ceili(rect.end.y / cell)):
		for x: int in range(floori(rect.position.x / cell), ceili(rect.end.x / cell)):
			cells.append(Vector2i(x, y))
	return cells

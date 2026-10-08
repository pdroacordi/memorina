class_name RootCatchFinder extends RefCounted

## Where roots can seize a thing hanging in a gap: the earth face beside it on each side (design 02 section 7.1, "em volta de um objeto que esteja no vão").

## The column of the first solid cell from `cell` going `direction` (-1 left, +1 right) within `max_cells`, or -1 when it is stone, missing or too far.
static func earth_face(map: RoomMap, cell: Vector2i, direction: int, max_cells: int) -> int:
	for step in range(0, max_cells + 1):
		var at := cell + Vector2i(direction * step, 0)
		var ground := map.ground_at(at)
		if ground == Enums.Ground.NONE:
			continue
		return at.x if ground == Enums.Ground.EARTH and not map.is_platform(at) else -1
	return -1

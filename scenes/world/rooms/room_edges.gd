class_name RoomEdges extends RefCounted

## Ivo never stands outside a room: walls on the boundary of the rooms plus a sky band over each open top run
## (systems/rooms "Edges", architecture/world-edges-from-the-room-list).

## Px of sky over an open top: RoomRing.WIDTH less GameCamera.subject_margin, so Ivo stays in frame (room_edges_test).
const CEILING_RISE := 152.0
## Px a wall slab reaches out from the allowed space.
const THICKNESS := 16.0

const _CELL := float(RoomMap.CELL_PX)


## 1 per column of `map`'s first row whose cell closes the sky: solid, one-way, roof or void. Air, water and a secret are open.
static func closed_top(map: RoomMap) -> PackedByteArray:
	var closed := PackedByteArray()
	closed.resize(map.size.x)
	for x: int in map.size.x:
		var cell := map.origin + Vector2i(x, 0)
		closed[x] = 1 if map.is_solid(cell) or map.is_platform(cell) or map.is_void(cell) else 0
	return closed

## A band CEILING_RISE px tall over each run of a room's open first-row columns that no other room lies above.
## `closed[i]` is `rooms[i]`'s closed_top(); a column it does not cover is closed.
static func bands(rooms: Array[Rect2], closed: Array[PackedByteArray]) -> Array[Rect2]:
	var found: Array[Rect2] = []
	for i: int in rooms.size():
		var room := rooms[i]
		var columns := roundi(room.size.x / _CELL)
		var run := -1
		for column: int in columns + 1:
			var open := column < columns and column < closed[i].size() and closed[i][column] == 0 \
				and not _under_another(rooms, i, Vector2(room.position.x + (column + 0.5) * _CELL, room.position.y - 1.0))
			if open and run < 0:
				run = column
			elif not open and run >= 0:
				found.append(Rect2(room.position.x + run * _CELL, room.position.y - CEILING_RISE, (column - run) * _CELL, CEILING_RISE))
				run = -1
	return found

## THICKNESS px slabs covering every point outside the rooms and bands within THICKNESS of them (corners included),
## merged; none overlaps a room or band.
static func walls(rooms: Array[Rect2], bands_found: Array[Rect2]) -> Array[Rect2]:
	var allowed: Array[Rect2] = rooms.duplicate()
	allowed.append_array(bands_found)
	var pieces: Array[Rect2] = []
	for rect: Rect2 in allowed:
		var t := THICKNESS
		var strips: Array[Rect2] = [
			Rect2(rect.position.x - t, rect.position.y - t, rect.size.x + 2.0 * t, t),
			Rect2(rect.position.x - t, rect.end.y, rect.size.x + 2.0 * t, t),
			Rect2(rect.position.x - t, rect.position.y, t, rect.size.y),
			Rect2(rect.end.x, rect.position.y, t, rect.size.y),
		]
		var near: Array[Rect2] = []
		var reach := rect.grow(t)
		for other: Rect2 in allowed:
			if reach.intersection(other).has_area():
				near.append(other)
		for strip: Rect2 in strips:
			pieces.append_array(_minus(strip, near))
	return _merge(pieces)

## Whether `point` lies in a room or a band.
static func allows(rooms: Array[Rect2], bands_found: Array[Rect2], point: Vector2) -> bool:
	for rect: Rect2 in rooms:
		if rect.has_point(point):
			return true
	for rect: Rect2 in bands_found:
		if rect.has_point(point):
			return true
	return false

## Each band's whole 32 px cells, world cells: the rows the reach audit opens over a top.
static func band_cells(bands_found: Array[Rect2]) -> Array[Rect2i]:
	var cells: Array[Rect2i] = []
	for band: Rect2 in bands_found:
		var from := Vector2i(ceili(band.position.x / _CELL), ceili(band.position.y / _CELL))
		var to := Vector2i(floori(band.end.x / _CELL), floori(band.end.y / _CELL))
		cells.append(Rect2i(from, to - from))
	return cells

static func _under_another(rooms: Array[Rect2], own: int, point: Vector2) -> bool:
	for j: int in rooms.size():
		if j != own and rooms[j].has_point(point):
			return true
	return false

# `piece` less every rect of `cuts` it overlaps with area; a touch on an edge cuts nothing
# (gotchas/rect2-intersects-is-false-for-rects-that-only-share-an-edge).
static func _minus(piece: Rect2, cuts: Array[Rect2]) -> Array[Rect2]:
	var left: Array[Rect2] = [piece]
	for cut: Rect2 in cuts:
		var next: Array[Rect2] = []
		for part: Rect2 in left:
			var shared := part.intersection(cut)
			if not shared.has_area():
				next.append(part)
				continue
			if shared.position.y > part.position.y:
				next.append(Rect2(part.position.x, part.position.y, part.size.x, shared.position.y - part.position.y))
			if shared.end.y < part.end.y:
				next.append(Rect2(part.position.x, shared.end.y, part.size.x, part.end.y - shared.end.y))
			if shared.position.x > part.position.x:
				next.append(Rect2(part.position.x, shared.position.y, shared.position.x - part.position.x, shared.size.y))
			if shared.end.x < part.end.x:
				next.append(Rect2(shared.end.x, shared.position.y, part.end.x - shared.end.x, shared.size.y))
		left = next
	return left

# Joins slabs that share a row band and touch or overlap along it, then the same by columns, until nothing joins.
static func _merge(pieces: Array[Rect2]) -> Array[Rect2]:
	var merged := pieces
	var count := -1
	while merged.size() != count:
		count = merged.size()
		merged = _merge_along(_merge_along(merged, true), false)
	return merged

static func _merge_along(pieces: Array[Rect2], horizontal: bool) -> Array[Rect2]:
	var lines: Dictionary[Vector2, Array] = {}
	for piece: Rect2 in pieces:
		var key := Vector2(piece.position.y, piece.size.y) if horizontal else Vector2(piece.position.x, piece.size.x)
		if not lines.has(key):
			lines[key] = []
		lines[key].append(piece)
	var joined: Array[Rect2] = []
	for key: Vector2 in lines:
		var line: Array = lines[key]
		line.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.x < b.position.x if horizontal else a.position.y < b.position.y)
		var current: Rect2 = line[0]
		for k: int in range(1, line.size()):
			var piece: Rect2 = line[k]
			var touches := piece.position.x <= current.end.x if horizontal else piece.position.y <= current.end.y
			if touches:
				current = current.merge(piece)
			else:
				joined.append(current)
				current = piece
		joined.append(current)
	return joined

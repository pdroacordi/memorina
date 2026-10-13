class_name BackdropSeams
extends RefCounted
## Where two rooms that draw different backdrop pictures meet: each such hard cut must touch an opaque cell, so it is hidden
## behind ground, a back wall, the void or a lake (systems/backdrops, architecture/backdrop-seams).

## Px per cell the check walks: the map grid.
const CELL := 32.0


## Every cell edge between two owners with different pictures where neither cell is opaque, merged into straight runs.
## `lattice` is the world px of cell (0, 0)'s corner; every room's rect lies on it.
static func cuts(rooms: Array[BackdropSeamRoom], lattice: Vector2) -> Array[BackdropCut]:
	var touching: Array = []
	for room: BackdropSeamRoom in rooms:
		var rects: Array[Rect2] = []
		for other: BackdropSeamRoom in rooms:
			if other != room and room.rect.grow(1.0).intersects(other.rect):
				rects.append(other.rect)
		touching.append(rects)
	var owner := {}
	var opaque := {}
	for i: int in rooms.size():
		var room := rooms[i]
		for cell: Vector2i in room.opaque:
			opaque[cell] = true
		var reach := RoomRing.reach(room.rect)
		var first := Vector2i(((reach.position - lattice) / CELL).floor())
		var last := Vector2i(((reach.end - lattice) / CELL).ceil())
		for y: int in range(first.y, last.y):
			for x: int in range(first.x, last.x):
				var cell := Vector2i(x, y)
				if owner.has(cell):
					continue
				if BackdropMath.keeps(_centre(cell, lattice), room.rect, touching[i], RoomRing.WIDTH):
					owner[cell] = i
	var runs := {}
	for cell: Vector2i in owner:
		for step: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
			var next := cell + step
			if not owner.has(next) or owner[next] == owner[cell] or opaque.has(cell) or opaque.has(next):
				continue
			var a := rooms[owner[cell]]
			var b := rooms[owner[next]]
			if BackdropMath.same_picture(_set_at(a, cell, lattice), a.anchor, _set_at(b, next, lattice), b.anchor):
				continue
			var in_rooms := a.rect.has_point(_centre(cell, lattice)) and b.rect.has_point(_centre(next, lattice))
			var vertical := step == Vector2i.RIGHT
			var across := 0 if vertical else 1
			var along := 1 - across
			var cut := BackdropCut.new(a.id, b.id, not in_rooms, vertical)
			cut.line = lattice[across] + float(next[across]) * CELL
			cut.from = lattice[along] + float(cell[along]) * CELL
			cut.to = cut.from + CELL
			var line_key := "%s %d %d %d" % ["|".join(cut.rooms), int(cut.in_ring), across, int(cut.line)]
			if not runs.has(line_key):
				runs[line_key] = []
			(runs[line_key] as Array).append(cut)
	var merged: Array[BackdropCut] = []
	for line_key: String in runs:
		var pieces: Array = runs[line_key]
		pieces.sort_custom(func(p: BackdropCut, q: BackdropCut) -> bool: return p.from < q.from)
		var run: BackdropCut = pieces[0]
		for k: int in range(1, pieces.size()):
			var piece: BackdropCut = pieces[k]
			if piece.from == run.to:
				run.to = piece.to
			else:
				merged.append(run)
				run = piece
		merged.append(run)
	return merged

# The set `room` draws at `cell`: its region's over its top, its own elsewhere (Backdrop.Part).
static func _set_at(room: BackdropSeamRoom, cell: Vector2i, lattice: Vector2) -> BackdropSet:
	return room.over_top if BackdropMath.over_top(_centre(cell, lattice), room.rect) else room.shown

static func _centre(cell: Vector2i, lattice: Vector2) -> Vector2:
	return lattice + (Vector2(cell) + Vector2(0.5, 0.5)) * CELL

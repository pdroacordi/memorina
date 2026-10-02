class_name RootSpanFinder extends RefCounted

## Finds earth-only root spans in map coordinates (docs/design/02 section 7.1).

enum Kind { BRIDGE, SHAFT, PILLAR }

static func find(map: RoomMap, max_bridge: int, max_shaft_width: int, min_shaft_rows: int, max_pillar: int) -> Array[Span]:
	var spans: Array[Span] = []
	spans.append_array(_bridges(map, max_bridge))
	spans.append_array(_shafts(map, max_shaft_width, min_shaft_rows))
	spans.append_array(_pillars(map, max_pillar))
	return spans

static func _earth(map: RoomMap, cell: Vector2i) -> bool:
	return map.contains(cell) and map.ground_at(cell) == Enums.Ground.EARTH

static func _solid(map: RoomMap, cell: Vector2i) -> bool:
	return map.contains(cell) and (map.is_solid(cell) or map.is_platform(cell))

## First solid cell right of `cell`, or the row's end.
static func _next_solid(map: RoomMap, cell: Vector2i) -> Vector2i:
	var x := cell.x + 1
	while x < map.origin.x + map.size.x and not _solid(map, Vector2i(x, cell.y)):
		x += 1
	return Vector2i(x, cell.y)

static func _bridges(map: RoomMap, max_gap: int) -> Array[Span]:
	var found: Array[Span] = []
	for y: int in range(map.origin.y, map.origin.y + map.size.y):
		for x: int in range(map.origin.x, map.origin.x + map.size.x):
			var a := Vector2i(x, y)
			if not _earth(map, a) or _solid(map, a + Vector2i.RIGHT) or _solid(map, a + Vector2i.UP):
				continue
			var b := _next_solid(map, a)
			var gap := b.x - a.x - 1
			if gap >= 1 and gap <= max_gap and _earth(map, b) and not _solid(map, b + Vector2i.UP):
				found.append(Span.new(Kind.BRIDGE, a, b, Vector2i(y, y)))
	return found

static func _shafts(map: RoomMap, max_width: int, min_rows: int) -> Array[Span]:
	# Facing wall pairs, row by row, keyed by their columns; runs of rows
	# become one shaft.
	var rows_by_pair := {}
	for y: int in range(map.origin.y, map.origin.y + map.size.y):
		for x: int in range(map.origin.x, map.origin.x + map.size.x):
			var a := Vector2i(x, y)
			if not _earth(map, a) or _solid(map, a + Vector2i.RIGHT):
				continue
			var b := _next_solid(map, a)
			var gap := b.x - a.x - 1
			if gap >= 1 and gap <= max_width and _earth(map, b):
				var key := Vector2i(a.x, b.x)
				if not rows_by_pair.has(key):
					rows_by_pair[key] = []
				(rows_by_pair[key] as Array).append(y)
	var found: Array[Span] = []
	for key: Vector2i in rows_by_pair:
		var rows: Array = rows_by_pair[key]
		var start: int = rows[0]
		var last: int = rows[0]
		for i: int in range(1, rows.size() + 1):
			var row: int = rows[i] if i < rows.size() else -99999
			if row == last + 1:
				last = row
				continue
			if last - start + 1 >= min_rows:
				found.append(Span.new(Kind.SHAFT, Vector2i(key.x, start), Vector2i(key.y, start), Vector2i(start, last)))
			start = row
			last = row
	return found

static func _pillars(map: RoomMap, max_height: int) -> Array[Span]:
	var found: Array[Span] = []
	for x: int in range(map.origin.x, map.origin.x + map.size.x):
		for y: int in range(map.origin.y, map.origin.y + map.size.y):
			var floor_cell := Vector2i(x, y)
			if not _earth(map, floor_cell) or _solid(map, floor_cell + Vector2i.UP):
				continue
			var c := y - 1
			while c >= map.origin.y and not _solid(map, Vector2i(x, c)):
				c -= 1
			var ceiling := Vector2i(x, c)
			var height := y - c - 1
			if c >= map.origin.y and height >= 1 and height <= max_height and _earth(map, ceiling):
				found.append(Span.new(Kind.PILLAR, floor_cell, ceiling, Vector2i(c, y)))
	return found

class Span:
	var kind: Kind
	## The two earth cells the roots grow from (a shaft: its walls at `rows.x`).
	var a := Vector2i.ZERO
	var b := Vector2i.ZERO
	## A shaft's first and last row; a bridge's row twice; a pillar's ceiling
	## and floor rows.
	var rows := Vector2i.ZERO

	func _init(p_kind: Kind, p_a: Vector2i, p_b: Vector2i, p_rows: Vector2i) -> void:
		kind = p_kind
		a = p_a
		b = p_b
		rows = p_rows

	## Cells of air the roots cross.
	func gap() -> int:
		return (a.y - b.y - 1) if kind == Kind.PILLAR else (b.x - a.x - 1)

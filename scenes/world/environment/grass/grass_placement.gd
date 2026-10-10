class_name GrassPlacement
extends RefCounted
## Where grass grows: every exposed top of a look that has grass, derived from the map when the room builds, never
## authored (architecture/generated-grass).


## The runs of `map`; `grows` answers whether a BiomeTileset.Look has grass.
static func runs(map: RoomMap, grows: Callable) -> Array[GrassRun]:
	var found: Array[GrassRun] = []
	var wet := _wet(map)
	for y: int in map.size.y:
		var start := -1
		for x: int in map.size.x + 1:
			var top := x < map.size.x and _is_top(map, x, y, wet, grows)
			if top and start >= 0 and map.looks[y * map.size.x + x] != map.looks[y * map.size.x + start]:
				found.append(_run(map, y, start, x - 1))
				start = -1
			if top and start < 0:
				start = x
			elif not top and start >= 0:
				found.append(_run(map, y, start, x - 1))
				start = -1
	return found

static func _is_top(map: RoomMap, x: int, y: int, wet: Dictionary[Vector2i, bool], grows: Callable) -> bool:
	var look := map.looks[y * map.size.x + x]
	# The top row's blades would stand above the room and be clipped away.
	if look == RoomMap.NO_LOOK or not grows.call(look) or y == 0:
		return false
	var above := map.origin + Vector2i(x, y - 1)
	# Grass under a secret would draw its front row over the closed wall (architecture/secret-false-walls).
	return map.looks[(y - 1) * map.size.x + x] == RoomMap.NO_LOOK and not wet.has(above) and map.secret_at(above) == 0

static func _run(map: RoomMap, y: int, from: int, to: int) -> GrassRun:
	var look := map.looks[y * map.size.x + from]
	return GrassRun.new(map.origin.y + y, map.origin.x + from, map.origin.x + to, look,
			_open(map, from - 1, y), _open(map, to + 1, y))

# Open where air is beside the run; the map edge, ground and a secret are closed, so the gap is exactly a secret's width.
static func _open(map: RoomMap, x: int, y: int) -> bool:
	if x < 0 or x >= map.size.x:
		return false
	return map.looks[y * map.size.x + x] == RoomMap.NO_LOOK and map.secret_at(map.origin + Vector2i(x, y)) == 0

static func _wet(map: RoomMap) -> Dictionary[Vector2i, bool]:
	var wet: Dictionary[Vector2i, bool] = {}
	for kind: Dictionary in [map.water, map.reach, map.shell_reach]:
		for symbol: String in kind:
			for cell: Vector2 in kind[symbol]:
				wet[Vector2i(cell)] = true
	return wet

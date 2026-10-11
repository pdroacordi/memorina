class_name RoomTileResolver
extends RefCounted
## Resolves a room's dual-grid display tiles per look, and its ledge pieces, at import (architecture/biome-tilesets).


## Fills `map`'s ground, back, ledge and secret layers from its looks, back walls, platforms and secrets.
static func resolve(map: RoomMap) -> void:
	var looks := void_filled(map)
	map.ground_layers = _layers(map, looks, true)
	_clear_void_tiles(map, map.ground_layers)
	map.back_layers = _layers(map, map.back, false)
	map.ledge_layers = _ledges(map)
	map.secret_layers = _secret_layers(map, looks)

## The room's looks with each void cell given its nearest drawn ground cell's look (4-neighbour search, ties west,
## east, north, south), so a wall's tiles toward the void are fill and the void's mask cuts them on the cell line
## (architecture/room-void-outside-the-shell).
static func void_filled(map: RoomMap) -> PackedByteArray:
	if map.void_cells.is_empty():
		return map.looks
	var looks := map.looks.duplicate()
	var queue: Array[Vector2i] = []
	for y: int in map.size.y:
		for x: int in map.size.x:
			var index := y * map.size.x + x
			if map.void_cells[index] == 0 and looks[index] != RoomMap.NO_LOOK and map.platform[index] == 0:
				queue.append(Vector2i(x, y))
	var next := 0
	while next < queue.size():
		var cell := queue[next]
		next += 1
		var look := looks[cell.y * map.size.x + cell.x]
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbour := cell + step
			if neighbour.x < 0 or neighbour.y < 0 or neighbour.x >= map.size.x or neighbour.y >= map.size.y:
				continue
			var index := neighbour.y * map.size.x + neighbour.x
			if map.void_cells[index] == 1 and looks[index] == RoomMap.NO_LOOK:
				looks[index] = look
				queue.append(neighbour)
	return looks

## Clears every display tile whose four corners are void, in every layer.
static func _clear_void_tiles(map: RoomMap, layers: Dictionary[int, PackedByteArray]) -> void:
	if map.void_cells.is_empty():
		return
	var display := map.display_size()
	for j: int in display.y:
		for i: int in display.x:
			if not (_void(map, i - 1, j - 1) and _void(map, i, j - 1) and _void(map, i - 1, j) and _void(map, i, j)):
				continue
			for look: int in layers:
				var layer: PackedByteArray = layers[look]
				layer[j * display.x + i] = 0
				layers[look] = layer

## Whether local cell (x, y) is void, sampled as `_look` samples: x clamps in, rows below repeat the bottom row, rows
## above are air.
static func _void(map: RoomMap, x: int, y: int) -> bool:
	if y < 0:
		return false
	return map.void_cells[mini(y, map.size.y - 1) * map.size.x + clampi(x, 0, map.size.x - 1)] == 1

## The tiles a closed secret draws: the room resolved with its secret cells filled in, kept only in display tiles with a
## secret corner, so its edges meet the real ground exactly (architecture/secret-false-walls).
static func _secret_layers(map: RoomMap, looks: PackedByteArray) -> Dictionary[int, PackedByteArray]:
	var layers: Dictionary[int, PackedByteArray] = {}
	if map.secret_looks.is_empty():
		return layers
	var filled := looks.duplicate()
	for index: int in filled.size():
		if map.secret_looks[index] != RoomMap.NO_LOOK:
			filled[index] = map.secret_looks[index]
	var full := _layers(map, filled, true)
	var display := map.display_size()
	for look: int in full:
		var layer: PackedByteArray = full[look]
		var owned := PackedByteArray()
		owned.resize(layer.size())
		var any := false
		for j: int in display.y:
			for i: int in display.x:
				if map.secret_owning(Vector2i(i, j)) > 0:
					owned[j * display.x + i] = layer[j * display.x + i]
					any = any or layer[j * display.x + i] != 0
		if any:
			layers[look] = owned
	return layers

## Look -> one byte per display cell: mask | variant << 4.
static func _layers(map: RoomMap, looks: PackedByteArray, skip_platforms: bool) -> Dictionary[int, PackedByteArray]:
	var layers: Dictionary[int, PackedByteArray] = {}
	if looks.is_empty():
		return layers
	var present: Array[int] = []
	for index: int in looks.size():
		var look := looks[index]
		if look != RoomMap.NO_LOOK and not (skip_platforms and map.platform[index] == 1) and not look in present:
			present.append(look)
	# Look order is draw order: a later look's layer goes over an earlier one's.
	present.sort()
	var display := map.display_size()
	for look: int in present:
		var layer := PackedByteArray()
		layer.resize(display.x * display.y)
		for j: int in display.y:
			for i: int in display.x:
				var corners := PackedInt32Array([
					_look(map, looks, i - 1, j - 1, skip_platforms), _look(map, looks, i, j - 1, skip_platforms),
					_look(map, looks, i - 1, j, skip_platforms), _look(map, looks, i, j, skip_platforms),
				])
				var mask := GroundAutotile.corner_mask(corners, look)
				var cell := map.origin + Vector2i(i, j)
				var variant := 0
				if mask == GroundAutotile.FULL:
					variant = GroundAutotile.fill_variant(cell)
				elif GroundAutotile.takes_variant(mask):
					variant = GroundAutotile.edge_variant(cell)
				layer[j * display.x + i] = mask | (variant << 4)
		layers[look] = layer
	return layers

## The look at local cell (x, y), -1 for air. Out of the map: x clamps in, rows below repeat the bottom row, rows above are air.
static func _look(map: RoomMap, looks: PackedByteArray, x: int, y: int, skip_platforms: bool) -> int:
	if y < 0:
		return -1
	var index := mini(y, map.size.y - 1) * map.size.x + clampi(x, 0, map.size.x - 1)
	if skip_platforms and map.platform[index] == 1:
		return -1
	var look := looks[index]
	return -1 if look == RoomMap.NO_LOOK else look

## Look -> one byte per cell: ledge piece + 1, 0 where the cell is no ledge.
static func _ledges(map: RoomMap) -> Dictionary[int, PackedByteArray]:
	var layers: Dictionary[int, PackedByteArray] = {}
	for y: int in map.size.y:
		for x: int in map.size.x:
			var index := y * map.size.x + x
			# A roof has no look: its facade draws it.
			if map.platform[index] != 1 or map.looks[index] == RoomMap.NO_LOOK:
				continue
			var look := map.looks[index]
			if not layers.has(look):
				var fresh := PackedByteArray()
				fresh.resize(map.size.x * map.size.y)
				layers[look] = fresh
			var west := x > 0 and map.platform[index - 1] == 1 and map.looks[index - 1] == look
			var east := x < map.size.x - 1 and map.platform[index + 1] == 1 and map.looks[index + 1] == look
			var layer: PackedByteArray = layers[look]
			layer[index] = GroundAutotile.ledge_coords(west, east).x + 1
			layers[look] = layer
	return layers

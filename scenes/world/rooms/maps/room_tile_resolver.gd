class_name RoomTileResolver
extends RefCounted
## Resolves a room's dual-grid display tiles per look, and its ledge pieces, at import (architecture/biome-tilesets).


## Fills `map`'s ground, back, ledge and secret layers from its looks, back walls, platforms and secrets.
static func resolve(map: RoomMap) -> void:
	map.ground_layers = _layers(map, map.looks, true)
	map.back_layers = _layers(map, map.back, false)
	map.ledge_layers = _ledges(map)
	map.secret_layers = _secret_layers(map)

## The tiles a closed secret draws: the room resolved with its secret cells filled in, kept only in display tiles with a
## secret corner, so its edges meet the real ground exactly (architecture/secret-false-walls).
static func _secret_layers(map: RoomMap) -> Dictionary[int, PackedByteArray]:
	var layers: Dictionary[int, PackedByteArray] = {}
	if map.secret_looks.is_empty():
		return layers
	var filled := map.looks.duplicate()
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
			if map.platform[index] != 1:
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

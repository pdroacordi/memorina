class_name RoomTileResolver
extends RefCounted
## Resolves a room's dual-grid display tiles per look, and its ledge pieces, at import (architecture/biome-tilesets).


## Fills `map`'s ground, back and ledge layers from its looks, back walls and platforms.
static func resolve(map: RoomMap) -> void:
	map.ground_layers = _layers(map, map.looks, true)
	map.back_layers = _layers(map, map.back, false)
	map.ledge_layers = _ledges(map)

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
				var variant := GroundAutotile.fill_variant(map.origin + Vector2i(i, j)) if mask == GroundAutotile.FULL else 0
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

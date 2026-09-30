@tool
class_name RoomMap extends Resource

## A room's ground, water and placed things, as parsed from its `.room` text
## file at import (addons/room_maps). Everything here is already resolved -
## the tile each ground cell draws with included - so building a room is one
## set_cell per cell and nothing is parsed at runtime.
##
## Cells are in the room's TILE coordinates: the text's top-left character is
## `origin`.

## A tile no cell uses.
const NO_TILE := -1

@export var legend: RoomLegend
@export var origin := Vector2i.ZERO
@export var size := Vector2i.ZERO
## The text rows, kept for error messages and the map guide's examples.
@export var rows := PackedStringArray()
## Enums.Ground per cell, row-major. Platforms are their material too.
@export var ground := PackedByteArray()
## 1 where the cell is a one-way platform.
@export var platform := PackedByteArray()
## The resolved atlas tile per cell, packed by pack_tile(); NO_TILE if empty.
@export var tiles := PackedInt32Array()
## Water cells by legend symbol: symbol -> PackedVector2Array of cells.
@export var water := {}
## One per placed thing: {"symbol": String, "cell": Vector2i, "params": Dictionary}.
@export var entities: Array[Dictionary] = []

static func pack_tile(coords: Vector2i, alternative: int) -> int:
	return coords.x | (coords.y << 8) | (alternative << 16)

static func tile_coords(packed: int) -> Vector2i:
	return Vector2i(packed & 0xff, (packed >> 8) & 0xff)

static func tile_alternative(packed: int) -> int:
	return (packed >> 16) & 0xff

func contains(cell: Vector2i) -> bool:
	var local := cell - origin
	return local.x >= 0 and local.y >= 0 and local.x < size.x and local.y < size.y

func ground_at(cell: Vector2i) -> Enums.Ground:
	if not contains(cell):
		return Enums.Ground.NONE
	return ground[_index(cell)] as Enums.Ground

func is_solid(cell: Vector2i) -> bool:
	return ground_at(cell) != Enums.Ground.NONE and not is_platform(cell)

func is_platform(cell: Vector2i) -> bool:
	return contains(cell) and platform[_index(cell)] == 1

func tile_at(cell: Vector2i) -> int:
	return tiles[_index(cell)] if contains(cell) else NO_TILE

func _index(cell: Vector2i) -> int:
	var local := cell - origin
	return local.y * size.x + local.x

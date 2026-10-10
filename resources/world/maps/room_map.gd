@tool
class_name RoomMap extends Resource

## Imported room data with its dual-grid tiles resolved; cells use tile coordinates from `origin` (architecture/biome-tilesets).

## Px per map cell.
const CELL_PX := 32
## A cell with no look: air.
const NO_LOOK := 255

@export var legend: RoomLegend
@export var origin := Vector2i.ZERO
@export var size := Vector2i.ZERO
## The text rows, kept for error messages and the map guide's examples.
@export var rows := PackedStringArray()
## The `[back]` rows, empty when the room has none.
@export var back_rows := PackedStringArray()
## The `tileset =` id, and the biome it names.
@export var tileset := ""
@export var biome: BiomeTileset
## Enums.Ground per cell, row-major. Platforms are their material too.
@export var ground := PackedByteArray()
## 1 where the cell is a one-way platform.
@export var platform := PackedByteArray()
## BiomeTileset.Look per cell (NO_LOOK for air), platforms included.
@export var looks := PackedByteArray()
## BiomeTileset.Look of the back wall per cell (NO_LOOK for none); empty when the room has no `[back]`.
@export var back := PackedByteArray()
## Look -> one byte per display cell (display_size()): solid-corner mask | variant << 4 (GroundAutotile.takes_variant).
@export var ground_layers: Dictionary[int, PackedByteArray] = {}
@export var back_layers: Dictionary[int, PackedByteArray] = {}
## Look -> one byte per cell: ledge piece + 1, 0 for none.
@export var ledge_layers: Dictionary[int, PackedByteArray] = {}
## Water cells by legend symbol: symbol -> PackedVector2Array of cells.
@export var water: Dictionary[String, PackedVector2Array] = {}
## Reach cells by the symbol of the water they raise (their own symbol when they stand alone).
@export var reach: Dictionary[String, PackedVector2Array] = {}
## Shell reach cells (room map `u`) by the symbol of the water a Redoma shell raises to them.
@export var shell_reach: Dictionary[String, PackedVector2Array] = {}
## One per placed thing: {"symbol": String, "cell": Vector2i, "params": Dictionary}.
@export var entities: Array[Dictionary] = []

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

## The dual grid is one cell larger than the map each way: a display cell sits on each cell corner.
func display_size() -> Vector2i:
	return size + Vector2i.ONE

func _index(cell: Vector2i) -> int:
	var local := cell - origin
	return local.y * size.x + local.x

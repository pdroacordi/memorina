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
## The text rows: error messages, the map guide's examples, and a cell's legend entry (is_droppable, ReachGrid).
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
## The `[secret]` rows, empty when the room has none.
@export var secret_rows := PackedStringArray()
## BiomeTileset.Look a secret cell is drawn as (NO_LOOK elsewhere); empty without `[secret]`. `looks` and `ground` stay air there.
@export var secret_looks := PackedByteArray()
## Per cell: the secret group's index + 1, 0 outside a secret; groups are 8-connected.
@export var secret_groups := PackedByteArray()
## Per cell: 1 where the secret cell draws the biome's crack.
@export var secret_cracks := PackedByteArray()
## Per group: `<room file>@x,y`, the key `found_secrets` remembers.
@export var secret_ids := PackedStringArray()
## Look -> one byte per display cell, as `ground_layers`, for the display tiles a secret owns (0 elsewhere).
@export var secret_layers: Dictionary[int, PackedByteArray] = {}
## Per cell: 1 where the cell is void, outside the room's shell; empty when the room has none.
@export var void_cells := PackedByteArray()
## One per placed thing: {"symbol": String, "cell": Vector2i, "params": Dictionary}.
@export var entities: Array[Dictionary] = []

func contains(cell: Vector2i) -> bool:
	var local := cell - origin
	return local.x >= 0 and local.y >= 0 and local.x < size.x and local.y < size.y

func ground_at(cell: Vector2i) -> Enums.Ground:
	if not contains(cell):
		return Enums.Ground.NONE
	return ground[_index(cell)] as Enums.Ground

## BiomeTileset.Look at `cell`, or NO_LOOK for air and off the map.
func look_at(cell: Vector2i) -> int:
	return looks[_index(cell)] if contains(cell) and not looks.is_empty() else NO_LOOK

func is_solid(cell: Vector2i) -> bool:
	return ground_at(cell) != Enums.Ground.NONE and not is_platform(cell)

## The secret group index + 1 at `cell`, 0 for none.
func secret_at(cell: Vector2i) -> int:
	return secret_groups[_index(cell)] if contains(cell) and not secret_groups.is_empty() else 0

## The secret group index + 1 owning display cell `display` (corner cells display - (1,1) .. display), 0 for none.
func secret_owning(display: Vector2i) -> int:
	for corner: Vector2i in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i.ZERO]:
		var group := secret_at(origin + display + corner)
		if group > 0:
			return group
	return 0

## Whether `cell` is void: solid to gameplay, drawn black.
func is_void(cell: Vector2i) -> bool:
	return contains(cell) and not void_cells.is_empty() and void_cells[_index(cell)] == 1

func is_platform(cell: Vector2i) -> bool:
	return contains(cell) and platform[_index(cell)] == 1

## Whether `cell` is a ledge whose legend entry is droppable (architecture/drop-through-ledges).
func is_droppable(cell: Vector2i) -> bool:
	if not is_platform(cell):
		return false
	var local := cell - origin
	var entry := legend.entry(rows[local.y][local.x])
	return entry != null and entry.droppable

## `cell` as LedgeDrop sees it; must classify like ReachGrid.drop_cell.
func drop_cell(cell: Vector2i) -> LedgeDrop.Cell:
	if not contains(cell) or is_solid(cell):
		return LedgeDrop.Cell.STOPS
	if is_platform(cell):
		return LedgeDrop.Cell.DROPPABLE if is_droppable(cell) else LedgeDrop.Cell.STOPS
	return LedgeDrop.Cell.OPEN

## The dual grid is one cell larger than the map each way: a display cell sits on each cell corner.
func display_size() -> Vector2i:
	return size + Vector2i.ONE

func _index(cell: Vector2i) -> int:
	var local := cell - origin
	return local.y * size.x + local.x

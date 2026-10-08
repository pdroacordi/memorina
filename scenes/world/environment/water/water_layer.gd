class_name WaterLayer extends TileMapLayer

## Converts painted water cells into runtime water bodies.

## Tile alternative that paints a reach: where Chuva raises the water, not water at rest.
const REACH_ALTERNATIVE := 1
## Tile alternative that paints a shell reach: where Redoma's displaced water rises, never the rain.
const SHELL_REACH_ALTERNATIVE := 2

## Scene instantiated for each basin; its root or `Water` child must be a WaterBody.
@export var body_scene: PackedScene
## Scene for a basin painted with a reach above its rest (a RainBasin); null when this kind never rises.
@export var rising_body_scene: PackedScene
## Dry gap from painted top to waterline, in world pixels.
@export var surface_inset := 8

# A body scene may be a WaterBody or contain one as its `Water` child.
static func _water_body_of(instance: Node) -> WaterBody:
	if instance is WaterBody:
		return instance
	var water := instance.get_node_or_null("Water") as WaterBody
	assert(water != null, "%s is neither a WaterBody nor holds one as Water" % instance.name)
	return water

func _ready() -> void:
	assert(body_scene != null, "%s needs a body_scene" % name)
	assert(tile_set != null, "%s needs the water tile set" % name)
	assert(surface_inset >= 0 and surface_inset < tile_set.tile_size.y,
		"%s: the waterline must sit inside the top row of cells" % name)
	enabled = false
	var cells: Array[Vector2i] = []
	var reach: Array[Vector2i] = []
	var shell_reach: Array[Vector2i] = []
	for cell: Vector2i in get_used_cells():
		match get_cell_alternative_tile(cell):
			REACH_ALTERNATIVE:
				reach.append(cell)
			SHELL_REACH_ALTERNATIVE:
				shell_reach.append(cell)
			_:
				cells.append(cell)
	var basins := WaterBasins.build(cells, reach, shell_reach)
	for cell: Vector2i in basins.unreachable:
		push_warning("%s: water painted at %s is not below its basin's surface (under terrain, or a side arm) and is not drawn" % [get_path(), cell])
	for basin: WaterBasins.Basin in basins.basins:
		add_child(_pour(basin))

func _pour(basin: WaterBasins.Basin) -> Node2D:
	var cell := Vector2(tile_set.tile_size)
	var rising := basin.rest > 0 and basin.rains
	assert(not rising or rising_body_scene != null, "%s: a reach is painted but this water never rises" % name)
	var instance := (rising_body_scene if rising else body_scene).instantiate() as Node2D
	var body := _water_body_of(instance)
	body.rest_depth = basin.rest * cell.y
	body.displaces = basin.rest > 0 and not basin.rains
	# Each water column must fit within one cell to preserve its floor depth.
	assert(tile_set.tile_size.x % body.column_width() == 0,
		"%s: a water column (%d px) must divide a cell (%d px)" % [name, body.column_width(), tile_set.tile_size.x])
	# Set size before entering the tree because WaterBody sizes its children in _ready.
	body.size = Vector2i(roundi(basin.width() * cell.x), roundi(basin.deepest() * cell.y) - surface_inset)
	var floors := PackedFloat32Array()
	for depth: int in basin.depths:
		floors.append(depth * cell.y - surface_inset)
	body.set_floor(cell.x, floors)
	body.mirror_axis_offset = -floori(surface_inset / 2.0)
	# Place the body origin at the waterline center.
	instance.position = Vector2(
		(basin.left + basin.width() * 0.5) * cell.x,
		basin.surface * cell.y + surface_inset)
	return instance

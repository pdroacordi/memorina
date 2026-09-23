class_name WaterLayer extends TileMapLayer

## Water painted into a level. Paint cells where the water is - into a pit for
## a pool, over the ground and down to the room's bottom for a lake in front of
## it - and at runtime every basin the cells describe (WaterBasins) becomes one
## instance of `body_scene`, sized, placed and given the basin's stepped floor.
##
## The painted cells are also the editor preview: water only exists at runtime
## (its shaders are fed by the running body), so the swatch is what a level
## designer lines up against the terrain. At runtime the layer draws nothing.
##
## One layer is one kind of water: a pool, a freezable pool and a lake are three
## presets of this script (water_pool_layer.tscn, freezable_water_layer.tscn,
## water_lake_layer.tscn) differing only in `body_scene` and their numbers.

## What each basin becomes: a scene whose root is a WaterBody, or which holds
## one as its `Water` child.
@export var body_scene: PackedScene
## World pixels from the top of the painted cells down to the waterline: the
## bank's lip that stays dry above the water. The mirror axis follows it
## (WaterBody.mirror_axis_offset = -inset / 2), so the reflection starts at the
## top of the bank whatever the inset.
@export var surface_inset := 8

# The WaterBody inside an instance of a body scene. A different kind of water
# is a new preset with its own body scene, never an override here: a profile
# set on a lake would turn it into a simulation its shader cannot read.
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
	var basins := WaterBasins.build(get_used_cells())
	for cell: Vector2i in basins.unreachable:
		push_warning("%s: water painted at %s is not below its basin's surface (under terrain, or a side arm) and is not drawn" % [get_path(), cell])
	for basin: WaterBasins.Basin in basins.basins:
		add_child(_pour(basin))

func _pour(basin: WaterBasins.Basin) -> Node2D:
	var cell := Vector2(tile_set.tile_size)
	var instance := body_scene.instantiate() as Node2D
	var body := _water_body_of(instance)
	# A column straddling two cells would take one depth and draw into the bank.
	assert(tile_set.tile_size.x % body.column_width() == 0,
		"%s: a water column (%d px) must divide a cell (%d px)" % [name, body.column_width(), tile_set.tile_size.x])
	# Before entering the tree: the body sizes everything it owns in _ready.
	body.size = Vector2i(roundi(basin.width() * cell.x), roundi(basin.deepest() * cell.y) - surface_inset)
	var floors := PackedFloat32Array()
	for depth: int in basin.depths:
		floors.append(depth * cell.y - surface_inset)
	body.set_floor(cell.x, floors)
	body.mirror_axis_offset = -floori(surface_inset / 2.0)
	# The body's origin is the centre of its waterline.
	instance.position = Vector2(
		(basin.left + basin.width() * 0.5) * cell.x,
		basin.surface * cell.y + surface_inset)
	return instance

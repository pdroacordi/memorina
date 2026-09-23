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
## bank's lip that stays dry above the water.
@export var surface_inset := 4
## Passed to every body (WaterBody.mirror_axis_offset).
@export var mirror_axis_offset := 0
## Optional overrides of the scene's own motion and look.
@export var profile: WaterProfile
@export var look: WaterLook

func _ready() -> void:
	assert(body_scene != null, "%s needs a body_scene" % name)
	assert(tile_set != null, "%s needs the water tile set" % name)
	enabled = false
	var basins := WaterBasins.build(get_used_cells())
	for cell: Vector2i in basins.unreachable:
		push_warning("%s: water painted at %s is under no surface (a pocket under terrain) and is not drawn" % [get_path(), cell])
	for basin: WaterBasins.Basin in basins.basins:
		add_child(_pour(basin))

## The WaterBody inside an instance of a body scene.
static func water_body_of(instance: Node) -> WaterBody:
	if instance is WaterBody:
		return instance
	var water := instance.get_node_or_null("Water") as WaterBody
	assert(water != null, "%s is neither a WaterBody nor holds one as Water" % instance.name)
	return water

func _pour(basin: WaterBasins.Basin) -> Node2D:
	var cell := Vector2(tile_set.tile_size)
	var instance := body_scene.instantiate() as Node2D
	var body := water_body_of(instance)
	# Before entering the tree: the body sizes everything it owns in _ready.
	body.size = Vector2i(roundi(basin.width() * cell.x), roundi(basin.deepest() * cell.y) - surface_inset)
	var floors := PackedFloat32Array()
	for depth: int in basin.depths:
		floors.append(depth * cell.y - surface_inset)
	body.set_floor(cell.x, floors)
	body.mirror_axis_offset = mirror_axis_offset
	if profile:
		body.profile = profile
	if look:
		body.look = look
	# The body's origin is the centre of its waterline.
	instance.position = Vector2(
		(basin.left + basin.width() * 0.5) * cell.x,
		basin.surface * cell.y + surface_inset)
	return instance

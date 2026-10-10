@tool
class_name RoomMapNode extends Node2D

## Builds room ground, back walls, water and entities from `.room` data (docs/maps/README.md, architecture/biome-tilesets).

const GROUP := &"room_map"
## The node every placed entity is a child of.
const ENTITIES := &"Entities"
const GROUND_MATERIAL := preload("res://scenes/world/memory/seasonal/floor_tiles_seasonal_material.tres")
const BACK_MATERIAL := preload("res://scenes/world/memory/seasonal/back_tiles_seasonal_material.tres")
## Behind props (-10) and in front of the Backdrop (-30) (architecture/props-and-ambient-life).
const BACK_Z := -20

## The imported `.room` file.
@export var map: RoomMap:
	set(value):
		map = value
		if is_inside_tree():
			_build()

## Cell-aligned, hidden, and the only collision: the art is offset half a cell on the dual grid.
var _solid: TileMapLayer

## Loaded visible room map containing `global_point`, or null if none does.
static func at(node: Node, global_point: Vector2) -> RoomMapNode:
	for member: Node in node.get_tree().get_nodes_in_group(GROUP):
		var room := member as RoomMapNode
		if room and room.is_visible_in_tree() and room.map and room.map.contains(room.cell_at(global_point)):
			return room
	return null

func _ready() -> void:
	add_to_group(GROUP)
	_build()

func cell_at(global_point: Vector2) -> Vector2i:
	return _solid.local_to_map(_solid.to_local(global_point)) if _solid else Vector2i.ZERO

## Ground type at `global_point`, or NONE off-map/in air; water does not change the ground type.
func ground_at(global_point: Vector2) -> Enums.Ground:
	return map.ground_at(cell_at(global_point)) if map else Enums.Ground.NONE

## The world rectangle of `cell`, for anything that must line up with the grid.
func cell_rect(cell: Vector2i) -> Rect2:
	var size := Vector2(RoomMap.CELL_PX, RoomMap.CELL_PX)
	return Rect2(_solid.to_global(_solid.map_to_local(cell) - size * 0.5), size)

func _build() -> void:
	# Remove immediately so newly built entities can reuse IDs before queued nodes are freed.
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_solid = null
	if map == null:
		return
	if map.biome != null:
		var ground_material := _clipped(GROUND_MATERIAL)
		var back_material := _clipped(BACK_MATERIAL)
		# Sorted: look order is draw order, so a later look's layer is added over an earlier one's.
		for look: int in _sorted(map.back_layers):
			_adopt(_display_layer("Back_%s" % _look_name(look), look, map.back_layers[look], back_material, BACK_Z))
		for look: int in _sorted(map.ground_layers):
			_adopt(_display_layer("Ground_%s" % _look_name(look), look, map.ground_layers[look], ground_material, 0))
		if not map.ledge_layers.is_empty():
			_adopt(_ledge_layer())
	_solid = _solid_layer()
	_adopt(_solid)
	var symbols: Array[String] = map.water.keys()
	for symbol: String in map.reach.keys() + map.shell_reach.keys():
		if not symbol in symbols:
			symbols.append(symbol)
	for symbol: String in symbols:
		_pour(map.legend.entry(symbol), map.water.get(symbol, PackedVector2Array()), map.reach.get(symbol, PackedVector2Array()), map.shell_reach.get(symbol, PackedVector2Array()))
	var entities := Node2D.new()
	entities.name = ENTITIES
	# Add the complete entity set together so links resolve regardless of map order.
	for placed: Dictionary in map.entities:
		_place(map.legend.entry(placed.symbol), placed, entities)
	_adopt(entities)

## One look's dual-grid tiles, half a cell up and left, so each display cell sits on a cell corner.
func _display_layer(layer_name: String, look: int, cells: PackedByteArray, material_used: Material, z: int) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = map.biome.tile_set()
	layer.material = material_used
	layer.z_index = z
	layer.position = -Vector2(RoomMap.CELL_PX, RoomMap.CELL_PX) * 0.5
	var display := map.display_size()
	var variants := map.biome.variants(look)
	for j: int in display.y:
		for i: int in display.x:
			var packed := cells[j * display.x + i]
			var mask := packed & 0xf
			if mask == 0:
				continue
			var variant := packed >> 4
			var coords := GroundAutotile.variant_coords(variant) if variant > 0 and variant <= variants else GroundAutotile.wang_coords(mask)
			layer.set_cell(map.origin + Vector2i(i, j), look, coords)
	return layer

## One-way ledges, cell-aligned, every look in one layer (source id = look).
func _ledge_layer() -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = "Ledges"
	layer.tile_set = map.biome.tile_set()
	layer.material = GROUND_MATERIAL
	for look: int in map.ledge_layers:
		var cells: PackedByteArray = map.ledge_layers[look]
		for y: int in map.size.y:
			for x: int in map.size.x:
				var piece := cells[y * map.size.x + x]
				if piece > 0:
					layer.set_cell(map.origin + Vector2i(x, y), look, Vector2i(piece - 1, GroundAutotile.LEDGE_ROW))
	return layer

## Hidden by `visible`, never `enabled`, which would also stop its collision (gotchas/tilemaplayer-enabled-does-not-hide-children).
func _solid_layer() -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = "Solid"
	layer.tile_set = GroundCollision.tile_set()
	layer.visible = false
	for y: int in map.size.y:
		for x: int in map.size.x:
			var cell := map.origin + Vector2i(x, y)
			var ground := map.ground_at(cell)
			if ground != Enums.Ground.NONE:
				layer.set_cell(cell, GroundCollision.SOURCE_ID, GroundCollision.coords(ground), GroundCollision.ONE_WAY if map.is_platform(cell) else 0)
	return layer

## `base` limited to the map's world rect: the dual grid draws half a tile past every edge, and the rooms beside run.
func _clipped(base: ShaderMaterial) -> ShaderMaterial:
	var clipped := base.duplicate() as ShaderMaterial
	var top_left := to_global(Vector2(map.origin * RoomMap.CELL_PX))
	var size := Vector2(map.size * RoomMap.CELL_PX) * global_scale
	clipped.set_shader_parameter(&"clip_rect", Vector4(top_left.x, top_left.y, size.x, size.y))
	return clipped

func _sorted(layers: Dictionary) -> Array[int]:
	var looks: Array[int] = []
	looks.assign(layers.keys())
	looks.sort()
	return looks

func _look_name(look: int) -> String:
	return BiomeTileset.Look.keys()[look].capitalize()

## Paint finer water cells before adding the layer, because its `_ready` creates bodies.
func _pour(entry: RoomLegendEntry, cells: PackedVector2Array, reach: PackedVector2Array, shell_reach: PackedVector2Array) -> void:
	var layer := entry.water_layer.instantiate() as WaterLayer
	assert(layer != null, "legend '%s': water_layer must be a WaterLayer preset" % entry.symbol)
	_paint(layer, cells, 0)
	_paint(layer, reach, WaterLayer.REACH_ALTERNATIVE)
	_paint(layer, shell_reach, WaterLayer.SHELL_REACH_ALTERNATIVE)
	layer.name = "Water_%s" % entry.symbol.uri_encode()
	_adopt(layer)

## Paints each map cell as the water layer's finer cells, with tile `alternative`.
func _paint(layer: WaterLayer, cells: PackedVector2Array, alternative: int) -> void:
	var ratio := Vector2i(RoomMap.CELL_PX, RoomMap.CELL_PX) / Vector2i(layer.tile_set.tile_size)
	for cell: Vector2 in cells:
		for dy: int in ratio.y:
			for dx: int in ratio.x:
				layer.set_cell(Vector2i(cell) * ratio + Vector2i(dx, dy), 0, Vector2i.ZERO, alternative)

func _place(entry: RoomLegendEntry, placed: Dictionary, entities: Node2D) -> void:
	var node := entry.scene.instantiate() as Node2D
	assert(node != null, "legend '%s': an entity scene's root must be a Node2D" % entry.symbol)
	var size := Vector2(RoomMap.CELL_PX, RoomMap.CELL_PX)
	var rect := Rect2(_solid.map_to_local(placed.cell) - size * 0.5, size)
	node.position = Vector2(rect.get_center().x, rect.end.y) if entry.anchor == RoomLegendEntry.Anchor.FEET else rect.get_center()
	node.name = "%s_%d_%d" % [entry.symbol.uri_encode(), placed.cell.x, placed.cell.y]
	EntityParams.apply(node, placed.params)
	entities.add_child(node)

func _adopt(node: Node) -> void:
	add_child(node)

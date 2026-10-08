@tool
class_name RoomMapNode extends Node2D

## Builds room ground, water and entities from `.room` data (docs/maps/README.md).

const GROUP := &"room_map"
## The node every placed entity is a child of.
const ENTITIES := &"Entities"
const FLOOR_TILESET := preload("res://resources/world/tiles/floor_tileset.tres")

## The imported `.room` file.
@export var map: RoomMap:
	set(value):
		map = value
		if is_inside_tree():
			_build()
## Seasonal material used to draw the ground.
@export var ground_material: Material:
	set(value):
		ground_material = value
		if _ground:
			_ground.material = value

var _ground: TileMapLayer

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
	return _ground.local_to_map(_ground.to_local(global_point)) if _ground else Vector2i.ZERO

## Ground type at `global_point`, or NONE off-map/in air; water does not change the ground type.
func ground_at(global_point: Vector2) -> Enums.Ground:
	return map.ground_at(cell_at(global_point)) if map else Enums.Ground.NONE

## The world rectangle of `cell`, for anything that must line up with the grid.
func cell_rect(cell: Vector2i) -> Rect2:
	var size := Vector2(FLOOR_TILESET.tile_size)
	return Rect2(_ground.to_global(_ground.map_to_local(cell) - size * 0.5), size)

func _build() -> void:
	# Remove immediately so newly built entities can reuse IDs before queued nodes are freed.
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_ground = null
	if map == null:
		return
	_ground = TileMapLayer.new()
	_ground.name = "Ground"
	_ground.tile_set = FLOOR_TILESET
	_ground.material = ground_material
	for y: int in map.size.y:
		for x: int in map.size.x:
			var cell := map.origin + Vector2i(x, y)
			var packed := map.tile_at(cell)
			if packed != RoomMap.NO_TILE:
				_ground.set_cell(cell, GroundAutotile.SOURCE_ID, RoomMap.tile_coords(packed), RoomMap.tile_alternative(packed))
	_adopt(_ground)
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
	var ratio := Vector2i(FLOOR_TILESET.tile_size) / Vector2i(layer.tile_set.tile_size)
	for cell: Vector2 in cells:
		for dy: int in ratio.y:
			for dx: int in ratio.x:
				layer.set_cell(Vector2i(cell) * ratio + Vector2i(dx, dy), 0, Vector2i.ZERO, alternative)

func _place(entry: RoomLegendEntry, placed: Dictionary, entities: Node2D) -> void:
	var node := entry.scene.instantiate() as Node2D
	assert(node != null, "legend '%s': an entity scene's root must be a Node2D" % entry.symbol)
	var size := Vector2(FLOOR_TILESET.tile_size)
	var rect := Rect2(_ground.map_to_local(placed.cell) - size * 0.5, size)
	node.position = Vector2(rect.get_center().x, rect.end.y) if entry.anchor == RoomLegendEntry.Anchor.FEET else rect.get_center()
	node.name = "%s_%d_%d" % [entry.symbol.uri_encode(), placed.cell.x, placed.cell.y]
	EntityParams.apply(node, placed.params)
	entities.add_child(node)

func _adopt(node: Node) -> void:
	add_child(node)

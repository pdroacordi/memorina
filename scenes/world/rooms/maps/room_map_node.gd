@tool
class_name RoomMapNode extends Node2D

## A room's ground, water and placed things, built from its `.room` text
## (docs/maps/README.md). The text is the source of truth; this node only
## lays out what the imported RoomMap already resolved, so a room's load is a
## set_cell per ground cell plus one WaterLayer per kind of water and one node
## per entity.
##
## The ground is a TileMapLayer child, and the water layers and entities are
## its SIBLINGS, drawn after it - never its children: a lake parented under the
## ground's TileMapLayer stopped drawing in front of it.
##
## Runs in the editor too, as a preview: what it builds there is never owned
## by the scene, so it is never saved into the .tscn - edit the .room file,
## not the preview.
##
## It is also where the rest of the game asks what the ground is made of
## (ground_at), because the map is the only place that knows: Enraizar needs
## earth, and stone looks different on purpose.

const GROUP := &"room_map"
const FLOOR_TILESET := preload("res://resources/world/tiles/floor_tileset.tres")

## The imported `.room` file.
@export var map: RoomMap:
	set(value):
		map = value
		if is_inside_tree():
			_build()
## What the ground draws with: the seasonal art material, so a pulse redraws
## it in its season.
@export var ground_material: Material:
	set(value):
		ground_material = value
		if _ground:
			_ground.material = value

var _ground: TileMapLayer
## Everything built from the map, so a rebuild removes exactly that.
var _built: Array[Node] = []

## The room map whose map contains `global_point`'s cell (rooms do not
## overlap). Null where no room map is loaded.
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

## What the ground at `global_point` is made of; NONE in the air, in water, off
## the map.
func ground_at(global_point: Vector2) -> Enums.Ground:
	return map.ground_at(cell_at(global_point)) if map else Enums.Ground.NONE

## The world rectangle of `cell`, for anything that must line up with the grid.
func cell_rect(cell: Vector2i) -> Rect2:
	var size := Vector2(FLOOR_TILESET.tile_size)
	return Rect2(_ground.to_global(_ground.map_to_local(cell) - size * 0.5), size)

func _build() -> void:
	for node: Node in _built:
		node.queue_free()
	_built.clear()
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
	for symbol: String in map.water:
		_pour(map.legend.entry(symbol), map.water[symbol])
	for placed: Dictionary in map.entities:
		_place(map.legend.entry(placed.symbol), placed)

## One WaterLayer per kind of water, its finer cells painted under every map
## cell of that kind BEFORE it enters the tree: it turns its cells into bodies
## in its own _ready.
func _pour(entry: RoomLegendEntry, cells: PackedVector2Array) -> void:
	var layer := entry.water_layer.instantiate() as WaterLayer
	assert(layer != null, "legend '%s': water_layer must be a WaterLayer preset" % entry.symbol)
	var ratio := Vector2i(FLOOR_TILESET.tile_size) / Vector2i(layer.tile_set.tile_size)
	for cell: Vector2 in cells:
		for dy: int in ratio.y:
			for dx: int in ratio.x:
				layer.set_cell(Vector2i(cell) * ratio + Vector2i(dx, dy), 0, Vector2i.ZERO)
	layer.name = "Water_%s" % entry.symbol.uri_encode()
	_adopt(layer)

func _place(entry: RoomLegendEntry, placed: Dictionary) -> void:
	var node := entry.scene.instantiate() as Node2D
	assert(node != null, "legend '%s': an entity scene's root must be a Node2D" % entry.symbol)
	var size := Vector2(FLOOR_TILESET.tile_size)
	var rect := Rect2(_ground.map_to_local(placed.cell) - size * 0.5, size)
	node.position = Vector2(rect.get_center().x, rect.end.y) if entry.anchor == RoomLegendEntry.Anchor.FEET else rect.get_center()
	node.name = "%s_%d_%d" % [entry.symbol.uri_encode(), placed.cell.x, placed.cell.y]
	EntityParams.apply(node, placed.params)
	_adopt(node)

func _adopt(node: Node) -> void:
	_built.append(node)
	add_child(node)

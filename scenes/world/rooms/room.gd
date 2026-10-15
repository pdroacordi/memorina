class_name Room
extends Area2D

signal room_entered(room: Room)

const GROUP := "room"

@export var contents_scene : PackedScene
## Reached through a door: off the map and out of the weather (design 04 section 4).
@export var interior: bool = false
@onready var _shape_node: CollisionShape2D = $CollisionShape2D
var _contents_node: Node2D
var _map: RoomMap
## Rebuild the contents on the next activate() instead of waking them.
var _expired: bool = false

## The room `node` sits in, if any (a contents scene opened alone has none).
static func of(node: Node) -> Room:
	var at := node.get_parent()
	while at != null:
		if at is Room:
			return at
		at = at.get_parent()
	return null

## The room in `tree` whose bounds hold the world `point`, or null.
static func at(tree: SceneTree, point: Vector2) -> Room:
	for room: Room in tree.get_nodes_in_group(GROUP):
		if room.get_bounds().has_point(point):
			return room
	return null

## The index of the node in `contents` that sets a RoomMap `map`, or -1
## (gotchas/scene-state-lists-only-the-properties-a-scene-file-sets: every contents scene sets it).
static func map_node(contents: SceneState) -> int:
	for i: int in contents.get_node_count():
		if _map_set_by(contents, i) != null:
			return i
	return -1

# The RoomMap node `node` of `contents` sets as `map`, or null.
static func _map_set_by(contents: SceneState, node: int) -> RoomMap:
	for j: int in contents.get_node_property_count(node):
		if contents.get_node_property_name(node, j) == &"map":
			return contents.get_node_property_value(node, j) as RoomMap
	return null

func _enter_tree() -> void:
	add_to_group(GROUP)

## Reactivates cached contents or creates them on the first visit.
func activate() -> void:
	if _expired:
		_expired = false
		evict()
	if not _contents_node:
		_contents_node = contents_scene.instantiate()
		_add_contents.call_deferred(_contents_node)
	else:
		_contents_node.process_mode = Node.PROCESS_MODE_INHERIT
		_contents_node.show()

## Deactivates contents while preserving their session state.
func deactivate() -> void:
	if _contents_node:
		_contents_node.process_mode = Node.PROCESS_MODE_DISABLED
		_contents_node.hide()

## Whether the contents exist and run (new contents may still be waiting for their deferred add).
func is_active() -> bool:
	return _contents_node != null and _contents_node.process_mode != Node.PROCESS_MODE_DISABLED

## Destroys cached contents when `RoomResidency` evicts this room.
func evict() -> void:
	if _contents_node:
		# Out of the tree now, not at frame end: a fresh instance may follow
		# this frame, and the old one's groups (a bench's seat) must be gone.
		if _contents_node.get_parent() == self:
			remove_child(_contents_node)
		_contents_node.queue_free()
		_contents_node = null

func expire() -> void:
	_expired = true

## Newly activated contents are added deferred; wait for `ready` before reading their children.
func contents() -> Node2D:
	return _contents_node

## The room's map, read from its contents scene without instancing it; null when the contents set none.
func map() -> RoomMap:
	if _map == null and contents_scene != null:
		var state := contents_scene.get_state()
		var node := map_node(state)
		_map = _map_set_by(state, node) if node >= 0 else null
	return _map

## The room's id, its scene file name: what a door's `to_room` names.
func id() -> StringName:
	return StringName(scene_file_path.get_file().get_basename())

## No sword here: an interior of a region with calm interiors. On the Region, since Room triggers regenerate.
func is_calm() -> bool:
	return interior and get_region().calm_interiors

func get_region() -> Region:
	var region := get_parent() as Region
	assert(region != null, "Room %s is not a child of a Region." % name)
	return region

## World-space rectangle the camera is allowed to show.
func get_bounds() -> Rect2:
	var shape: RectangleShape2D = _shape_node.shape
	return Rect2(_shape_node.global_position - shape.size * 0.5, shape.size)


# Prevent evicted contents from entering the tree after deferred activation (docs/knowledge/gotchas/queue-free-deferred-add-still-enters-the-tree.md).
func _add_contents(node: Node2D) -> void:
	if node == _contents_node and is_instance_valid(node):
		add_child(node)

func _on_body_entered(_body: Node2D) -> void:
	room_entered.emit(self)

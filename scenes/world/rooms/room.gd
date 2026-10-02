class_name Room
extends Area2D

signal room_entered(room: Room)

const GROUP := "room"

@export var contents_scene : PackedScene
@onready var _shape_node: CollisionShape2D = $CollisionShape2D
var _contents_node: Node2D
## Rebuild the contents on the next activate() instead of waking them.
var _expired: bool = false

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

## Destroys cached contents when the resident-room cache evicts this room (see game.gd).
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

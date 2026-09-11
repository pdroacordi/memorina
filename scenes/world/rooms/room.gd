class_name Room
extends Area2D

signal room_entered(room: Room)

const GROUP := "room"

@export var contents_scene : PackedScene
@onready var _shape_node: CollisionShape2D = $CollisionShape2D
var _contents_node: Node2D

func _enter_tree() -> void:
	add_to_group(GROUP)

## Instantiates on the first-ever visit; on every later visit the node was
## just sitting deactivated (see deactivate()), so this only needs to
## reverse that — nothing is re-created, so position/AI/animation state all
## carry over exactly as they were left.
func activate() -> void:
	if not _contents_node:
		_contents_node = contents_scene.instantiate()
		call_deferred("add_child", _contents_node)
	else:
		_contents_node.process_mode = Node.PROCESS_MODE_INHERIT
		_contents_node.show()

## Leaving a room does NOT destroy its contents — just freezes them in
## place. PROCESS_MODE_DISABLED recursively stops _process/_physics_process
## for the whole subtree (children default to inheriting it), so nothing in
## a deactivated room ticks: no AI, no gravity, no timers.
func deactivate() -> void:
	if _contents_node:
		_contents_node.process_mode = Node.PROCESS_MODE_DISABLED
		_contents_node.hide()

## The actual destroy, reserved for when the resident-room cache (see
## game.gd) decides this room is cold enough to truly forget. Whatever
## per-session state a deactivated room would have kept (position, "already
## spawned," etc.) is lost — the next visit instantiates fresh, same as
## before this whole warm/cold split existed.
func evict() -> void:
	if _contents_node:
		_contents_node.queue_free()
		_contents_node = null

## World-space rectangle the camera is allowed to show.
func get_bounds() -> Rect2:
	var shape: RectangleShape2D = _shape_node.shape
	return Rect2(_shape_node.global_position - shape.size * 0.5, shape.size)


func _on_body_entered(_body: Node2D) -> void:
	room_entered.emit(self)

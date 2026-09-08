class_name Room
extends Area2D

signal room_entered(room: Room)

const GROUP := "room"

@export var contents_scene : PackedScene
@onready var _shape_node: CollisionShape2D = $CollisionShape2D
var _contents_node: Node2D

func _enter_tree() -> void:
	add_to_group(GROUP)

func load_contents() -> void:
	if not _contents_node:
		_contents_node = contents_scene.instantiate()
		call_deferred("add_child", _contents_node)

func unload_contents() -> void:
	if _contents_node:
		_contents_node.queue_free()
		_contents_node = null

## World-space rectangle the camera is allowed to show.
func get_bounds() -> Rect2:
	var shape: RectangleShape2D = _shape_node.shape
	return Rect2(_shape_node.global_position - shape.size * 0.5, shape.size)


func _on_body_entered(_body: Node2D) -> void:
	room_entered.emit(self)

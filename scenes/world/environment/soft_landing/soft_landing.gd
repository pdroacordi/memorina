class_name SoftLanding
extends Area2D
## A zone where a landing is never a hard landing: deep snow (systems/rooms "Soft landing"). It tells the body it
## holds; the body's landing component counts the zones it is in.

## Zone width, in cells, centred on its cell.
@export var width_cells: int = 4
## Zone height, in cells, rising from its cell's floor. Keep it at least 2 cells over the highest floor under it: a
## body enters it a few frames before it lands, so the count is up when the landing is judged.
@export var height_cells: int = 3

@onready var _shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	var box := RectangleShape2D.new()
	box.size = size()
	_shape.shape = box
	_shape.position = Vector2(0.0, -box.size.y * 0.5)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

## The zone's size in px.
func size() -> Vector2:
	return Vector2(width_cells, height_cells) * RoomMap.CELL_PX

func _on_body_entered(body: Node2D) -> void:
	if body.has_method(&"enter_soft_landing"):
		body.call(&"enter_soft_landing")

func _on_body_exited(body: Node2D) -> void:
	if body.has_method(&"exit_soft_landing"):
		body.call(&"exit_soft_landing")

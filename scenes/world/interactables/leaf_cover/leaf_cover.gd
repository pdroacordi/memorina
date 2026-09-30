class_name LeafCover extends StaticBody2D

## A curtain of dry leaves grown over a passage (design 02 section 8, Outono
## Espacial 1: "uma parede de folhas secas esconde uma passagem lateral").
## Soltar lets the leaves fall: they drop in a flurry, the passage opens, and
## when the grey takes the pulse back they grow back - not while someone is
## standing in the passage, which would leave them inside the wall.
##
## Stands on its cell like any room map entity: `size` wide, rising from the
## floor.

@export var size := Vector2(32, 96)
@export var regrow_time := 0.8

@onready var _releasable: Releasable = $Releasable
@onready var _leaves: Sprite2D = $Leaves
@onready var _fall: CPUParticles2D = $Fall
@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _receiver_shape: CollisionShape2D = $ReleaseReceiver/CollisionShape2D
@onready var _inside: Area2D = $Inside
@onready var _inside_shape: CollisionShape2D = $Inside/CollisionShape2D

func _ready() -> void:
	var box := RectangleShape2D.new()
	box.size = size
	for shape: CollisionShape2D in [_shape, _receiver_shape, _inside_shape]:
		shape.shape = box
		shape.position = Vector2(0, -size.y * 0.5)
	_leaves.region_rect = Rect2(Vector2.ZERO, size)
	_leaves.position = Vector2(0, -size.y * 0.5)
	_fall.position = Vector2(0, -size.y * 0.5)
	_fall.emission_rect_extents = size * 0.5
	_releasable.released.connect(_on_released)
	_releasable.restored.connect(_on_restored)
	_inside.body_entered.connect(func(body: Node2D) -> void: if body is Character: _releasable.hold())
	_inside.body_exited.connect(func(body: Node2D) -> void: if body is Character: _releasable.let_go())

func is_open() -> bool:
	return _releasable.is_released()

func _on_released() -> void:
	_shape.set_deferred("disabled", true)
	_fall.restart()
	var tween := create_tween()
	tween.tween_property(_leaves, "modulate:a", 0.0, 0.35)

func _on_restored() -> void:
	_shape.set_deferred("disabled", false)
	var tween := create_tween()
	tween.tween_property(_leaves, "modulate:a", 1.0, regrow_time)

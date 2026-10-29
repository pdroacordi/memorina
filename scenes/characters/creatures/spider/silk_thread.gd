class_name SilkThread
extends Node2D
## Draws its spider's thread from the anchor down to the spider's back each frame. It stands at the anchor (top level),
## so its shader's grid is tied to the ceiling and does not slide as the spider climbs (systems/creatures).

## Thread width, px.
const WIDTH := 2.0

@export var ai: ThreadAI
@export var spider: Enemy
## Where the thread meets the spider, px from the spider's origin.
@export var attach: Vector2 = Vector2(0.0, -20.0)
@export var colour: Color = Color(0.86, 0.86, 0.82)


func _ready() -> void:
	top_level = true

func _process(_delta: float) -> void:
	# It snaps at death; the body dissolves without it.
	visible = not spider.is_dead()
	global_position = ai.anchor()
	queue_redraw()

func _draw() -> void:
	draw_line(Vector2.ZERO, to_local(spider.global_position + attach), colour, WIDTH)

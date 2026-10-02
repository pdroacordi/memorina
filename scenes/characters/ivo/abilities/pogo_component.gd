class_name PogoComponent
extends Node
## Applies the pogo impulse; the caller decides which hit should trigger it.

@export var enabled: bool = true
@export var bounce_strength: float = 400.0

@onready var _body: CharacterBody2D = get_parent()


func try_bounce() -> void:
	if not enabled:
		return
	_body.velocity.y = -bounce_strength

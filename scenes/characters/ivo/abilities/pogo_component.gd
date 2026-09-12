class_name PogoComponent
extends Node
## Applies the upward bounce impulse for the pogo attack. Kept separate from
## Hitbox and AttackComponent - both stay reusable by enemies that must never
## bounce off their own hits - and separate from knowing WHICH attack landed,
## which is Player's job to decide before calling try_bounce().

@export var enabled: bool = true
@export var bounce_strength: float = 400.0

@onready var _body: CharacterBody2D = get_parent()


func try_bounce() -> void:
	if not enabled:
		return
	_body.velocity.y = -bounce_strength

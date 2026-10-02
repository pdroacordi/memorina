class_name DoubleJumpComponent
extends Node
## Provides one gated mid-air jump using JumpComponent.launch() for the shared launch formula.

signal double_jumped(position: Vector2)

## The owner sets this from the saved skill gate.
@export var enabled: bool = true
## Jump height in pixels.
@export var height: float = 128.0
## Fraction of launch velocity added while rising; adding preserves visible lift when a recalled jump cannot wait for the apex.
@export_range(0.0, 1.0, 0.05) var rising_boost: float = 0.5

## The owner injects the jump component so this component does not search for siblings.
var jump: JumpComponent
var _is_ready: bool = false

# The driven body is always the direct parent.
@onready var _body: Character = get_parent()


## Ground or wall contact re-arms the air jump.
func refresh() -> void:
	_is_ready = true

func try_jump() -> bool:
	if not enabled or not _is_ready:
		return false

	var rising := minf(_body.velocity.y, 0.0)
	jump.launch(height)
	if rising < 0.0:
		_body.velocity.y = minf(_body.velocity.y, rising + _body.velocity.y * rising_boost)
	_is_ready = false
	double_jumped.emit(_body.global_position)
	return true

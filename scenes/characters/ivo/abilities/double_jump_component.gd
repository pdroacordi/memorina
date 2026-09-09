class_name DoubleJumpComponent
extends Node
## One extra mid-air jump. This is a gated PLAYER ability, not baseline
## movement — which is why it lives under the player's abilities/ folder
## rather than the shared components/ set that enemies also mount. Reuses
## JumpComponent.launch() so the launch and force formula are never
## duplicated.

signal double_jumped(position: Vector2)

## The owner drives this from the save-game skill gate; the component itself
## must never know SaveSystem exists, so it stays reusable.
@export var enabled: bool = true
## A single scalar, so a plain export rather than a one-field Resource, which
## would be ceremony without benefit.
@export var height: float = 128.0

## Injected by the owner, which as composition root is the only thing that
## should know the full wiring graph; the component does not go looking for
## siblings.
var jump: JumpComponent
var _is_ready: bool = false

# Always a direct child of the body it drives, matching the existing
# $PlayerInput / $Hurtbox idiom in this codebase; an exported NodePath would
# only add an inspector-reassignable foot-gun with no swappable-target use case.
@onready var _body: Character = get_parent()


## Touching the ground or a wall re-arms the air jump.
func refresh() -> void:
	_is_ready = true

func try_jump() -> bool:
	if not enabled or not _is_ready:
		return false

	jump.launch(height)
	_is_ready = false
	double_jumped.emit(_body.global_position)
	return true

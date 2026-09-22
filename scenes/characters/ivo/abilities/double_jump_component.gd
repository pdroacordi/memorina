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
## How much of the launch is ADDED rather than assigned when the body is
## still rising. An air jump that assigns the speed is right at the apex and
## wrong on the way up: pressed at -184 px/s a 222 px/s launch is a gain of
## 38, a jump nobody can see. A recalled double jump forces exactly that
## press - the slowed world makes waiting for the apex impossible - so it is
## the one case the rule has to answer. 0 restores the plain assignment.
@export_range(0.0, 1.0, 0.05) var rising_boost: float = 0.5

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

	var rising := minf(_body.velocity.y, 0.0)
	jump.launch(height)
	if rising < 0.0:
		_body.velocity.y = minf(_body.velocity.y, rising + _body.velocity.y * rising_boost)
	_is_ready = false
	double_jumped.emit(_body.global_position)
	return true

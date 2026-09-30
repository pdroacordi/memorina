class_name Mechanism extends AnimatableBody2D

## Something a trigger moves between two places: a gate that slides up out of
## the way, a lift that rises. It follows ONE trigger (room map param
## `trigger_path`, the id of a plate or anything with `activated` /
## `deactivated` signals) and moves `travel` pixels over `move_time` seconds
## while the trigger holds, back while it does not. An AnimatableBody2D, so it
## carries and shoves whoever stands on or against it instead of passing
## through them.

## The trigger it follows. A bare id in a room map resolves to that entity.
@export var trigger_path: NodePath
## Where it goes when triggered, relative to where it was placed.
@export var travel := Vector2(0, -96)
@export var move_time := 0.6
## Start triggered (a drawbridge that is already down, a lift already up).
@export var start_moved := false

var _rest := Vector2.ZERO
var _progress := 0.0
var _target := 0.0

func _ready() -> void:
	sync_to_physics = true
	_rest = position
	_target = 1.0 if start_moved else 0.0
	_progress = _target
	_apply()
	var trigger := get_node_or_null(trigger_path)
	if trigger:
		trigger.activated.connect(func() -> void: _target = 1.0)
		trigger.deactivated.connect(func() -> void: _target = 0.0)

func is_moved() -> bool:
	return _progress >= 1.0

func _physics_process(delta: float) -> void:
	if is_equal_approx(_progress, _target):
		return
	_progress = move_toward(_progress, _target, delta / maxf(move_time, 0.0001))
	_apply()

func _apply() -> void:
	# Eased, so it starts and settles like something heavy, and whole pixels.
	position = (_rest + travel * smoothstep(0.0, 1.0, _progress)).round()

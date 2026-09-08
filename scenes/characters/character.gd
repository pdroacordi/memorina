class_name Character
extends CharacterBody2D
## Shared base for anything that moves, takes damage and faces a direction.
## Subclasses implement motion by overriding _process_motion()/_after_move()
## rather than _physics_process(), which this base owns as a template method.

signal facing_changed(facing: int)
signal died

@export var gravity_scale: float = 1.0

@export_category("Knockback")
## How long locomotion control stays suppressed after a hit.
@export var knockback_time: float = 0.18
## Exponential decay rate applied to horizontal knockback velocity during that window.
@export var knockback_damping: float = 6.0

var facing: int = 1
var _knockback_timer: float = 0.0

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var _base_gravity: float = PhysicsServer2D.area_get_param(get_world_2d().space, PhysicsServer2D.AREA_PARAM_GRAVITY)


func _ready() -> void:
	hurtbox.hit_received.connect(_on_hit_received)
	health.died.connect(_on_health_died)

func _physics_process(delta: float) -> void:
	_knockback_timer = maxf(_knockback_timer - delta, 0.0)
	_process_motion(delta)
	move_and_slide()
	# _after_move() must run after move_and_slide(): that is what refreshes
	# is_on_floor(). Whatever state it sets must also be settled before the
	# AnimationTree evaluates, which holds structurally — AnimationTree is a
	# child of this node, and Godot processes parents before their children.
	_after_move(delta)

## Turns to face `axis` (negative left, positive right). Silent no-op on a
## zero axis or when the axis doesn't cross the facing threshold, so callers
## can pass a raw input axis every frame without spamming the signal.
func face_towards(axis: float) -> void:
	if is_zero_approx(axis):
		return

	var new_facing: int = -1 if axis < 0.0 else 1
	if new_facing == facing:
		return

	facing = new_facing
	facing_changed.emit(facing)

func base_gravity() -> float:
	return _base_gravity * gravity_scale

func is_in_knockback() -> bool:
	return _knockback_timer > 0.0

## The impulse REPLACES horizontal velocity rather than adding to it, so the
## resulting speed is predictable regardless of how fast the character was
## already moving (a chain of hits doesn't compound into an ever-larger shove).
func apply_knockback(impulse: Vector2) -> void:
	if impulse.is_zero_approx():
		return

	velocity.x = impulse.x
	# A purely horizontal shove should not cancel an in-progress fall or jump.
	if not is_zero_approx(impulse.y):
		velocity.y = impulse.y

	_knockback_timer = knockback_time

## Exponential rather than the linear move_toward used by normal locomotion:
## it decays smoothly without a hard cutoff, so control returns gradually
## instead of snapping back the instant the hitstun window ends.
func apply_knockback_decay(delta: float) -> void:
	velocity.x = lerpf(velocity.x, 0.0, 1.0 - exp(-knockback_damping * delta))

## Hook for subclasses to drive their own motion before move_and_slide().
func _process_motion(_delta: float) -> void:
	pass

## Hook for subclasses to react once move_and_slide() has refreshed floor/wall
## state (see the comment in _physics_process()).
func _after_move(_delta: float) -> void:
	pass

func _on_hit_received(damage: int, knockback: Vector2, _source: Node2D) -> void:
	health.take_damage(damage)
	apply_knockback(knockback)

## Only announces death; no queue_free, no death policy here. The design has
## no traditional game over, so the host decides the consequence (e.g. the
## player respawns at the last bench).
func _on_health_died() -> void:
	died.emit()

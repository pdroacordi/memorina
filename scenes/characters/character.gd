class_name Character
extends CharacterBody2D

signal facing_changed(facing: int)
signal died

@export var gravity_scale: float = 1.0

@export_category("Knockback")
@export var knockback_time: float = 0.18
@export var knockback_damping: float = 6.0

var facing: int = 1
var _knockback_timer: float = 0.0
var _just_hit: bool = false

@onready var health             : Health = $Health
@onready var hurtbox            : Hurtbox = $Hurtbox
@onready var _base_gravity      : float = PhysicsServer2D.area_get_param(get_world_2d().space, PhysicsServer2D.AREA_PARAM_GRAVITY)
@onready var _sprite            : Sprite2D = $Sprite2D
@onready var _animation_driver  : AnimationDriver = $AnimationDriver
@onready var _animation_resolver: AnimationResolver = $AnimationResolver

func _ready() -> void:
	hurtbox.hit_received.connect(_on_hit_received)
	health.died.connect(_on_health_died)
	_animation_resolver.driver = _animation_driver

func _physics_process(delta: float) -> void:
	_knockback_timer = maxf(_knockback_timer - delta, 0.0)
	_process_motion(delta)
	move_and_slide()
	_after_move(delta)
	_animation_driver.play(_animation_resolver.resolve())
	_just_hit = false

func face_towards(axis: float) -> void:
	if is_zero_approx(axis):
		return

	var new_facing: int = -1 if axis < 0.0 else 1
	if new_facing == facing:
		return

	facing = new_facing
	_sprite.flip_h = facing < 0
	facing_changed.emit(facing)

func base_gravity() -> float:
	return _base_gravity * gravity_scale

func is_in_knockback() -> bool:
	return _knockback_timer > 0.0

func is_dead() -> bool:
	return not health.is_alive()

func just_hit() -> bool:
	return _just_hit

func apply_knockback(impulse: Vector2) -> void:
	if impulse.is_zero_approx():
		return

	velocity.x = impulse.x
	if not is_zero_approx(impulse.y):
		velocity.y = impulse.y

	_knockback_timer = knockback_time

## Lets go of a flinch early, for something that OUTRANKS being hit - a
## remembered skill performing on the same press that bought it.
func clear_knockback() -> void:
	_knockback_timer = 0.0

func apply_knockback_decay(delta: float) -> void:
	velocity.x = lerpf(velocity.x, 0.0, 1.0 - exp(-knockback_damping * delta))

func _process_motion(_delta: float) -> void:
	pass

func _after_move(_delta: float) -> void:
	pass

func _assert_clip_length(state: StringName, duration: float) -> void:
	var clip := _animation_driver.clip_length(state)
	assert(absf(clip - duration) < 0.001,
		"%s: '%s' clip is %.4fs but its gameplay duration is %.4fs" % [name, state, clip, duration])

func _on_hit_received(damage: int, knockback: Vector2, _source: Node2D) -> void:
	if is_dead():
		return
	health.take_damage(damage)
	apply_knockback(knockback)
	# A killing blow shows death, not a flinch.
	_just_hit = health.is_alive()

func _on_health_died() -> void:
	died.emit()

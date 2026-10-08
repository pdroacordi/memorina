class_name Character
extends CharacterBody2D

signal facing_changed(facing: int)
signal died

## Sprite properties copied by `silhouette()`.
const SILHOUETTE_PROPERTIES: Array[StringName] = [
	&"texture", &"hframes", &"vframes", &"frame", &"flip_h", &"flip_v",
	&"centered", &"offset", &"region_enabled", &"region_rect", &"texture_filter",
]
## How far a character on the floor is pulled down onto it, px: walking down a frozen crest's slope stays grounded.
const FLOOR_SNAP := 12.0

@export var gravity_scale: float = 1.0

@export_category("Knockback")
@export var knockback_time: float = 0.18
@export var knockback_damping: float = 6.0
## Color and duration of the hit flash, in real seconds.
@export var hurt_flash_color: Color = Color(1.0, 0.5, 0.5)
@export var hurt_flash_time: float = 0.18

var facing: int = 1
## Air velocity (px/s) applied during this physics frame.
var _carry := Vector2.ZERO
var _knockback_timer: float = 0.0
var _just_hit: bool = false
var _flash_tween: Tween

@onready var health             : Health = $Health
@onready var hurtbox            : Hurtbox = $Hurtbox
@onready var _base_gravity      : float = PhysicsServer2D.area_get_param(get_world_2d().space, PhysicsServer2D.AREA_PARAM_GRAVITY)
@onready var _sprite            : Sprite2D = $Sprite2D
@onready var _animation_driver  : AnimationDriver = $AnimationDriver
@onready var _animation_resolver: AnimationResolver = $AnimationResolver

## Moves `body` to `point` on the node and on the physics server alike. A plain position write leaves a
## kinematic body at its old place for one step (docs/knowledge/gotchas/a-teleported-kinematic-body-overlaps-from-its-old-place-for-one-step.md).
static func teleport_body(body: CharacterBody2D, point: Vector2) -> void:
	body.global_position = point
	var rid := body.get_rid()
	# STATIC applies the transform at once; returning to KINEMATIC re-arms GodotPhysics2D's first_time_kinematic.
	PhysicsServer2D.body_set_mode(rid, PhysicsServer2D.BODY_MODE_STATIC)
	PhysicsServer2D.body_set_state(rid, PhysicsServer2D.BODY_STATE_TRANSFORM, body.global_transform)
	PhysicsServer2D.body_set_mode(rid, PhysicsServer2D.BODY_MODE_KINEMATIC)

func _ready() -> void:
	floor_snap_length = FLOOR_SNAP
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
	_carry = Vector2.ZERO

## Every move that is not motion (a seat, a respawn, a debug jump) goes through here.
func teleport(point: Vector2) -> void:
	teleport_body(self, point)

func face_towards(axis: float) -> void:
	if is_zero_approx(axis):
		return

	var new_facing: int = -1 if axis < 0.0 else 1
	if new_facing == facing:
		return

	facing = new_facing
	_sprite.flip_h = facing < 0
	facing_changed.emit(facing)

## Pushers call this before movement; `AirflowBody` runs at a lower physics priority.
func push(wind: Vector2) -> void:
	_carry += wind

## Returns this frame's accumulated air velocity.
func carry() -> Vector2:
	return _carry

func base_gravity() -> float:
	return _base_gravity * gravity_scale

func is_in_knockback() -> bool:
	return _knockback_timer > 0.0

func is_dead() -> bool:
	return not health.is_alive()

func just_hit() -> bool:
	return _just_hit

## Flashes the sprite for the given duration in real seconds.
func flash(color: Color, seconds: float) -> void:
	if _flash_tween != null:
		_flash_tween.kill()
	_sprite.modulate = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(_sprite, "modulate", Color.WHITE, seconds)

## Returns a static sprite copy using the current global transform.
func silhouette() -> Sprite2D:
	var copy := Sprite2D.new()
	for property: StringName in SILHOUETTE_PROPERTIES:
		copy.set(property, _sprite.get(property))
	copy.transform = _sprite.global_transform
	return copy

func apply_knockback(impulse: Vector2) -> void:
	if impulse.is_zero_approx():
		return

	velocity.x = impulse.x
	if not is_zero_approx(impulse.y):
		velocity.y = impulse.y

	_knockback_timer = knockback_time

## Clears knockback when an action performed on the same press takes priority.
func clear_knockback() -> void:
	_knockback_timer = 0.0

## Applies hazard damage; subclasses may also relocate or ignore the body.
func receive_hazard(hazard: HazardZone) -> void:
	if is_dead():
		return
	_wound(hazard.damage)

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
	_wound(damage)
	apply_knockback(knockback)

## Applies shared damage, flash, and hit state.
func _wound(damage: int) -> void:
	health.take_damage(damage)
	flash(hurt_flash_color, hurt_flash_time)
	# A killing blow shows death, not a flinch.
	_just_hit = health.is_alive()

func _on_health_died() -> void:
	died.emit()

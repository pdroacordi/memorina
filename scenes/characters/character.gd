class_name Character
extends CharacterBody2D

signal facing_changed(facing: int)
signal died

## What silhouette() copies from the body's sprite: the frame, never its
## material, script or animation.
const SILHOUETTE_PROPERTIES: Array[StringName] = [
	&"texture", &"hframes", &"vframes", &"frame", &"flip_h", &"flip_v",
	&"centered", &"offset", &"region_enabled", &"region_rect", &"texture_filter",
]

@export var gravity_scale: float = 1.0

@export_category("Knockback")
@export var knockback_time: float = 0.18
@export var knockback_damping: float = 6.0
## The colour a body wears for a moment when something lands on it, and for
## how long. Script-owned: nothing keys Sprite2D:modulate, so no RESET track
## fights this.
@export var hurt_flash_color: Color = Color(1.0, 0.5, 0.5)
@export var hurt_flash_time: float = 0.18

var facing: int = 1
## The air this body stands in this frame, as a VELOCITY (px/s): wind, a
## current, a song's gale (Airflow, through AirflowBody). Summed by whatever
## pushes, steered toward by the body's own motion, cleared after the move.
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
	_carry = Vector2.ZERO

func face_towards(axis: float) -> void:
	if is_zero_approx(axis):
		return

	var new_facing: int = -1 if axis < 0.0 else 1
	if new_facing == facing:
		return

	facing = new_facing
	_sprite.flip_h = facing < 0
	facing_changed.emit(facing)

## Adds moving air to this frame's carry. Pushers call this before the body
## moves (AirflowBody runs at a lower physics priority than the body).
func push(wind: Vector2) -> void:
	_carry += wind

## The air this body is standing in right now. The body decides what it does
## with it: locomotion steers toward input plus this, a guardian ignores it.
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

## A body wearing a colour for a beat: being hit, a guardian telegraphing, a
## guardian going lucid. One implementation, whatever the reason.
func flash(color: Color, seconds: float) -> void:
	if _flash_tween != null:
		_flash_tween.kill()
	_sprite.modulate = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(_sprite, "modulate", Color.WHITE, seconds)

## A still copy of the frame this body is showing right now - what Sombra
## burns into the ground. Plain drawing: no script, no animation, and not on
## the creature pass (it is the world's, so the grey takes it). Its transform
## is the sprite's GLOBAL one; re-express it under whatever adopts it.
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

## Lets go of a flinch early, for something that OUTRANKS being hit - a
## remembered skill performing on the same press that bought it.
func clear_knockback() -> void:
	_knockback_timer = 0.0

## Somewhere this body cannot be (a HazardZone found it). By default it simply
## hurts: no knockback, there is nothing to be knocked away from, and no
## i-frames, which cannot hold anyone above water. A body that must also be put
## back somewhere (Player), or that is never wounded (Guardian), overrides this.
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

## What every way of being hurt shares: the health, the flash, the flinch.
func _wound(damage: int) -> void:
	health.take_damage(damage)
	flash(hurt_flash_color, hurt_flash_time)
	# A killing blow shows death, not a flinch.
	_just_hit = health.is_alive()

func _on_health_died() -> void:
	died.emit()

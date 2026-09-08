class_name Player
extends CharacterBody2D

signal facing_changed(facing: int)
signal jumped(position: Vector2)
signal double_jumped(position: Vector2)
signal hard_landed(position: Vector2, impact_speed: float)


@export_category("Locomotion")
@export var move_speed        : float = 96
@export var acceleration      : float = 1024
@export var deceleration      : float = 2048
@export var air_control       : float = 0.8
@export var air_brakes        : float = 0.8

@export_category("Jumping")
@export var jump_height       : float = 80
@export var rise_gravity_mult : float = 0.85
@export var fall_gravity_mult : float = 1.0
@export var terminal_velocity : float = 500
@export var coyote_time_max   : float = 0.12
@export var jump_buffer_max   : float = 0.12
@export var jump_cut_mult     : float = 0.5
@export var apex_threshold    : float = 40.0
@export var apex_gravity_mult : float = 0.5
@export var double_jump_height: float = 64

@export_category("Landing")
@export var hard_land_speed   : float = 400.0
@export var hard_land_time    : float = 0.75

@export_category("Wall Slide")
@export var wall_gravity_mult : float = 0.1

@export_category("Roll")
@export var roll_time            : float = 0.3
@export var roll_distance        : float = 128
@export var roll_cooldown        : float = 0.5
@export var roll_coyote_time_max : float = 0.12
@export var roll_buffer_max      : float = 0.12

var facing                    : int   = 1

var _is_jumping               : bool  = false
var _is_wall_sliding          : bool  = false
var _coyote_timer             : float = 0.0
var _jump_buffer_timer        : float = -1.0
var _was_on_floor             : bool  = true
var _last_fall_speed          : float = 0.0
var _recovery_timer           : float = 0.0
var _roll_timer               : float = 0.0
var _roll_cooldown_timer      : float = 0.0
var _roll_coyote_timer        : float = 0.0
var _roll_buffer_timer        : float = -1.0
var _double_jump_is_ready     : bool  = false

@onready var _sprite          : Sprite2D    = $Sprite2D
@onready var _input           : PlayerInput = $PlayerInput
@onready var _hurtbox         : Hurtbox     = $Hurtbox
@onready var _health          : Health      = $Health
@onready var _base_gravity    : float = PhysicsServer2D.area_get_param(get_world_2d().space, PhysicsServer2D.AREA_PARAM_GRAVITY)
@onready var _roll_speed       : float = roll_distance / roll_time

func _ready() -> void:
	_input.jump_pressed.connect(_on_jump_pressed)
	_input.jump_canceled.connect(_on_jump_canceled)
	_input.roll_pressed.connect(_on_roll_pressed)
	
	_hurtbox.hit_received.connect(_on_hit_received)

func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()

	_update_facing()
	_update_timers(delta, on_floor)

	if is_rolling():
		pass
	elif on_floor:
		_ground_physics(delta)
	else:
		_air_physics(delta)

	_try_jump(on_floor)
	_try_roll(on_floor)
	move_and_slide()

	# Must run after move_and_slide(): that is what refreshes is_on_floor().
	# _recovery_timer must also be set before the AnimationTree evaluates, which
	# holds structurally — AnimationTree is a child of this node, and Godot
	# processes parents before their children.
	_check_landing()

#############################################
##  A N I M A T I O N   C O N T R A C T    ##
#############################################
## Bound by advance_expression strings in ivo.tscn. Renaming or changing the
## semantics of anything below breaks animation SILENTLY at runtime, with no
## compile error. Update both together.

func move_axis() -> float:
	return 0.0 if is_recovering() or is_rolling() else _input.direction

func wants_to_move() -> bool:
	return not is_zero_approx(move_axis())

func is_jumping() -> bool:
	return _is_jumping

func is_rising() -> bool:
	return velocity.y < 0.0

func is_falling() -> bool:
	return not is_on_floor() and not _is_jumping

func is_recovering() -> bool:
	return _recovery_timer > 0.0

func is_wall_sliding() -> bool:
	return _is_wall_sliding

func is_rolling() -> bool:
	return _roll_timer > 0.0

#############################################
##  C A M E R A   I N T E N T              ##
#############################################
## Consumed by the camera; no animation binds to these. The two axes are
## mutually exclusive by construction — one requires standing, the other
## requires being airborne — so a camera may simply add them.

## Deliberate peek in [-1, 1] — negative up, positive down (screen space).
## Only a character standing still can peek, so this returns 0.0 while airborne,
## moving or recovering.
func look_axis() -> float:
	if not is_on_floor() or wants_to_move() or is_recovering():
		return 0.0
	return _input.look_direction

## Automatic vertical lead in [-1, 1], proportional to fall speed — negative
## while rising, positive while falling, 0.0 on the ground. Lets the camera show
## where the character is heading rather than where they are.
func air_axis() -> float:
	if is_on_floor():
		return 0.0
	return clampf(velocity.y / terminal_velocity, -1.0, 1.0)

#############################################
##  E V E N T S                            ##
#############################################

func _on_jump_pressed() -> void:
	_jump_buffer_timer = jump_buffer_max

func _on_jump_canceled() -> void:
	_cut_jump()
	
func _on_roll_pressed() -> void:
	_roll_buffer_timer = roll_buffer_max
	
func _on_hit_received(damage: int, knockback: Vector2, _source: Node2D) -> void:
	_health.take_damage(damage)
	velocity += knockback

#############################################
##  L O C O M O T I O N                    ##
#############################################

func _update_facing() -> void:
	var axis: float = move_axis()
	if is_zero_approx(axis):
		return

	var new_facing: int = -1 if axis < 0.0 else 1
	if new_facing == facing:
		return

	facing = new_facing
	_sprite.flip_h = facing < 0
	facing_changed.emit(facing)

func _ground_physics(delta: float) -> void:
	var axis: float = move_axis()

	if is_zero_approx(axis):
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
	elif is_zero_approx(velocity.x) or signf(velocity.x) == signf(axis):
		velocity.x = move_toward(velocity.x, axis * move_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, axis * move_speed, deceleration * delta)

func _air_physics(delta: float) -> void:
	if not _wall_slide(delta):
		_apply_gravity(delta)

	var axis: float = move_axis()

	if is_zero_approx(axis):
		velocity.x = move_toward(velocity.x, 0.0, deceleration * air_brakes * delta)
	else:
		velocity.x = move_toward(velocity.x, axis * move_speed, acceleration * air_control * delta)
	_last_fall_speed = maxf(velocity.y, 0.0)

#############################################
##  J U M P I N G                          ##
#############################################

func _update_timers(delta: float, on_floor: bool) -> void:
	if on_floor:
		_coyote_timer = coyote_time_max
		_double_jump_is_ready = true
		_roll_coyote_timer = roll_coyote_time_max
	else:
		_coyote_timer = max(_coyote_timer - delta, 0.0)
		_roll_coyote_timer = max(_roll_coyote_timer - delta, 0.0)

	if _jump_buffer_timer > 0.0:
		_jump_buffer_timer -= delta

	if _roll_buffer_timer > 0.0:
		_roll_buffer_timer -= delta

	if _recovery_timer > 0.0:
		_recovery_timer = _recovery_timer - delta if on_floor else 0.0
	
	if _roll_timer > 0.0:
		_roll_timer = max(_roll_timer - delta, 0.0)
		if _roll_timer == 0.0:
			_roll_cooldown_timer = roll_cooldown
	elif _roll_cooldown_timer > 0.0:
		_roll_cooldown_timer = max(_roll_cooldown_timer - delta, 0.0)

func _apply_gravity(delta: float) -> void:
	var gravity_mult := fall_gravity_mult if velocity.y >= 0.0 else rise_gravity_mult

	if absf(velocity.y) < apex_threshold:
		gravity_mult *= apex_gravity_mult

	var gravity := _base_gravity * gravity_mult

	velocity.y += gravity * delta
	velocity.y  = min(velocity.y, terminal_velocity)

	if _is_jumping and velocity.y >= 0.0:
		_is_jumping = false

func _try_jump(on_floor: bool) -> void:
	if is_recovering() or _jump_buffer_timer <= 0.0:
		return

	if on_floor or _coyote_timer > 0.0:
		velocity.y = _jump_force(jump_height)
		_is_jumping = true
		_is_wall_sliding = false
		_coyote_timer = 0.0
		_jump_buffer_timer = -1.0
		jumped.emit(global_position)
	elif _has_unlocked(Enums.PlayerSkill.DOUBLE_JUMP) and _double_jump_is_ready:
		velocity.y = _jump_force(double_jump_height)
		_is_jumping = true
		_is_wall_sliding = false
		_double_jump_is_ready = false
		_jump_buffer_timer = -1.0
		double_jumped.emit(global_position)

func _cut_jump() -> void:
	if _is_jumping and velocity.y < 0.0:
		velocity.y *= jump_cut_mult

func _jump_force(height: float) -> float:
	var gravity_rise := _base_gravity * rise_gravity_mult
	return sqrt(gravity_rise * height * 2.0) * -1.0

#############################################
##  L A N D I N G                          ##
#############################################

func _check_landing() -> void:
	var on_floor := is_on_floor()

	if on_floor and not _was_on_floor and _last_fall_speed >= hard_land_speed:
		_recovery_timer = hard_land_time
		hard_landed.emit(global_position, _last_fall_speed)
	_was_on_floor = on_floor

	if on_floor:
		_is_wall_sliding = false

#############################################
##  A B I L I T I E S                      ##
#############################################

func _has_unlocked(skill: Enums.PlayerSkill) -> bool:
	return SaveSystem.has_skill(skill)
	
func _wall_slide(delta: float) -> bool:
	if _is_wall_sliding:
		if not is_on_wall() or sign(get_wall_normal().x) == sign(move_axis()):
			_is_wall_sliding = false
		else:
			velocity.y += _base_gravity * delta * wall_gravity_mult
			_coyote_timer = coyote_time_max
			_double_jump_is_ready = true
	elif (
		_has_unlocked(Enums.PlayerSkill.WALL_CLIMB)
		and is_on_wall()
		and velocity.y >= 0
		and sign(move_axis() * -1) == sign(get_wall_normal().x)
	):
		_is_wall_sliding = true
		_coyote_timer = coyote_time_max
		_double_jump_is_ready = true
		velocity.y = min(velocity.y, 0)

	return _is_wall_sliding

func is_roll_on_cooldown() -> bool:
	return _roll_cooldown_timer > 0.0

func _try_roll(on_floor: bool) -> void:
	if _roll_buffer_timer <= 0.0:
		return
	if not (on_floor or _roll_coyote_timer > 0.0):
		return
	if not _has_unlocked(Enums.PlayerSkill.ROLL):
		return
	if is_rolling() or is_roll_on_cooldown():
		return

	_roll_buffer_timer = -1.0
	_roll_coyote_timer = 0.0

	var direction: float = move_axis()
	var roll_direction: float = sign(direction) if direction else facing

	velocity.x = roll_direction * _roll_speed
	_roll_timer = roll_time

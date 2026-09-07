class_name Player
extends CharacterBody2D

signal jumped(position: Vector2)
signal landed(position: Vector2, impact_speed: float)
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

@export_category("Landing")
@export var hard_land_speed   : float = 400.0
@export var hard_land_time    : float = 0.75

var _direction                : float = 0.0
var _is_jumping               : bool  = false
var _coyote_timer             : float = 0.0
var _jump_buffer_timer        : float = -1.0
var _was_on_floor             : bool  = true
var _last_fall_speed          : float = 0.0
var _recovery_timer           : float = 0.0

@onready var _sprite          : Sprite2D    = $Sprite2D
@onready var _input           : PlayerInput = $PlayerInput
@onready var _base_gravity    : float = PhysicsServer2D.area_get_param(get_world_2d().space, PhysicsServer2D.AREA_PARAM_GRAVITY)

func _ready() -> void:
	_input.direction_changed.connect(_on_direction_changed)
	_input.jump_pressed.connect(_on_jump_pressed)
	_input.jump_canceled.connect(_on_jump_canceled)

func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()

	_update_facing()
	_update_timers(delta, on_floor)

	if on_floor:
		_ground_physics(delta)
	else:
		_air_physics(delta)

	_try_jump(on_floor)
	move_and_slide()

	# Must run after move_and_slide(): that is what updates is_on_floor(), and
	# the AnimationTree evaluates as a child node later in the same frame. Any
	# later and the state machine sees "grounded with input" for one frame and
	# escapes the land animation into run.
	_check_landing()

#############################################
##  S T A T E                              ##
#############################################

func is_recovering() -> bool:
	return _recovery_timer > 0.0

#############################################
##  E V E N T S                            ##
#############################################

func _on_direction_changed(new_direction: float) -> void:
	_direction = 0.0 if is_recovering() else new_direction

func _on_jump_pressed() -> void:
	_jump_buffer_timer = jump_buffer_max

func _on_jump_canceled() -> void:
	_cut_jump()

#############################################
##  L O C O M O T I O N                    ##
#############################################

func _update_facing() -> void:
	if _direction != 0.0:
		_sprite.flip_h = _direction < 0.0

func _ground_physics(delta: float) -> void:
	if _direction != 0.0:
		if velocity.x == 0.0 or sign(velocity.x) == sign(_direction):
			velocity.x = move_toward(velocity.x, _direction * move_speed, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, _direction * move_speed, deceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)

func _air_physics(delta: float) -> void:
	_apply_gravity(delta)

	if _direction != 0.0:
		velocity.x = move_toward(velocity.x, _direction * move_speed, acceleration * air_control * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * air_brakes * delta)
	_last_fall_speed = maxf(velocity.y, 0.0)

#############################################
##  J U M P I N G                          ##
#############################################

func _update_timers(delta: float, on_floor: bool) -> void:
	if on_floor:
		_coyote_timer = coyote_time_max
	else:
		_coyote_timer = max(_coyote_timer - delta, 0.0)

	if _jump_buffer_timer > 0.0:
		_jump_buffer_timer -= delta

	if _recovery_timer > 0.0:
		_recovery_timer = _recovery_timer - delta if on_floor else 0.0

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
	var can_jump := (on_floor or _coyote_timer > 0.0) and not is_recovering()
	var wants_jump := _jump_buffer_timer > 0.0

	if can_jump and wants_jump:
		velocity.y = _jump_force(jump_height)
		_is_jumping = true
		_coyote_timer = 0.0
		_jump_buffer_timer = -1.0
		jumped.emit(global_position)

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

	if on_floor and not _was_on_floor:
		landed.emit(global_position, _last_fall_speed)

		if _last_fall_speed >= hard_land_speed:
			_recovery_timer = hard_land_time
			_direction = 0.0
			hard_landed.emit(global_position, _last_fall_speed)
	_was_on_floor = on_floor

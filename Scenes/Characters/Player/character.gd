extends CharacterBody2D
class_name Player

@export_category("Locomotion")
@export  var _move_speed   : float = 256
@export  var _acceleration : float = 2048
@export  var _deceleration : float = 4096
var _direction : float = 0.0

@export_category("Jumping")
@export  var _jump_height         : float = 128
@export  var _rise_gravity_mult   : float = 1.6
@export  var _fall_gravity_mult   : float = 2.5
@export  var _air_control         : float = 1.2   
@export  var _air_brakes          : float = 1.0
@export  var _terminal_velocity   : float = 900
@export  var _coyote_time_max     : float = 0.12  
@export  var _jump_buffer_max     : float = 0.12
@onready var _base_gravity        : float = PhysicsServer2D.area_get_param(get_world_2d().space, PhysicsServer2D.AREA_PARAM_GRAVITY)
var _is_jumping                   : bool  = false
var _coyote_timer                 : float = 0.0
var _jump_buffer_timer            : float = -1.0

@onready var input : PlayerInput = $PlayerInput

func _ready() -> void:
	input.direction_changed.connect(_on_direction_changed)
	input.jump_pressed.connect(_on_jump_pressed)
	input.jump_canceled.connect(_on_jump_canceled)

#############################################
##  E V E N T S                            ##
#############################################

func _on_direction_changed(new_direction: float) -> void:
	_direction = new_direction

func _on_jump_pressed() -> void:
	_jump_buffer_timer = _jump_buffer_max

func _on_jump_canceled() -> void:
	_cancel_jump()

#############################################
##  A C T I O N S                          ##
#############################################	

func _jump_force(height: float) -> float:
	var gravity_rise = _base_gravity * _rise_gravity_mult
	return sqrt(gravity_rise * height * 2) * -1
 
func _try_jump() -> void:
	var can_jump := is_on_floor() or _coyote_timer > 0.0
	var wants_jump := _jump_buffer_timer > 0.0
 
	if can_jump and wants_jump:
		velocity.y = _jump_force(_jump_height)
		_is_jumping = true
		_coyote_timer = 0.0
		_jump_buffer_timer = -1.0
 
func _cancel_jump() -> void:
	if _is_jumping and velocity.y < 0:
		velocity.y *= 0.5

#############################################
##  P H Y S I C S                          ##
#############################################

func _ground_physics(delta: float) -> void:
	if _direction:
		if velocity.x == 0 or sign(velocity.x) == sign(_direction):
			velocity.x = move_toward(velocity.x, _direction * _move_speed, _acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, _direction * _move_speed, _deceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, _deceleration * delta)

func _air_physics(delta: float) -> void:
	_apply_gravity(delta)
	
	if _direction:
		velocity.x = move_toward(velocity.x, _direction * _move_speed, _acceleration * _air_control * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, _deceleration * _air_brakes * delta)
	

func _apply_gravity(delta: float) -> void:
	var gravity_mult := _fall_gravity_mult if velocity.y >= 0 else _rise_gravity_mult
	var gravity := _base_gravity * gravity_mult
 
	velocity.y += gravity * delta
	velocity.y  = min(velocity.y, _terminal_velocity)
 
	if _is_jumping and velocity.y >= 0:
		_is_jumping = false

func _update_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = _coyote_time_max
	else:
		_coyote_timer = max(_coyote_timer - delta, 0.0)
 
	if _jump_buffer_timer > 0.0:
		_jump_buffer_timer -= delta

func _physics_process(delta: float) -> void:
	_update_timers(delta)
 
	if is_on_floor():
		_ground_physics(delta)
	else:
		_air_physics(delta)
		
	_try_jump()
 
	move_and_slide()

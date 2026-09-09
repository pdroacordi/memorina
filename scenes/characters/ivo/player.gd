class_name Player
extends Character

signal jumped(position: Vector2)
signal double_jumped(position: Vector2)
signal hard_landed(position: Vector2, impact_speed: float)


@export_category("Wall Slide")
@export var wall_gravity_mult : float = 0.1

@export_category("Roll")
@export var roll_time            : float = 0.3
@export var roll_distance        : float = 128
@export var roll_cooldown        : float = 0.5
@export var roll_coyote_time_max : float = 0.12
@export var roll_buffer_max      : float = 0.12

var _is_wall_sliding          : bool  = false
var _roll_timer               : float = 0.0
var _roll_cooldown_timer      : float = 0.0
var _roll_coyote_timer        : float = 0.0
var _roll_buffer_timer        : float = -1.0

@onready var _sprite          : Sprite2D    = $Sprite2D
@onready var _input           : PlayerInput = $PlayerInput
@onready var _locomotion      : LocomotionComponent = $Locomotion
@onready var _jump            : JumpComponent = $Jump
@onready var _landing         : LandingComponent = $Landing
@onready var _double_jump     : DoubleJumpComponent = $DoubleJump
@onready var _roll_speed       : float = roll_distance / roll_time

func _ready() -> void:
	super()

	_input.jump_pressed.connect(_jump.buffer_jump)
	_input.jump_canceled.connect(_jump.cut_jump)
	# Components emit these, but ivo.tscn wires its DustEmitter to Player's own
	# signals with from=".". Re-emitting keeps those scene connections working
	# untouched, so moving logic into a component never costs a scene edit.
	_jump.jumped.connect(jumped.emit)
	_landing.hard_landed.connect(hard_landed.emit)
	_double_jump.double_jumped.connect(double_jumped.emit)
	_input.roll_pressed.connect(_on_roll_pressed)

	facing_changed.connect(_on_facing_changed)

	_double_jump.jump = _jump

func _process_motion(delta: float) -> void:
	var on_floor := is_on_floor()

	face_towards(move_axis())
	_jump.tick_timers(delta, on_floor)
	_update_timers(delta, on_floor)
	_landing.tick_timer(delta, on_floor)

	if is_in_knockback():
		_jump.apply_gravity(delta)
		apply_knockback_decay(delta)
	elif is_rolling():
		pass
	elif on_floor:
		_locomotion.ground_update(delta, move_axis())
	else:
		_air_physics(delta)

	_try_jump(on_floor)
	_try_roll(on_floor)

func _after_move(_delta: float) -> void:
	var on_floor := is_on_floor()
	_landing.check_landing(on_floor)
	if on_floor:
		_is_wall_sliding = false

#############################################
##  A N I M A T I O N   C O N T R A C T    ##
#############################################
## Bound by advance_expression strings in ivo.tscn. Renaming or changing the
## semantics of anything below breaks animation SILENTLY at runtime, with no
## compile error. Update both together.

func move_axis() -> float:
	return 0.0 if is_recovering() or is_rolling() or is_in_knockback() else _input.direction

func wants_to_move() -> bool:
	return not is_zero_approx(move_axis())

func is_jumping() -> bool:
	return _jump.is_jumping

func is_rising() -> bool:
	return velocity.y < 0.0

func is_falling() -> bool:
	return not is_on_floor() and not _jump.is_jumping

func is_recovering() -> bool:
	return _landing.is_recovering()

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
	return clampf(velocity.y / _jump.terminal_velocity(), -1.0, 1.0)

#############################################
##  E V E N T S                            ##
#############################################

func _on_roll_pressed() -> void:
	_roll_buffer_timer = roll_buffer_max

## The base owns the facing VALUE; the sprite flip is a per-character visual,
## so Player is the one that reacts to the signal rather than the base.
func _on_facing_changed(new_facing: int) -> void:
	_sprite.flip_h = new_facing < 0

#############################################
##  L O C O M O T I O N                    ##
#############################################

func _air_physics(delta: float) -> void:
	if not _wall_slide(delta):
		_jump.apply_gravity(delta)
	_locomotion.air_update(delta, move_axis())
	_landing.sample_fall_speed(velocity.y)

#############################################
##  J U M P I N G                          ##
#############################################

func _update_timers(delta: float, on_floor: bool) -> void:
	if on_floor:
		_double_jump.refresh()
		_roll_coyote_timer = roll_coyote_time_max
	else:
		_roll_coyote_timer = max(_roll_coyote_timer - delta, 0.0)

	if _roll_buffer_timer > 0.0:
		_roll_buffer_timer -= delta

	if _roll_timer > 0.0:
		_roll_timer = max(_roll_timer - delta, 0.0)
		if _roll_timer == 0.0:
			_roll_cooldown_timer = roll_cooldown
	elif _roll_cooldown_timer > 0.0:
		_roll_cooldown_timer = max(_roll_cooldown_timer - delta, 0.0)

func _try_jump(on_floor: bool) -> void:
	if is_recovering() or not _jump.has_buffered_jump():
		return

	_refresh_abilities()

	if _jump.try_ground_jump(on_floor):
		_is_wall_sliding = false
	elif _double_jump.try_jump():
		_is_wall_sliding = false

#############################################
##  A B I L I T I E S                      ##
#############################################

func _has_unlocked(skill: Enums.PlayerSkill) -> bool:
	return SaveSystem.has_skill(skill)

## Pushes the save-game skill gate onto the ability components, so they never
## learn SaveSystem exists and stay reusable by anything that wants to switch
## an ability off. Called at the moment an ability is attempted rather than
## every frame or cached at unlock time: the first is wasteful, and the second
## goes stale whenever a skill changes by a path that forgot to announce it.
func _refresh_abilities() -> void:
	_double_jump.enabled = _has_unlocked(Enums.PlayerSkill.DOUBLE_JUMP)

func _wall_slide(delta: float) -> bool:
	if _is_wall_sliding:
		if not is_on_wall() or sign(get_wall_normal().x) == sign(move_axis()):
			_is_wall_sliding = false
		else:
			velocity.y += base_gravity() * delta * wall_gravity_mult
			_jump.refresh_coyote()
			_double_jump.refresh()
	elif (
		_has_unlocked(Enums.PlayerSkill.WALL_CLIMB)
		and is_on_wall()
		and velocity.y >= 0
		and sign(move_axis() * -1) == sign(get_wall_normal().x)
	):
		_is_wall_sliding = true
		_jump.refresh_coyote()
		_double_jump.refresh()
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

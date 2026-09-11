class_name Player
extends Character

signal jumped(position: Vector2)
signal double_jumped(position: Vector2)
signal hard_landed(position: Vector2, impact_speed: float)

const GROUP := "player"

enum MotionState { KNOCKBACK, ROLL, GROUND, AIR }


@onready var _input           : PlayerInput = $PlayerInput
@onready var _locomotion      : LocomotionComponent = $Locomotion
@onready var _jump            : JumpComponent = $Jump
@onready var _landing         : LandingComponent = $Landing
@onready var _double_jump     : DoubleJumpComponent = $DoubleJump
@onready var _wall_mobility   : WallMobilityComponent = $WallMobility
@onready var _roll            : RollComponent = $Roll

var _states: CharacterStateMachine

func _enter_tree() -> void:
	add_to_group(GROUP)

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
	_input.roll_pressed.connect(_roll.buffer_roll)

	_double_jump.jump = _jump
	_wall_mobility.jump = _jump
	_wall_mobility.double_jump = _double_jump

	_states = CharacterStateMachine.new()
	_states.add_state(MotionState.KNOCKBACK, _knockback_motion)
	_states.add_state(MotionState.ROLL, _roll_motion)
	_states.add_state(MotionState.GROUND, _ground_motion)
	_states.add_state(MotionState.AIR, _air_physics)

func _process_motion(delta: float) -> void:
	var on_floor := is_on_floor()

	face_towards(move_axis())
	_jump.tick_timers(delta, on_floor)
	_roll.tick_timers(delta, on_floor)
	if on_floor:
		_double_jump.refresh()
	_landing.tick_timer(delta, on_floor)

	_states.transition_to(_select_motion_state(on_floor))
	_states.update(delta)

	_try_jump(on_floor)
	_try_roll(on_floor)

func _after_move(_delta: float) -> void:
	var on_floor := is_on_floor()
	_landing.check_landing(on_floor)
	if on_floor:
		_wall_mobility.stop()

#############################################
##  A N I M A T I O N   C O N T R A C T    ##
#############################################
## ivo.tscn's AnimationTree calls these by NAME, from advance_expression
## strings. Renaming one, or changing what it means, breaks animation SILENTLY
## at runtime — no compile error, no warning. Change the scene and the script
## together. The bound names are exactly:
##   wants_to_move, is_jumping, is_rising, is_falling, is_wall_sliding,
##   is_rolling, and the built-in is_on_floor.
## move_axis() and is_recovering() are NOT bound directly — they feed the ones
## that are, so renaming those two fails loudly at compile time instead.

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
	return _wall_mobility.is_sliding

func is_rolling() -> bool:
	return _roll.is_rolling()

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
##  L O C O M O T I O N                    ##
#############################################

## Mirrors the original branch order exactly: knockback overrides
## everything, then rolling, then ground vs air.
func _select_motion_state(on_floor: bool) -> MotionState:
	if is_in_knockback():
		return MotionState.KNOCKBACK
	if is_rolling():
		return MotionState.ROLL
	return MotionState.GROUND if on_floor else MotionState.AIR

func _knockback_motion(delta: float) -> void:
	_jump.apply_gravity(delta)
	apply_knockback_decay(delta)

## The roll component owns horizontal velocity for its whole duration, but
## vertical still belongs to gravity — otherwise rolling off a ledge hangs in
## the air until the roll expires. The component decelerates horizontally on
## its own once its movement phase ends, sliding to a stop through recovery.
func _roll_motion(delta: float) -> void:
	_jump.apply_gravity(delta)
	_roll.update(delta)

func _ground_motion(delta: float) -> void:
	_locomotion.ground_update(delta, move_axis())

func _air_physics(delta: float) -> void:
	_wall_mobility.enabled = _has_unlocked(Enums.PlayerSkill.WALL_CLIMB)
	if not _wall_mobility.update(delta, move_axis()):
		_jump.apply_gravity(delta)
	_locomotion.air_update(delta, move_axis())
	_landing.sample_fall_speed(velocity.y)

#############################################
##  J U M P I N G                          ##
#############################################

func _try_jump(on_floor: bool) -> void:
	# Rolling commits: the roll owns velocity for its whole duration, so
	# jumping out of it mid-way would fight that and skip the recovery the
	# cooldown is meant to enforce. The buffer keeps ticking during the roll,
	# so a jump pressed near the end still fires the moment it finishes.
	if is_recovering() or is_rolling() or not _jump.has_buffered_jump():
		return

	# The gate is pushed onto the component at the moment its ability is
	# attempted, so the component never learns SaveSystem exists, nothing is
	# cached that could go stale, and nothing is queried on frames where it
	# is not needed.
	_double_jump.enabled = _has_unlocked(Enums.PlayerSkill.DOUBLE_JUMP)

	if _jump.try_ground_jump(on_floor):
		_wall_mobility.stop()
	elif _double_jump.try_jump():
		_wall_mobility.stop()

func _try_roll(on_floor: bool) -> void:
	if not _roll.has_buffered_roll():
		return

	_roll.enabled = _has_unlocked(Enums.PlayerSkill.ROLL)
	_roll.try_roll(on_floor, move_axis(), facing)

#############################################
##  A B I L I T I E S                      ##
#############################################

func _has_unlocked(skill: Enums.PlayerSkill) -> bool:
	return SaveSystem.has_skill(skill)

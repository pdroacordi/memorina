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
@onready var _attack          : AttackComponent = $Attack
@onready var _pogo            : PogoComponent = $Pogo
@onready var _hitbox          : Hitbox = $Hitbox

## Per-sequence tuning data Ivo picks from at attack-start; a boss composing
## the same AttackComponent would never need this idle/run/air split.
@export var attack_stats_idle : AttackStats
@export var attack_stats_run  : AttackStats
@export var attack_stats_jump : AttackStats
@export var attack_stats_fall : AttackStats
@export var attack_stats_pogo : AttackStats

var _states: CharacterStateMachine
## Which AttackStats the current sequence started with, held fixed for its
## whole duration - the AnimationTree polls this to pick idle vs run vs the
## single-phase air states. Empty string while not attacking.
var _attack_context: StringName = &""
## Overlapping safe-room/NPC zones must combine additively: exiting an inner
## zone while still inside an outer one must not re-enable combat.
var _combat_disable_count: int = 0

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
	_input.attack_pressed.connect(_attack.buffer_attack)
	_attack.phase_started.connect(_on_attack_phase_started)
	_hitbox.connected.connect(_on_hitbox_connected)
	# facing_changed only fires on a CHANGE, so without this the hitbox would
	# sit at its authored (facing-right) offset until the first turn, wrong
	# whenever Ivo starts a scene already facing left.
	_hitbox._on_character_facing_changed(facing)

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
	_attack.tick_timers(delta)
	_pogo.enabled = _can_use_sword()
	if on_floor:
		_double_jump.refresh()
	_landing.tick_timer(delta, on_floor)

	_states.transition_to(_select_motion_state(on_floor))
	_states.update(delta)

	_try_jump(on_floor)
	_try_roll(on_floor)
	_try_attack()

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
##   is_rolling, is_attacking, attack_phase_index, attack_context, and the
##   built-in is_on_floor.
## move_axis() and is_recovering() are NOT bound directly — they feed the ones
## that are, so renaming those two fails loudly at compile time instead.

func move_axis() -> float:
	if is_recovering() or is_rolling() or is_in_knockback():
		return 0.0
	# Only the standing-still combo plants Ivo in place; the run-context combo
	# already keeps moving, and all three air attacks (jump/fall/pogo) must
	# keep horizontal control too, or landing a pogo chain becomes impossible.
	if is_attacking() and _attack_context == &"idle":
		return 0.0
	return _input.direction

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

func is_attacking() -> bool:
	return _attack.is_attacking()

func attack_phase_index() -> int:
	return _attack.current_phase_index

func attack_context() -> StringName:
	return _attack_context

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
	if is_recovering() or is_rolling() or not _jump.has_buffered_jump() or is_attacking():
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
	if is_attacking() or not _roll.has_buffered_roll():
		return

	_roll.enabled = _has_unlocked(Enums.PlayerSkill.ROLL)
	_roll.try_roll(on_floor, move_axis(), facing)

#############################################
##  A T T A C K I N G                      ##
#############################################

## Resolved here rather than inside the attack_pressed signal handler: the
## buffer (see AttackComponent.buffer_attack/has_buffered_attack) survives
## across frames exactly like RollComponent's/JumpComponent's own buffers, so
## a press that lands mid-roll/recovery/knockback isn't dropped - it fires
## the instant the gate clears - and reading the movement axis here, after
## this frame's input events are fully settled, avoids a same-frame race
## where a key release and the attack press could otherwise be read out of order.
func _try_attack() -> void:
	if not _attack.has_buffered_attack():
		return
	if is_recovering() or is_rolling() or is_in_knockback():
		return

	_attack.enabled = _can_use_sword()

	var context: StringName = _current_attack_context()
	if _attack.try_attack(_attack_stats_for(context)):
		_attack_context = context

func _on_attack_phase_started(_phase_index: int, phase: AttackPhaseData) -> void:
	_hitbox.damage = phase.damage
	_hitbox.knockback_strength = phase.knockback_strength
	_hitbox.knockback_lift = phase.knockback_lift

## Only the pogo attack's hit should bounce Ivo upward - the same shared
## Hitbox also lands every ground-combo and other air-attack hit, so this is
## the one place that knows which attack is currently connecting.
func _on_hitbox_connected(_target: Hurtbox) -> void:
	if _attack_context == &"pogo":
		_pogo.try_bounce()

## Context is resolved once, at the moment a NEW sequence starts (see
## _try_attack), and held in _attack_context for the sequence's whole
## duration - AttackComponent itself never branches on it.
func _current_attack_context() -> StringName:
	if not is_on_floor():
		if _input.look_direction > 0.0:
			return &"pogo"
		return &"jump" if is_rising() else &"fall"
	return &"run" if wants_to_move() else &"idle"

func _attack_stats_for(context: StringName) -> AttackStats:
	match context:
		&"run":
			return attack_stats_run
		&"jump":
			return attack_stats_jump
		&"fall":
			return attack_stats_fall
		&"pogo":
			return attack_stats_pogo
		_:
			return attack_stats_idle

## Item possession alone is not enough - sword use is also off wherever combat
## is disabled (safe rooms, NPC vicinity), tracked via _combat_disable_count.
func _can_use_sword() -> bool:
	return _has_item(Enums.PlayerItem.SWORD) and _combat_disable_count <= 0

## Wired per-scene from any CombatDisabledZone placed in a safe room or an
## NPC's own scene - see combat_disabled_zone.gd. A counter, not a bool,
## because overlapping zones must combine additively.
func _on_combat_zone_entered() -> void:
	_combat_disable_count += 1

func _on_combat_zone_exited() -> void:
	_combat_disable_count -= 1

#############################################
##  A B I L I T I E S                      ##
#############################################

func _has_unlocked(skill: Enums.PlayerSkill) -> bool:
	return SaveSystem.has_skill(skill)

func _has_item(item: Enums.PlayerItem) -> bool:
	return SaveSystem.has_item(item)

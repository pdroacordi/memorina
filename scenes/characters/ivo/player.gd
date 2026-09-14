class_name Player
extends Character

signal jumped(position: Vector2)
signal double_jumped(position: Vector2)
signal hard_landed(position: Vector2, impact_speed: float)

const GROUP := "player"

## Which AttackStats a sequence was started with. Gameplay, not animation:
## one context spans several clips (a combo), and the resolver maps between.
const CTX_IDLE := &"idle"
const CTX_RUN := &"run"
const CTX_JUMP := &"jump"
const CTX_FALL := &"fall"
const CTX_POGO := &"pogo"
const ATTACK_CONTEXTS: Array[StringName] = [CTX_IDLE, CTX_RUN, CTX_JUMP, CTX_FALL, CTX_POGO]
const AIR_ATTACK_CONTEXTS: Array[StringName] = [CTX_JUMP, CTX_FALL, CTX_POGO]

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
## A concrete view of Character's generic resolver, for the duration assert.
@onready var _player_resolver : PlayerAnimationResolver = $AnimationResolver

## Per-sequence tuning data Ivo picks from at attack-start; a boss composing
## the same AttackComponent would never need this idle/run/air split.
@export var attack_stats_idle : AttackStats
@export var attack_stats_run  : AttackStats
@export var attack_stats_jump : AttackStats
@export var attack_stats_fall : AttackStats
@export var attack_stats_pogo : AttackStats

var _states: CharacterStateMachine
## Which AttackStats the current sequence started with, held fixed for its
## whole duration - _attack_clip() reads it to pick idle vs run vs the
## single-phase air states. Empty string while not attacking.
var _attack_context: StringName = &""
## Overlapping safe-room/NPC zones must combine additively: exiting an inner
## zone while still inside an outer one must not re-enable combat.
var _combat_disable_count: int = 0
## A double jump has no lasting gameplay state of its own — afterwards Ivo is
## simply rising — so the event is exposed as a one-frame pulse. It fires
## inside _process_motion, so it is cleared at the top of the next one.
var _just_double_jumped: bool = false

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
	_double_jump.double_jumped.connect(_on_double_jumped)
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

	_assert_clip_durations()

func _process_motion(delta: float) -> void:
	_just_double_jumped = false
	if is_dead():
		# A corpse still falls and stops sliding; nothing else.
		_knockback_motion(delta)
		return

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
##  S T A T E   Q U E R I E S              ##
#############################################
## Read by PlayerAnimationResolver (and the camera); no animation logic here.

func _assert_clip_durations() -> void:
	_assert_clip_length(PlayerAnimationResolver.ROLL, _roll.stats.roll_time + _roll.stats.roll_recovery_time)
	for context in ATTACK_CONTEXTS:
		var stats := _attack_stats_for(context)
		for i in stats.phases.size():
			_assert_clip_length(_player_resolver.attack_clip_for(context, i), stats.phases[i].duration)

func move_axis() -> float:
	if is_recovering() or is_rolling() or is_in_knockback():
		return 0.0
	if is_attacking() and _attack_context == CTX_IDLE:
		return 0.0
	return _input.direction

func wants_to_move() -> bool:
	return not is_zero_approx(move_axis())

func is_jumping() -> bool:
	return _jump.is_jumping

func is_rising() -> bool:
	return velocity.y < 0.0

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

func just_landed() -> bool:
	return _landing.just_landed()

func just_double_jumped() -> bool:
	return _just_double_jumped

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

func air_axis() -> float:
	if is_on_floor():
		return 0.0
	return clampf(velocity.y / _jump.terminal_velocity(), -1.0, 1.0)

#############################################
##  L O C O M O T I O N                    ##
#############################################

func _select_motion_state(on_floor: bool) -> MotionState:
	if is_in_knockback():
		return MotionState.KNOCKBACK
	if is_rolling():
		return MotionState.ROLL
	return MotionState.GROUND if on_floor else MotionState.AIR

func _knockback_motion(delta: float) -> void:
	_jump.apply_gravity(delta)
	apply_knockback_decay(delta)

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
	if is_recovering() or is_rolling() or not _jump.has_buffered_jump() or is_attacking():
		return

	_double_jump.enabled = _has_unlocked(Enums.PlayerSkill.DOUBLE_JUMP)

	if _jump.try_ground_jump(on_floor):
		_wall_mobility.stop()
	elif _double_jump.try_jump():
		_wall_mobility.stop()

func _on_double_jumped(jump_position: Vector2) -> void:
	_just_double_jumped = true
	double_jumped.emit(jump_position)

func _try_roll(on_floor: bool) -> void:
	if is_attacking() or not _roll.has_buffered_roll():
		return

	_roll.enabled = _has_unlocked(Enums.PlayerSkill.ROLL)
	_roll.try_roll(on_floor, move_axis(), facing)

#############################################
##  A T T A C K I N G                      ##
#############################################

func _try_attack() -> void:
	if not _attack.has_buffered_attack():
		return
	if is_recovering() or is_rolling() or is_in_knockback():
		return

	_attack.enabled = _can_use_sword()

	var context: StringName = _current_attack_context()
	if _attack.try_attack(_attack_stats_for(context)):
		_attack_context = context

func _on_hit_received(damage: int, knockback: Vector2, source: Node2D) -> void:
	super(damage, knockback, source)
	_attack.cancel()

func _on_attack_phase_started(_phase_index: int, phase: AttackPhaseData) -> void:
	_hitbox.damage = phase.damage
	_hitbox.knockback_strength = phase.knockback_strength
	_hitbox.knockback_lift = phase.knockback_lift
	# A sequence can end and a new one begin in the same frame (a pogo chain),
	# leaving the clip name unchanged — the swing still has to restart.
	_animation_driver.request_replay()

## Only the pogo attack's hit should bounce Ivo upward - the same shared
## Hitbox also lands every ground-combo and other air-attack hit, so this is
## the one place that knows which attack is currently connecting.
func _on_hitbox_connected(_target: Hurtbox) -> void:
	if _attack_context == CTX_POGO:
		_pogo.try_bounce()

## Context is resolved once, at the moment a NEW sequence starts (see
## _try_attack), and held in _attack_context for the sequence's whole
## duration - AttackComponent itself never branches on it.
func _current_attack_context() -> StringName:
	if not is_on_floor():
		if _input.look_direction > 0.0:
			return CTX_POGO
		return CTX_JUMP if is_rising() else CTX_FALL
	return CTX_RUN if wants_to_move() else CTX_IDLE

func _attack_stats_for(context: StringName) -> AttackStats:
	match context:
		CTX_RUN:
			return attack_stats_run
		CTX_JUMP:
			return attack_stats_jump
		CTX_FALL:
			return attack_stats_fall
		CTX_POGO:
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

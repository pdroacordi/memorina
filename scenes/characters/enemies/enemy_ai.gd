class_name EnemyAI
extends AIController
## The combat machine every creature shares: wake, take the nearest visible presence, approach, throw the first
## move whose reach holds it, recover (docs/knowledge/systems/creatures.md). A movement style overrides only
## the motion hooks `_idle_tick`, `_approach_tick`, `_home_tick`, `_active_tick` and `_recover_tick`.

signal move_telegraphed(move: EnemyMove)
signal move_started(move: EnemyMove)
signal move_finished(move: EnemyMove)

enum State { DORMANT, IDLE, APPROACH, HOME, TELEGRAPH, ACTIVE, RECOVER }

## Distance from home under which a creature walking back counts as there, px.
const HOME_TOLERANCE := 8.0
## Where a flyer aims on a target, px from the target's feet (the centre of Ivo's hurtbox).
const CHEST := Vector2(0.0, -28.0)
## Horizontal steer under which a creature keeps its facing, px/s; a flyer settling on a point steers a little.
const FACE_DEADBAND := 12.0

## Pushed by Enemy before the first tick.
var stats: EnemyStats
## Desired velocity, px/s.
var steer: Vector2 = Vector2.ZERO
## Written by the body each physics frame: no floor ahead on the side it last faced.
var ledge_ahead: bool = false

var _clock := MoveClock.new()
var _side := SideTracker.new()
## What it goes for this frame, chosen once per tick before the state is.
var _target: Node2D = null
var _home: Vector2 = Vector2.ZERO
var _awake: bool = false
## Side the current move was aimed at, -1/1; held until it ends.
var _move_side: float = 1.0
## Side it last faced, -1/1: the side `ledge_ahead` was measured on.
var _facing: float = 1.0

@onready var _body: Node2D = get_parent()
@onready var _sight: EnemySight = get_parent().get_node(^"EnemySight") as EnemySight


func _ready() -> void:
	_states.add_state(State.DORMANT, _dormant_tick)
	_states.add_state(State.IDLE, _idle_tick)
	_states.add_state(State.APPROACH, _approach_tick)
	_states.add_state(State.HOME, _home_tick)
	_states.add_state(State.TELEGRAPH, _telegraph_tick)
	_states.add_state(State.ACTIVE, _active_tick)
	_states.add_state(State.RECOVER, _recover_tick)
	_clock.phase_entered.connect(_on_phase_entered)
	_states.transition_to(State.DORMANT)

## The clock decays before the state is chosen, so a cooldown that ends this tick can start a move this tick.
func tick(delta: float) -> void:
	_target = _sight.visible_presence() if _awake else null
	if _target != null:
		_side.update(_target.global_position.x - _body.global_position.x)
	_clock.tick(delta)
	super.tick(delta)
	var facing := facing_direction
	if not is_zero_approx(facing):
		_facing = facing

## Starts acting from where it stands, which becomes home.
func wake() -> void:
	if _awake:
		return
	_awake = true
	_home = _body.global_position

## A hit cancels a telegraph, and a hit window unless the move is armoured; the cooldown is kept.
func on_hurt() -> void:
	if _clock.phase == MoveClock.Phase.TELEGRAPH \
			or (_clock.phase == MoveClock.Phase.ACTIVE and not _clock.move.armoured):
		var move := _clock.move
		_clock.cancel()
		move_finished.emit(move)

## A new wall contact; ends a move that ends on walls.
func handle_wall_contact() -> void:
	if _clock.phase == MoveClock.Phase.ACTIVE and _clock.move.ends_on_wall:
		_clock.end_active()

func is_awake() -> bool:
	return _awake

## At home (asleep counts): a ceiling creature hangs, a thread creature rests at its anchor.
func is_home() -> bool:
	return not _awake or not _away_from_home()

func is_telegraphing() -> bool:
	return _clock.phase == MoveClock.Phase.TELEGRAPH

func is_active() -> bool:
	return _clock.phase == MoveClock.Phase.ACTIVE

func is_recovering() -> bool:
	return _clock.phase == MoveClock.Phase.RECOVER

## TELEGRAPH, ACTIVE or RECOVER: a move holds the creature.
func is_busy() -> bool:
	return _clock.is_busy()

## The move being thrown or cooling down; null when READY.
func current_move() -> EnemyMove:
	return _clock.move

func _get_direction() -> float:
	return signf(steer.x)

## A move keeps its side; standing with a target, it faces the target; otherwise where it moves.
## See docs/knowledge/bugs/the-brute-swings-away-from-a-target-already-in-reach.md.
func _get_facing_direction() -> float:
	if _clock.is_busy():
		return _move_side
	if absf(steer.x) < FACE_DEADBAND:
		return _side.side if _target != null else 0.0
	return signf(steer.x)

func _select_state() -> int:
	if not _awake:
		return State.DORMANT
	match _clock.phase:
		MoveClock.Phase.TELEGRAPH:
			return State.TELEGRAPH
		MoveClock.Phase.ACTIVE:
			return State.ACTIVE
		MoveClock.Phase.RECOVER:
			return State.RECOVER
	if _target != null:
		if _clock.phase == MoveClock.Phase.READY:
			var move := _move_in_reach(_side.side)
			if move != null:
				_move_side = _side.side
				_clock.start(move)
				return State.TELEGRAPH
		return State.APPROACH
	if _away_from_home():
		return State.HOME
	return State.IDLE

func _move_in_reach(side: float) -> EnemyMove:
	for move: EnemyMove in stats.moves:
		if EnemyReach.holds(move.reach, side, _body.global_position, _target.global_position):
			return move
	return null

## A wanderer goes home only from past its leash; a creature that holds its ground goes home from anywhere.
func _away_from_home() -> bool:
	var away := absf(_body.global_position.x - _home.x)
	if stats.wanders:
		return stats.leash > 0.0 and away > stats.leash
	return away > HOME_TOLERANCE

func _dormant_tick(_delta: float) -> void:
	steer = Vector2.ZERO

func _idle_tick(_delta: float) -> void:
	steer = Vector2.ZERO

func _approach_tick(_delta: float) -> void:
	steer = Vector2.ZERO

func _home_tick(_delta: float) -> void:
	steer = Vector2.ZERO

func _telegraph_tick(_delta: float) -> void:
	steer = Vector2.ZERO

func _active_tick(_delta: float) -> void:
	steer = Vector2.ZERO

func _recover_tick(_delta: float) -> void:
	steer = Vector2.ZERO

## A style's hook on a move phase, before the phase's first tick (an aim or a path is locked here).
func _enter_phase(_phase: MoveClock.Phase) -> void:
	pass

func _on_phase_entered(phase: MoveClock.Phase) -> void:
	_enter_phase(phase)
	match phase:
		MoveClock.Phase.TELEGRAPH:
			move_telegraphed.emit(_clock.move)
		MoveClock.Phase.ACTIVE:
			move_started.emit(_clock.move)
		MoveClock.Phase.RECOVER:
			move_finished.emit(_clock.move)

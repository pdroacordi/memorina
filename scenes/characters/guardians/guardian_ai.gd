class_name GuardianAI
extends AIController
## Chooses attacks and movement during the pressure phase; the guardian sets `active` and attack data.

signal attack_telegraphed(attack: GuardianAttack)
signal attack_started(attack: GuardianAttack)
signal attack_finished(attack: GuardianAttack)

## Horizontal dead band, in px, for movement and facing.
const TURN_BAND := 10.0
## Horizontal entry and exit bands, in px, for escaping an overhead player.
const OVERHEAD_BAND := 64.0
const ESCAPED_BAND := 150.0
## Lunge and minimum escape durations, in seconds.
const STEP_OUT_TIME := 0.55
const ESCAPE_MIN_TIME := 0.9
## Seconds the player must remain within reach before escape ends.
const ESCAPE_RELEASE_TIME := 0.3
## Fraction of the tallest attack height used as the reach release threshold.
const REACH_RELEASE := 0.8
## Comfort-distance multipliers for entering give-ground and close modes.
const COMFORT_NEAR := 0.7
const COMFORT_FAR := 1.3

## What it is doing about the spacing while a cooldown runs.
const PACE := 0
const GIVE_GROUND := 1
const CLOSE := 2

const APPROACH := 0
const TELEGRAPH := 1
const ATTACK := 2
const HOLD := 3

## The repertoire, pushed in from GuardianStats by the guardian.
var attacks: Array[GuardianAttack] = []
## Ordinary moves between two scheduled recall moves; 0 disables the schedule.
var recall_after_attacks: int = 0
## False outside the pressure phase: the guardian stands where it is.
var active: bool = false
## Multiplier on every cooldown; the guardian lowers it as the fight's
## aggression rises.
var cooldown_scale: float = 1.0
## Spacing and pacing, pushed in from GuardianStats by the guardian.
var comfort_distance: float = 140.0
var pace_time: float = 0.9
var pace_speed: float = 0.5
var step_out_speed: float = 1.7
## The move in progress (telegraph or swing), or null.
var current_attack: GuardianAttack = null

var _next: GuardianAttack = null
var _telegraph_timer: float = 0.0
var _attack_timer: float = 0.0
var _cooldown: float = 0.0
var _swinging: bool = false
## Ordinary moves made since the last scheduled recall move.
var _since_recall: int = 0
## Which way the guardian is looking when it is not walking.
var _look_direction: float = 1.0
## The escape from under a player: which way, how much lunge is left, how long
## it has run, and how long the player has been back within reach.
var _escaping: bool = false
var _escape_direction: float = 0.0
var _escape_lunge_left: float = 0.0
var _escape_time: float = 0.0
var _escape_release: float = 0.0
## Whether the player is out of reach overhead, held sticky: see _update_reach.
var _above_reach: bool = false
var _above_release: float = 0.0
## Which way it is pacing while it waits out a cooldown, and for how long.
var _spacing: int = PACE
var _pace_direction: float = 1.0
var _pace_left: float = 0.0
## The guardian asked for the recall move next, cadence or not.
var _recall_requested: bool = false

@onready var _body: Node2D = get_parent()
@onready var _sight: EnemySight = get_parent().get_node("EnemySight") as EnemySight


func _ready() -> void:
	_states.add_state(APPROACH, _approach_tick)
	_states.add_state(TELEGRAPH, _telegraph_tick)
	_states.add_state(ATTACK, _attack_tick)
	_states.add_state(HOLD, _hold_tick)
	_states.transition_to(HOLD)

## The cooldown decays every tick regardless of state, so it is up to date
## before _select_state reads it this same frame (see BruteShadowAI).
func tick(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	_update_look()
	super.tick(delta)

## The side the guardian should face: where it walks, or - standing still -
## where the player is. Read by the guardian instead of `direction`, so it
## keeps watching a player it has just backed away from.
func facing_intent() -> float:
	if not is_zero_approx(_current_direction):
		return _current_direction
	return _look_direction

## True from the telegraph's start to the swing's end.
func is_attacking() -> bool:
	return current_attack != null

func is_telegraphing() -> bool:
	return current_attack != null and not _swinging

func is_swinging() -> bool:
	return _swinging

## Getting out from under a player standing on it.
func is_escaping() -> bool:
	return _escaping

## The next move is the recall move, whatever the cadence says: the player
## has done their part and is not kept waiting for it.
func request_recall() -> void:
	if _recall_move() == null:
		return
	_recall_requested = true
	if not is_attacking():
		_pick_next()

## A counter: the cooldown is dropped so the next move starts as soon as it is
## in range. Nothing while a move is already under way.
func provoke() -> void:
	if is_attacking():
		return
	_cooldown = 0.0

## Drops the move without a cooldown: lucidity interrupts, it does not rest.
func cancel_attack() -> void:
	if current_attack == null:
		return
	var attack := current_attack
	current_attack = null
	_swinging = false
	_telegraph_timer = 0.0
	_attack_timer = 0.0
	attack_finished.emit(attack)

func _select_state() -> int:
	if not active or _sight.player == null or attacks.is_empty():
		_escaping = false
		return HOLD
	if is_attacking():
		return ATTACK if _swinging else TELEGRAPH
	_refresh_next()
	if not _escaping and _cooldown <= 0.0 and _in_range(_next):
		_start_telegraph(_next)
		return TELEGRAPH
	return APPROACH


## Everything the guardian does between swings.
func _approach_tick(delta: float) -> void:
	var to_player := _sight.player.global_position - _body.global_position
	_update_reach(to_player, delta)
	if _update_escape(to_player, delta):
		return
	if _cooldown > 0.0:
		_hold_spacing(to_player, delta)
		return
	if _in_range(_next):
		_current_direction = 0.0
		return
	# Avoid moving beneath an overhead player the current attacks cannot reach.
	if _above_reach:
		_hold_spacing(to_player, delta)
		return
	_close_in(to_player)

## Is the player out of reach overhead? Held with hysteresis in BOTH axes: it
## becomes true the moment they rise past the tallest move, and false only
## once they have been clearly back inside it (REACH_RELEASE of the height,
## for ESCAPE_RELEASE_TIME seconds). A pogo crosses that line three times a
## second, and an answer taken from the raw height each frame is the whole of
## the dithering this AI is written to avoid.
func _update_reach(to_player: Vector2, delta: float) -> void:
	var above := -to_player.y
	var tallest := _tallest_reach()
	if above > tallest:
		_above_reach = true
		_above_release = 0.0
		return
	if not _above_reach:
		return
	if above > tallest * REACH_RELEASE:
		_above_release = 0.0
		return
	_above_release += delta
	if _above_release >= ESCAPE_RELEASE_TIME:
		_above_reach = false
		_above_release = 0.0

## The escape from under a player standing on the guardian: entered inside
## OVERHEAD_BAND, left only once it is ESCAPED_BAND clear or the player has
## been back within reach for ESCAPE_RELEASE_TIME, and never before
## ESCAPE_MIN_TIME. True while it owns the movement.
func _update_escape(to_player: Vector2, delta: float) -> bool:
	var on_top := absf(to_player.x) <= OVERHEAD_BAND and _above_reach
	if not _escaping:
		if not on_top:
			return false
		_escaping = true
		_escape_direction = -signf(to_player.x) if absf(to_player.x) > 1.0 else _look_direction
		_escape_lunge_left = STEP_OUT_TIME
		_escape_time = 0.0
		_escape_release = 0.0

	_escape_time += delta
	# Require a continuous landing interval to end the escape.
	_escape_release = 0.0 if _above_reach else _escape_release + delta
	if _escape_time >= ESCAPE_MIN_TIME:
		var clear := absf(to_player.x) >= ESCAPED_BAND
		var landed := _escape_release >= ESCAPE_RELEASE_TIME
		if clear or landed:
			_escaping = false
			if landed:
				# Allow an attack immediately after the player lands.
				_cooldown = 0.0
			return false

	if _escape_lunge_left > 0.0:
		_escape_lunge_left -= delta
		_current_direction = _escape_direction * step_out_speed
	else:
		_hold_spacing(to_player, delta)
	return true

## Walks toward the player, keeping the last side inside the dead band:
## sign() of an x that sits on the guardian's own is the flip-flop this avoids.
func _close_in(to_player: Vector2) -> void:
	if absf(to_player.x) > TURN_BAND:
		_current_direction = signf(to_player.x)

## Holds spacing during cooldown with hysteresis at the comfort-distance thresholds.
func _hold_spacing(to_player: Vector2, delta: float) -> void:
	if comfort_distance <= 0.0:
		_current_direction = 0.0
		return
	var distance := absf(to_player.x)
	var toward := signf(to_player.x) if distance > TURN_BAND else _look_direction
	_update_spacing_mode(distance)
	match _spacing:
		GIVE_GROUND:
			_current_direction = -toward * pace_speed
		CLOSE:
			_current_direction = toward * pace_speed
		_:
			_pace_left -= delta
			if _pace_left <= 0.0:
				_pace_left = pace_time
				_pace_direction = -_pace_direction
			_current_direction = _pace_direction * pace_speed

func _update_spacing_mode(distance: float) -> void:
	match _spacing:
		GIVE_GROUND:
			if distance >= comfort_distance:
				_spacing = PACE
		CLOSE:
			if distance <= comfort_distance:
				_spacing = PACE
		_:
			if distance < comfort_distance * COMFORT_NEAR:
				_spacing = GIVE_GROUND
			elif distance > comfort_distance * COMFORT_FAR:
				_spacing = CLOSE

func _telegraph_tick(delta: float) -> void:
	_current_direction = 0.0
	_telegraph_timer -= delta
	if _telegraph_timer <= 0.0:
		_start_swing()

func _attack_tick(delta: float) -> void:
	_current_direction = 0.0
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_finish_attack()

func _hold_tick(_delta: float) -> void:
	_current_direction = 0.0

func _update_look() -> void:
	if _sight.player == null:
		return
	var dx := _sight.player.global_position.x - _body.global_position.x
	if absf(dx) > TURN_BAND:
		_look_direction = signf(dx)


func _start_telegraph(attack: GuardianAttack) -> void:
	current_attack = attack
	_swinging = false
	_telegraph_timer = attack.telegraph
	_current_direction = 0.0
	attack_telegraphed.emit(attack)
	if attack.telegraph <= 0.0:
		_start_swing()

func _start_swing() -> void:
	_swinging = true
	_attack_timer = current_attack.duration
	attack_started.emit(current_attack)

func _finish_attack() -> void:
	var attack := current_attack
	current_attack = null
	_swinging = false
	_cooldown = attack.cooldown * cooldown_scale
	if attack.recall != null:
		_since_recall = 0
		_recall_requested = false
	else:
		_since_recall += 1
	_pick_next()
	attack_finished.emit(attack)

## A move reaches inside a box, not a radius: `attack_range` to the side and
## `attack_height` up or down from its own feet.
func _in_range(attack: GuardianAttack) -> bool:
	if attack == null:
		return false
	var to_player := _sight.player.global_position - _body.global_position
	return absf(to_player.x) <= attack.attack_range and absf(to_player.y) <= attack.attack_height

func _tallest_reach() -> float:
	var tallest := 0.0
	for attack: GuardianAttack in attacks:
		tallest = maxf(tallest, attack.attack_height)
	return tallest

## Selects a due recall, a situational move, or a weighted move; weight 0 only permits scheduling.
func _pick_next() -> void:
	var recall_move := _recall_move()
	var due := recall_after_attacks > 0 and _since_recall >= recall_after_attacks
	if recall_move != null and (due or _recall_requested):
		_next = recall_move
		return
	var situational := _situational_pick()
	_next = situational if situational != null else _weighted_pick()

## Keeps the selected move until a situational condition changes.
func _refresh_next() -> void:
	if _next == null:
		_pick_next()
		return
	var recall_move := _recall_move()
	var due := recall_after_attacks > 0 and _since_recall >= recall_after_attacks
	if recall_move != null and (due or _recall_requested):
		_next = recall_move
		return
	var opinion := _situational_pick()
	if opinion != null:
		_next = opinion

## Returns an attack suited to an overhead or distant player, or null when neither applies.
func _situational_pick() -> GuardianAttack:
	var to_player := _sight.player.global_position - _body.global_position
	var above := -to_player.y
	var distance := absf(to_player.x)
	if above > 0.0:
		var reaches_up: GuardianAttack = null
		for attack: GuardianAttack in attacks:
			if attack.weight <= 0.0 or attack.attack_height < above:
				continue
			if distance > attack.attack_range:
				continue
			if reaches_up == null or attack.attack_height > reaches_up.attack_height:
				reaches_up = attack
		if reaches_up != null:
			return reaches_up
	# Require distance beyond the comfort band to avoid always selecting the longest attack.
	if comfort_distance > 0.0 and distance > comfort_distance * COMFORT_FAR:
		var longest: GuardianAttack = null
		for attack: GuardianAttack in attacks:
			if attack.weight <= 0.0:
				continue
			if longest == null or attack.attack_range > longest.attack_range:
				longest = attack
		if longest != null and longest.attack_range >= distance:
			return longest
	return null

func _weighted_pick() -> GuardianAttack:
	var total := 0.0
	for attack: GuardianAttack in attacks:
		total += maxf(attack.weight, 0.0)
	if total <= 0.0:
		return attacks[0]
	var roll := randf() * total
	for attack: GuardianAttack in attacks:
		roll -= maxf(attack.weight, 0.0)
		if attack.weight > 0.0 and roll <= 0.0:
			return attack
	return attacks[attacks.size() - 1]

func _recall_move() -> GuardianAttack:
	for attack: GuardianAttack in attacks:
		if attack.recall != null:
			return attack
	return null

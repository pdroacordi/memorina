class_name GuardianAI
extends AIController
## The pressure phase's movement and attack picking. Walks toward the player
## until the next chosen move is in range, telegraphs it (holds still so the
## wind-up can be read), swings, waits out its cooldown, picks another, and
## repeats. Which moves exist is data (GuardianAttack); whether the AI may act
## at all is pushed in through `active` by the guardian, which is the only
## node that knows the fight's phase. Never instantiated on its own: a
## Guardian mounts it as $AI.
##
## A player bouncing on its head is not a free ride either: a move only
## reaches inside its own box (range x height), so a guardian cannot swing at
## someone hovering overhead - it STEPS OUT from under them instead and
## stands off until they come down, rather than shuffling on the spot under
## their feet. Which moves can answer an overhead player is data
## (GuardianAttack.attack_height).
##
## The move carrying a recall is not left to chance: it is scheduled every
## `recall_after_attacks` ordinary moves (a phase the player can learn to
## expect), or at once when the guardian asks for it (request_recall), whether
## or not the skill has been remembered yet - the guardian decides if a recall
## opens; the AI only supplies the rhythm. A guardian being mashed asks for a
## counter the same way (provoke).

signal attack_telegraphed(attack: GuardianAttack)
signal attack_started(attack: GuardianAttack)
signal attack_finished(attack: GuardianAttack)

## How far the player must be to one side before the guardian picks a new
## side to walk or look at. Inside this band it keeps what it had: someone
## standing exactly overhead must not make it turn every frame.
const TURN_BAND := 10.0
## Horizontal reach of "overhead": within this, a player above the move's box
## is standing on the guardian rather than in front of it.
const OVERHEAD_BAND := 56.0
## Seconds the guardian walks to get out from under such a player.
const STEP_OUT_TIME := 0.7

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
## The move in progress (telegraph or swing), or null.
var current_attack: GuardianAttack = null

var _next: GuardianAttack = null
var _telegraph_timer: float = 0.0
var _attack_timer: float = 0.0
var _cooldown: float = 0.0
var _swinging: bool = false
## Ordinary moves made since the last scheduled recall move.
var _since_recall: int = 0
## Which way the guardian is looking when it is not walking, and how much of
## the step out from under an overhead player is left.
var _look_direction: float = 1.0
var _step_out_direction: float = 0.0
var _step_out_left: float = 0.0
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

func _update_look() -> void:
	if _sight.player == null:
		return
	var dx := _sight.player.global_position.x - _body.global_position.x
	if absf(dx) > TURN_BAND:
		_look_direction = signf(dx)

## True from the telegraph's start to the swing's end.
func is_attacking() -> bool:
	return current_attack != null

func is_telegraphing() -> bool:
	return current_attack != null and not _swinging

func is_swinging() -> bool:
	return _swinging

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
		return HOLD
	if is_attacking():
		return ATTACK if _swinging else TELEGRAPH
	if _next == null:
		_pick_next()
	if _cooldown <= 0.0 and _in_range(_next):
		_start_telegraph(_next)
		return TELEGRAPH
	return APPROACH

## Closes in, and stops once the chosen move is already in range rather than
## walking into the player's collider (the BruteShadowAI fix). A player
## overhead and out of the move's reach is walked out from under, once, and
## then waited out: a guardian is not a trampoline, and chasing an x that sits
## on top of its own would only flip it left and right on the spot.
func _approach_tick(delta: float) -> void:
	var to_player := _sight.player.global_position - _body.global_position
	if _next != null and _in_range(_next):
		_current_direction = 0.0
		_cancel_step_out()
		return
	if _is_overhead(to_player, _next):
		_step_out(to_player, delta)
		return
	_cancel_step_out()
	# Inside the band the last side is kept; sign() of an x that is ON the
	# guardian is the flip-flop this avoids.
	if absf(to_player.x) > TURN_BAND:
		_current_direction = signf(to_player.x)

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
	var to_player := _sight.player.global_position - _body.global_position
	return absf(to_player.x) <= attack.attack_range and absf(to_player.y) <= attack.attack_height

## Standing on the guardian rather than in front of it, and out of the reach
## of the move it was about to make.
func _is_overhead(to_player: Vector2, attack: GuardianAttack) -> bool:
	if attack == null or absf(to_player.x) > OVERHEAD_BAND:
		return false
	return -to_player.y > attack.attack_height

## Walks out from under for STEP_OUT_TIME, then stands its ground and watches:
## walking back in would put it under the same feet again.
func _step_out(to_player: Vector2, delta: float) -> void:
	if is_zero_approx(_step_out_direction):
		_step_out_direction = -signf(to_player.x) if absf(to_player.x) > 1.0 else _look_direction
		_step_out_left = STEP_OUT_TIME
	if _step_out_left > 0.0:
		_step_out_left -= delta
		_current_direction = _step_out_direction
	else:
		_current_direction = 0.0

func _cancel_step_out() -> void:
	_step_out_direction = 0.0
	_step_out_left = 0.0

## The recall move when its turn has come or was asked for; otherwise a
## weighted random pick among the rest. A move with weight 0 is only ever scheduled.
func _pick_next() -> void:
	var recall_move := _recall_move()
	var due := recall_after_attacks > 0 and _since_recall >= recall_after_attacks
	if recall_move != null and (due or _recall_requested):
		_next = recall_move
		return
	var total := 0.0
	for attack: GuardianAttack in attacks:
		total += maxf(attack.weight, 0.0)
	if total <= 0.0:
		_next = attacks[0]
		return
	var roll := randf() * total
	for attack: GuardianAttack in attacks:
		roll -= maxf(attack.weight, 0.0)
		if attack.weight > 0.0 and roll <= 0.0:
			_next = attack
			return
	_next = attacks[attacks.size() - 1]

func _recall_move() -> GuardianAttack:
	for attack: GuardianAttack in attacks:
		if attack.recall != null:
			return attack
	return null

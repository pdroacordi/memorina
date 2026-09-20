class_name GuardianAI
extends AIController
## The pressure phase's movement and attack picking. Walks toward the player
## until the next chosen move is in range, swings, waits out its cooldown,
## picks another by weight, and repeats. Which moves exist is data
## (GuardianAttack); whether the AI may act at all is pushed in through
## `active` by the guardian, which is the only node that knows the fight's
## phase. Never instantiated on its own: a Guardian mounts it as $AI.

signal attack_started(attack: GuardianAttack)
signal attack_finished(attack: GuardianAttack)

const APPROACH := 0
const ATTACK := 1
const HOLD := 2

## The repertoire, pushed in from GuardianStats by the guardian.
var attacks: Array[GuardianAttack] = []
## False outside the pressure phase: the guardian stands where it is.
var active: bool = false
## Multiplier on every cooldown; the guardian lowers it as the fight's
## aggression rises.
var cooldown_scale: float = 1.0
## The move in progress, or null.
var current_attack: GuardianAttack = null

var _next: GuardianAttack = null
var _attack_timer: float = 0.0
var _cooldown: float = 0.0

@onready var _body: Node2D = get_parent()
@onready var _sight: EnemySight = get_parent().get_node("EnemySight") as EnemySight


func _ready() -> void:
	_states.add_state(APPROACH, _approach_tick)
	_states.add_state(ATTACK, _attack_tick)
	_states.add_state(HOLD, _hold_tick)
	_states.transition_to(HOLD)

## The cooldown decays every tick regardless of state, so it is up to date
## before _select_state reads it this same frame (see BruteShadowAI).
func tick(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	super.tick(delta)

func is_attacking() -> bool:
	return current_attack != null

## Drops the swing without a cooldown: lucidity interrupts, it does not rest.
func cancel_attack() -> void:
	if current_attack == null:
		return
	var attack := current_attack
	current_attack = null
	_attack_timer = 0.0
	attack_finished.emit(attack)

func _select_state() -> int:
	if not active or _sight.player == null or attacks.is_empty():
		return HOLD
	if is_attacking():
		return ATTACK
	if _next == null:
		_pick_next()
	if _cooldown <= 0.0 and _in_range(_next):
		_start_attack(_next)
		return ATTACK
	return APPROACH

## Closes in, and stops once the chosen move is already in range rather than
## walking into the player's collider (the BruteShadowAI fix).
func _approach_tick(_delta: float) -> void:
	if _next != null and _in_range(_next):
		_current_direction = 0.0
	else:
		_current_direction = signf(_sight.player.global_position.x - _body.global_position.x)

func _attack_tick(delta: float) -> void:
	_current_direction = 0.0
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_finish_attack()

func _hold_tick(_delta: float) -> void:
	_current_direction = 0.0

func _start_attack(attack: GuardianAttack) -> void:
	current_attack = attack
	_attack_timer = attack.duration
	_current_direction = 0.0
	attack_started.emit(attack)

func _finish_attack() -> void:
	var attack := current_attack
	current_attack = null
	_cooldown = attack.cooldown * cooldown_scale
	_pick_next()
	attack_finished.emit(attack)

func _in_range(attack: GuardianAttack) -> bool:
	return _body.global_position.distance_to(_sight.player.global_position) <= attack.attack_range

## Weighted random over the repertoire. Nothing is remembered between picks:
## the unavoidable move is meant to come back "quantas vezes for necessario".
func _pick_next() -> void:
	var total := 0.0
	for attack: GuardianAttack in attacks:
		total += maxf(attack.weight, 0.0)
	if total <= 0.0:
		_next = attacks[0]
		return
	var roll := randf() * total
	for attack: GuardianAttack in attacks:
		roll -= maxf(attack.weight, 0.0)
		if roll <= 0.0:
			_next = attack
			return
	_next = attacks[attacks.size() - 1]

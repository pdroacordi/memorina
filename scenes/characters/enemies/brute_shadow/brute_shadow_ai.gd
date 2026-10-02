class_name BruteShadowAI
extends EnemyAI
## BruteShadow adds a stationary melee attack state to the common AI baseline.

const ATTACK := 2

@export var attack_stats: BruteShadowAttackStats

var is_attacking: bool = false

var _attack_timer: float = 0.0
var _attack_cooldown: float = 0.0


func _ready() -> void:
	super()
	_states.add_state(ATTACK, _attack_tick)

func tick(delta: float) -> void:
	# Decay before state selection so cooldown expiry can start an attack this tick.
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	super.tick(delta)

func _select_state() -> int:
	if is_attacking:
		return ATTACK
	if _attack_cooldown <= 0.0 and _in_melee_range():
		_start_attack()
		return ATTACK
	return super._select_state()

## Stops inside melee range while waiting for cooldown; the base chase has no stop distance.
func _chase_tick(delta: float) -> void:
	if _in_melee_range():
		_current_direction = 0.0
	else:
		super._chase_tick(delta)

func _attack_tick(delta: float) -> void:
	_current_direction = 0.0
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		is_attacking = false
		_attack_cooldown = attack_stats.attack_cooldown

func _start_attack() -> void:
	is_attacking = true
	_attack_timer = attack_stats.attack_duration
	_current_direction = 0.0

# Interruptions retain the cooldown so a flinch cannot trigger an immediate follow-up swing.
func cancel_attack() -> void:
	if is_attacking:
		is_attacking = false
		_attack_cooldown = attack_stats.attack_cooldown

func _in_melee_range() -> bool:
	return _target != null and _body.global_position.distance_to(_target.global_position) <= attack_stats.attack_range

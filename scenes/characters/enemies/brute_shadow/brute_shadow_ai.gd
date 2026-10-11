class_name BruteShadowAI
extends EnemyAI
## BruteShadow adds a stationary melee attack state to the common AI baseline.

const ATTACK := 2
## Horizontal dead band, in px: a target this close to overhead keeps the side it was last on.
const TURN_BAND := 10.0

@export var attack_stats: BruteShadowAttackStats

var is_attacking: bool = false

var _attack_timer: float = 0.0
var _attack_cooldown: float = 0.0
## Side the current swing was aimed at, -1/1; held until the swing ends.
var _swing_side: float = 0.0
## Side the target was last seen on outside TURN_BAND, -1/1.
var _side: float = 1.0


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

## Closes to `stop_distance` while the cooldown runs, so a brute that swung from afar ends up inside Ivo's reach.
## Horizontal only: a jump or a ledge above is not the target moving away
## (docs/knowledge/bugs/the-brute-walks-under-ivo-when-he-jumps-from-where-it-parks.md).
func _chase_tick(delta: float) -> void:
	if absf(_target.global_position.x - _body.global_position.x) <= attack_stats.stop_distance:
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
	_swing_side = _target_side()

# Interruptions retain the cooldown so a flinch cannot trigger an immediate follow-up swing.
func cancel_attack() -> void:
	if is_attacking:
		is_attacking = false
		_attack_cooldown = attack_stats.attack_cooldown

func _in_melee_range() -> bool:
	return _target != null and _body.global_position.distance_to(_target.global_position) <= attack_stats.attack_range

# In reach the brute stands still, so `direction` is 0 and cannot turn it: face the target, and keep a swing's side.
# See docs/knowledge/bugs/the-brute-swings-away-from-a-target-already-in-reach.md.
func _get_facing_direction() -> float:
	if is_attacking:
		return _swing_side
	if _in_melee_range():
		return _target_side()
	return super._get_facing_direction()

func _target_side() -> float:
	var dx := _target.global_position.x - _body.global_position.x
	if absf(dx) > TURN_BAND:
		_side = signf(dx)
	return _side

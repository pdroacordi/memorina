class_name BruteShadowAI
extends EnemyAI
## BruteShadow's only addition beyond the common wander/chase baseline: a
## melee ATTACK state that takes over once the player is within melee range,
## holding direction at 0.0 for the swing's full duration so it can't move or
## turn mid-attack. The swing itself (Hitbox timing, sprite frames) is
## entirely the AnimationTree's business — see brute_shadow.tscn's
## idle/walk -> attack transitions, gated by BruteShadow.should_attack(),
## which just reads `is_attacking` below.

const ATTACK := 2

@export var attack_stats: BruteShadowAttackStats

## Read by BruteShadow.should_attack() for the animation contract.
var is_attacking: bool = false

var _attack_timer: float = 0.0
var _attack_cooldown: float = 0.0


func _ready() -> void:
	super()
	_states.add_state(ATTACK, _attack_tick)

## Cooldown decays every tick regardless of state, not just while attacking —
## overridden here (rather than added to _select_state, which has no delta)
## so it's always up to date before _select_state reads it this same frame.
func tick(delta: float) -> void:
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	super.tick(delta)

func _select_state() -> int:
	if is_attacking:
		return ATTACK
	if _attack_cooldown <= 0.0 and _in_melee_range():
		_start_attack()
		return ATTACK
	return super._select_state()

## Overrides the inherited chase: once already within melee range (e.g.
## still on cooldown from the last swing), stop advancing instead of walking
## flush into the player — EnemyAI's own _chase_tick has no minimum distance
## at all, which otherwise leaves the AI trying to walk into the player's
## collider every frame, flipping facing back and forth as the collision
## response shoves it back each time.
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

func _in_melee_range() -> bool:
	return _sight.player != null and _body.global_position.distance_to(_sight.player.global_position) <= attack_stats.attack_range

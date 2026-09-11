class_name EnemyAI
extends AIController
## Baseline behavior for common enemies: wanders with random pauses and
## direction changes until the EnemySight sibling reports the player
## visible, then chases directly. A specific enemy needing more (an attack
## state, etc.) subclasses THIS — not AIController — and overrides
## _select_state() to fold its own state in ahead of the wander/chase pick.

const WANDER := 0
const CHASE := 1

@export var stats: EnemyAIStats

@onready var _body: Node2D = get_parent()
@onready var _sight: EnemySight = get_parent().get_node("EnemySight") as EnemySight

var _wander_timer: float = 0.0


func _ready() -> void:
	_states.add_state(WANDER, _wander_tick)
	_states.add_state(CHASE, _chase_tick)
	_states.state_changed.connect(_on_state_changed)
	_states.transition_to(WANDER)

func handle_wall_contact() -> void:
	if _states.current == WANDER:
		_pick_wander_phase()

func _select_state() -> int:
	return CHASE if _sight.is_player_visible() else WANDER

func _wander_tick(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_pick_wander_phase()

func _chase_tick(_delta: float) -> void:
	_current_direction = signf(_sight.player.global_position.x - _body.global_position.x)

func _pick_wander_phase() -> void:
	if randf() < 0.5:
		_current_direction = [-1.0, 1.0].pick_random()
		_wander_timer = randf_range(stats.min_wander_duration, stats.max_wander_duration)
	else:
		_current_direction = 0.0
		_wander_timer = randf_range(stats.min_idle_duration, stats.max_idle_duration)

func _on_state_changed(_from: int, to: int) -> void:
	if to == WANDER:
		_pick_wander_phase()

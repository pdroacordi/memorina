class_name BruteShadow
extends Enemy
## BruteShadow stays hidden and inactive until triggered, then joins the AI after its spawn animation.

@onready var _spawn_trigger : PlayerProximityTrigger = $SpawnTrigger
@onready var _anim_tree     : AnimationTree = %AnimationTree
## Specific attack-state reference used by the animation.
@onready var _brute_ai      : BruteShadowAI = $AI
## Concrete animation resolver reference used for spawning.
@onready var _brute_resolver: BruteShadowAnimationResolver = $AnimationResolver

var _spawn_done: bool = false


func _ready() -> void:
	super()
	if is_queued_for_deletion():
		return
	hide()
	# Keep the hurtbox inactive until spawn because its RESET track otherwise controls it.
	hurtbox.monitorable = false
	set_physics_process(false)
	_spawn_trigger.player_entered.connect(_on_player_entered)
	_assert_clip_length(BruteShadowAnimationResolver.ATTACK, _brute_ai.attack_stats.attack_duration)

func is_spawning() -> bool:
	return not _spawn_done

func is_attacking() -> bool:
	return _brute_ai.is_attacking

func wants_to_move() -> bool:
	return not is_zero_approx(_brute_ai.direction)

func _process_motion(delta: float) -> void:
	if is_spawning():
		return
	super(delta)

func _after_move(delta: float) -> void:
	if is_spawning():
		_spawn_done = _brute_resolver.is_spawn_finished()
		return
	super(delta)

func _on_player_entered() -> void:
	show()
	_anim_tree.active = true
	set_physics_process(true)

func _on_hit_received(damage: int, knockback: Vector2, source: Node2D) -> void:
	super(damage, knockback, source)
	_brute_ai.cancel_attack()

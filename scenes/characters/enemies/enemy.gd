class_name Enemy
extends Character

@export var save_id: String = ""

@export var terminal_velocity: float = 500.0

@onready var _ai         : AIController = $AI
@onready var _locomotion : LocomotionComponent = $Locomotion

var _was_on_wall: bool = false


func _ready() -> void:
	super()
	if not save_id.is_empty() and SaveSystem.is_enemy_defeated(save_id):
		hide()
		queue_free()
		return
	died.connect(_on_died)

func _on_died() -> void:
	if not save_id.is_empty():
		SaveSystem.mark_enemy_defeated(save_id)

func _process_motion(delta: float) -> void:
	if is_dead() or is_in_knockback():
		apply_knockback_decay(delta)
	else:
		_ai.tick(delta)
		face_towards(_ai.direction)
		_locomotion.ground_update(delta, _ai.direction)
	if not is_on_floor():
		velocity.y = minf(velocity.y + base_gravity() * delta, terminal_velocity)


func _after_move(_delta: float) -> void:
	if is_dead():
		if _animation_resolver.is_death_finished():
			queue_free()
		return
	var on_wall := is_on_wall()
	if on_wall and not _was_on_wall:
		_ai.handle_wall_contact()
	_was_on_wall = on_wall

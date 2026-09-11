class_name Enemy
extends Character

## Left empty (the default), this enemy respawns every time its room's
## contents reload, same as before. Set per-instance in the scene to opt an
## enemy into persistence: once defeated, it won't respawn again for the
## rest of the session (see SaveSystem.is_enemy_defeated/mark_enemy_defeated).
@export var save_id: String = ""

## Matches JumpStats' own default (see jump_stats.gd) — enemies have no
## JumpComponent of their own, but falling still needs the same cap: without
## one, a few consecutive airborne frames (stepping off a small ledge while
## chasing) let velocity.y grow unbounded until a single physics step moves
## it far enough to tunnel straight through the terrain collider.
@export var terminal_velocity: float = 500.0

@onready var _ai         : AIController = $AI
@onready var _locomotion : LocomotionComponent = $Locomotion

var _was_on_wall: bool = false


func _ready() -> void:
	super()
	if save_id.is_empty():
		return
	if SaveSystem.is_enemy_defeated(save_id):
		hide()
		queue_free()
		return
	died.connect(_on_died)

func _on_died() -> void:
	SaveSystem.mark_enemy_defeated(save_id)

func _process_motion(delta: float) -> void:
	_ai.tick(delta)
	face_towards(_ai.direction)
	_locomotion.ground_update(delta, _ai.direction)
	if not is_on_floor():
		velocity.y = minf(velocity.y + base_gravity() * delta, terminal_velocity)

## Reacts only on the frame contact BEGINS, not every frame it persists.
## is_on_wall() stays true for as long as the AI keeps pushing into the wall
## (velocity.x gets zeroed by the collision, but LocomotionComponent
## re-accelerates toward it next frame since `direction` hasn't changed), so
## an unguarded check here would re-roll a new wander phase every single
## physics frame instead of once per actual bump.
func _after_move(_delta: float) -> void:
	var on_wall := is_on_wall()
	if on_wall and not _was_on_wall:
		_ai.handle_wall_contact()
	_was_on_wall = on_wall

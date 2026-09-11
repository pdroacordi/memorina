class_name EnemySight
extends Area2D
## Broad-phase player detection (this Area2D's CollisionShape2D radius),
## confirmed by a narrow-phase RayCast2D against Terrain, so a wall between
## the enemy and the player blocks the chase like it would block real sight.

## Both Player and Enemy have their origin at their feet (the collision
## capsule sits ~27px above it). A ray cast from/to that raw origin runs
## right along the ground and clips terrain it has no business hitting, so
## both ends are lifted to roughly chest height before casting.
const SIGHT_HEIGHT_OFFSET := Vector2(0, -27)

@onready var _ray: RayCast2D = $RayCast2D

var player: Node2D = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func is_player_visible() -> bool:
	if player == null:
		return false
	_ray.target_position = _ray.to_local(player.global_position + SIGHT_HEIGHT_OFFSET)
	_ray.force_raycast_update()
	return not _ray.is_colliding()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(Player.GROUP):
		player = body

func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player = null

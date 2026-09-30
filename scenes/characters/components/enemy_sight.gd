class_name EnemySight
extends Area2D
## Broad-phase detection (this Area2D's CollisionShape2D radius) of the player
## and of every PRESENCE - whatever a creature takes for the hero: Ivo's body,
## and his burned shadow (Sombra, design 02 section 7.1), which is an area,
## not a body. Each is confirmed by a narrow-phase RayCast2D against Terrain,
## so a wall between them blocks the chase like it would block real sight.
##
## Two answers, because two kinds of mind read this: `player` is Ivo alone (a
## guardian fights HIM, never a shadow he left), and visible_presence() is the
## nearest presence in plain sight (a common creature goes for whichever it
## sees - that is what makes the shadow a lure).

## The group of everything a creature takes for the hero.
const PRESENCE := &"presence"

## Both Player and Enemy have their origin at their feet (the collision
## capsule sits ~27px above it). A ray cast from/to that raw origin runs
## right along the ground and clips terrain it has no business hitting, so
## both ends are lifted to roughly chest height before casting.
const SIGHT_HEIGHT_OFFSET := Vector2(0, -27)

var player: Node2D = null

var _presences: Array[Node2D] = []

@onready var _ray: RayCast2D = $RayCast2D


func _ready() -> void:
	body_entered.connect(_on_entered)
	body_exited.connect(_on_exited)
	area_entered.connect(_on_entered)
	area_exited.connect(_on_exited)

## The nearest presence in plain sight, or null. A presence that left the
## group (a shadow that broke) is no longer anyone.
func visible_presence() -> Node2D:
	var nearest: Node2D = null
	var best := INF
	for node: Node2D in _presences:
		var distance := global_position.distance_squared_to(node.global_position)
		# Distance first: the ray is the expensive part.
		if distance < best and node.is_in_group(PRESENCE) and can_see(node):
			nearest = node
			best = distance
	return nearest

func can_see(node: Node2D) -> bool:
	_ray.target_position = _ray.to_local(node.global_position + SIGHT_HEIGHT_OFFSET)
	_ray.force_raycast_update()
	return not _ray.is_colliding()

func _on_entered(node: Node2D) -> void:
	if node.is_in_group(Player.GROUP):
		player = node
	if node.is_in_group(PRESENCE) and not _presences.has(node):
		_presences.append(node)

func _on_exited(node: Node2D) -> void:
	if node == player:
		player = null
	_presences.erase(node)

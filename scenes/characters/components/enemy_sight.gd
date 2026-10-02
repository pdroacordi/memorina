class_name EnemySight
extends Area2D
## Detects visible presences; see docs/design/02_canções.md section 7.1.

const PRESENCE := &"presence"
## `player` is Ivo; `visible_presence()` may instead return his nearest visible shadow.

## Sight ray height above the feet in px.
# Raise both ray ends to avoid terrain clipping at their foot-level origins.
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

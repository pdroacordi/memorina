class_name TravelPoint
extends RefCounted
## Where Game.travel carries Ivo: a room, his feet in world px and the side he faces. Held in memory only.

var room: Room
var feet: Vector2
var facing: int


func _init(to: Room, at: Vector2, side: int) -> void:
	room = to
	feet = at
	facing = side

## Puts `player` there, standing, with no press pending.
func place(player: Player) -> void:
	player.arrive(feet, facing)

class_name TravelPoint
extends RefCounted
## Where Game.travel carries Ivo: a room, his feet in world px and the side he faces. Held in memory only.

var room: Room
var feet: Vector2
var facing: int
## Keeps his motion, pose and presses: the hidden swap into a twin room (flashback 5), where nothing may show a seam.
var keep_motion: bool = false


func _init(to: Room, at: Vector2, side: int) -> void:
	room = to
	feet = at
	facing = side

## Puts `player` there, standing, with no press pending; with `keep_motion`, only moves him.
func place(player: Player) -> void:
	if keep_motion:
		player.teleport(feet)
	else:
		player.arrive(feet, facing)

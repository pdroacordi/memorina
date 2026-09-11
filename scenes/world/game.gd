extends Node2D

## How many rooms (including the current one) stay resident — deactivated
## but not destroyed — at once. Backtracking within this many rooms of the
## current one keeps enemy position/AI/animation state intact; anything
## older gets evicted (see Room.evict()) and comes back fresh next visit.
const MAX_RESIDENT_ROOMS := 2

@onready var _fade   : Fade   = %Fade
@onready var _camera : GameCamera = %Camera2D
@onready var _player : Node2D = %Player
var _current_room    : Room
var _is_transitioning: bool      = false

## Most-recently-used first. A room only ever leaves this list via eviction
## (_touch_resident below), never just by being left — that's the whole
## point of keeping it "warm" instead of destroying it.
var _resident_rooms: Array[Room] = []

func _ready() -> void:
	_camera.follow(_player)
	for room: Room in get_tree().get_nodes_in_group(Room.GROUP):
		room.room_entered.connect(_on_player_entered_room)

func _on_player_entered_room(room: Room) -> void:
	if room == _current_room or _is_transitioning:
		return
	_is_transitioning = true
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	if _current_room:
		await _fade.to_black()
		_current_room.deactivate()
	_current_room = room
	_current_room.activate()
	_touch_resident(room)
	_camera.set_bounds(_current_room.get_bounds())
	await _fade.to_clear()
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_is_transitioning = false

## Marks `room` as the most recently visited, then evicts whichever
## resident room hasn't been touched in the longest time if that pushes the
## cache past its cap.
func _touch_resident(room: Room) -> void:
	_resident_rooms.erase(room)
	_resident_rooms.push_front(room)
	while _resident_rooms.size() > MAX_RESIDENT_ROOMS:
		_resident_rooms.pop_back().evict()

extends Node2D

@onready var _fade   : Fade   = %Fade
@onready var _camera : GameCamera = %Camera2D
@onready var _player : Node2D = %Player
var _current_room    : Room
var _is_transitioning: bool      = false

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
		_current_room.unload_contents()
	_current_room = room
	_current_room.load_contents()
	_camera.set_bounds(_current_room.get_bounds())
	await _fade.to_clear()
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_is_transitioning = false

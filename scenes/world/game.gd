extends Node2D

@onready var _world  : Node2D    = $World
@onready var _fade   : ColorRect = %Fade
@onready var _camera : Camera2D  = %Camera2D
@onready var _player : Node2D    = %Ivo
var _current_room    : Room
var _is_transitioning: bool      = false

func _ready() -> void:
	_camera.follow(_player)
	_connect_rooms(_world)

func _connect_rooms(node: Node) -> void:
	if node is Room:
		node.room_entered.connect(_on_player_entered_room)
	for child in node.get_children():
		_connect_rooms(child)

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

class_name GroundSeat
extends Node2D
## A place on the ground with no bench: Down sits Ivo here (`sit_ground`); it never rests or saves
## (systems/life-benches-death). While its gates hold and `cutscene` is unseen, sitting plays it (flashback 5).

## Which way Ivo faces sitting here: 1 right, -1 left.
@export var facing: int = 1
@export var cutscene: Cutscene
@export var when: Array[SaveFact] = []
@export var unless: Array[SaveFact] = []

@onready var _seat: Seat = $Seat
@onready var _prompt: KeyGlyph = $Prompt


func _ready() -> void:
	_seat.facing = facing
	_seat.ground = true
	_seat.changed.connect(_on_changed)
	_prompt.show_action(&"look_down")
	_on_changed()

## Whether sitting here plays `cutscene` under `data`.
func wants(data: PlayerData) -> bool:
	if cutscene == null or data.scenes_seen.has(cutscene.id):
		return false
	return SaveFact.gates_pass(when, unless, data)

func seat() -> Seat:
	return _seat

func _on_changed() -> void:
	_prompt.visible = _seat.has_body_in_reach() and not _seat.is_occupied()
	if _seat.is_occupied() and wants(SaveSystem.player_data):
		# Deferred: he sits inside his own physics step.
		_play.call_deferred()

func _play() -> void:
	var director := CutsceneDirector.find(get_tree())
	if director != null and _seat.is_occupied():
		director.play(cutscene, self)

class_name FlashbackLure
extends Node2D
## A flashback's call in the present (design drafts/camada_pessoal.md §2, "O chamado"): while its gates hold it sounds
## `voice` again and again from where it stands and ducks the music while Ivo is inside `zone`.

## The duck's name in Music.
const DUCK := &"flashback_lure"

@export var when: Array[SaveFact] = []
@export var unless: Array[SaveFact] = []
## The call, on the Sfx bus.
@export var stream: AudioStream
## Scaled seconds of silence between two calls.
@export var gap: float = 3.0
## dB the music sits at while Ivo is inside `zone`.
@export var duck_db: float = -40.0
## Where Ivo hears the place go quiet; its mask must hold Ivo's layer (256).
@export var zone: Area2D

var _active: bool = false
var _ducked: bool = false
## Scaled seconds until the next call.
var _wait: float = 0.0

@onready var _voice: AudioStreamPlayer2D = _make_voice()


func _ready() -> void:
	SaveSystem.progress_changed.connect(_refresh)
	_refresh()

func _exit_tree() -> void:
	_duck(false)

func _physics_process(delta: float) -> void:
	if not _active:
		return
	_duck(_ivo_inside())
	if _voice.playing:
		return
	_wait -= delta
	if _wait <= 0.0:
		_voice.play()
		_wait = gap

func is_active() -> bool:
	return _active

func is_ducking() -> bool:
	return _ducked

func _refresh() -> void:
	_active = SaveFact.gates_pass(when, unless, SaveSystem.player_data)
	if not _active:
		_voice.stop()
		_duck(false)
		_wait = 0.0

func _ivo_inside() -> bool:
	if zone == null or not zone.is_inside_tree():
		return false
	for body: Node2D in zone.get_overlapping_bodies():
		if body is Player:
			return true
	return false

func _duck(on: bool) -> void:
	if on == _ducked:
		return
	_ducked = on
	if on:
		Music.duck(DUCK, duck_db)
	else:
		Music.unduck(DUCK)

func _make_voice() -> AudioStreamPlayer2D:
	var made := AudioStreamPlayer2D.new()
	made.stream = stream
	made.bus = AudioBuses.SFX
	add_child(made)
	return made

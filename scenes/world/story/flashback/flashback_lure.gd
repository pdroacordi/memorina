class_name FlashbackLure
extends Node2D
## A flashback's call, or a sound of the past: while its gates hold it repeats `stream` where it stands, and ducks the
## music while Ivo is inside `zone` (systems/flashbacks, "The lure").

## The prefix of each lure's duck and muffle names in Music.
const DUCK := &"flashback_lure"

@export var when: Array[SaveFact] = []
@export var unless: Array[SaveFact] = []
## The call, on the Sfx bus.
@export var stream: AudioStream
## Scaled seconds of silence between two calls.
@export var gap: float = 3.0
## dB the music sits at while Ivo is inside `zone`.
@export var duck_db: float = -40.0
## Where Ivo hears the place go quiet; its mask must hold Ivo's layer (256); null never ducks.
@export var zone: Area2D

@export_group("Voice")
## Her singing, asked at SCENE layer while Ivo is inside `zone`; null asks none.
@export var voice: MusicCue
## Px from this node beyond which the music sits at `duck_db`; nearer, it rises to `near_db` here.
@export var voice_reach: float = 1200.0
@export var near_db: float = -6.0
## 0..1 low-pass on the music while the voice is asked: heard under the water.
@export var voice_muffle: float = 0.6

var _active: bool = false
var _ducked: bool = false
var _voice_request: MusicRequest
## This lure's own duck and muffle name, so two lures in neighbouring rooms never undo each other.
var _duck_id: StringName
## Scaled seconds until the next call.
var _wait: float = 0.0

@onready var _voice: AudioStreamPlayer2D = _make_voice()


func _ready() -> void:
	_duck_id = StringName("%s_%d" % [DUCK, get_instance_id()])
	SaveSystem.progress_changed.connect(_refresh)
	_refresh()

func _exit_tree() -> void:
	_quiet()

func _notification(what: int) -> void:
	# An idled room's nodes are disabled, never freed: its physics check stops before it sees Ivo leave.
	if what == NOTIFICATION_DISABLED:
		_quiet()

func _physics_process(delta: float) -> void:
	if not _active:
		return
	var ivo := _ivo_inside()
	_duck(ivo != null, _duck_db_for(ivo))
	_ask_voice(ivo != null)
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

## Whether her voice is asked of Music.
func is_singing() -> bool:
	return _voice_request != null

## The duck for Ivo at his place: `duck_db`, or with a voice, rising to `near_db` as he comes within `voice_reach`.
func duck_db_at(point: Vector2) -> float:
	if voice == null:
		return duck_db
	var near := 1.0 - SongProgress.at(global_position.distance_to(point), 0.0, voice_reach)
	return lerpf(duck_db, near_db, near)

func _refresh() -> void:
	_active = SaveFact.gates_pass(when, unless, SaveSystem.player_data)
	if not _active:
		_quiet()

func _quiet() -> void:
	if _voice != null:
		_voice.stop()
	_duck(false)
	_ask_voice(false)
	_wait = 0.0

## Ivo, when he is inside `zone`; else null.
func _ivo_inside() -> Player:
	if zone == null or not zone.is_inside_tree():
		return null
	for body: Node2D in zone.get_overlapping_bodies():
		if body is Player:
			return body as Player
	return null

func _duck_db_for(ivo: Player) -> float:
	return duck_db_at(ivo.global_position) if ivo != null else duck_db

func _duck(on: bool, db: float = 0.0) -> void:
	if on:
		Music.duck(_duck_id, db, self)
	elif _ducked:
		Music.unduck(_duck_id)
	_ducked = on

func _ask_voice(on: bool) -> void:
	if voice == null or on == (_voice_request != null):
		return
	if on:
		_voice_request = Music.request(voice, MusicRequest.Layer.SCENE, self)
		Music.muffle(_duck_id, voice_muffle, self)
	else:
		Music.release(_voice_request)
		_voice_request = null
		Music.unmuffle(_duck_id)

func _make_voice() -> AudioStreamPlayer2D:
	var made := AudioStreamPlayer2D.new()
	made.stream = stream
	made.bus = AudioBuses.SFX
	add_child(made)
	return made

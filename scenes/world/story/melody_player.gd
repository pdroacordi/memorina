class_name MelodyPlayer
extends Node
## Plays a Melody's notes on their onsets with one stream per note input, on the pausable, scaled clock: a hold or a
## freeze stops it where it is (systems/story).

signal note_played(index: int)
signal finished

## One stream per Enums.Note (UP, DOWN, LEFT, RIGHT).
@export var voices: Array[AudioStream] = []

var _melody: Melody
var _onsets: PackedFloat32Array = PackedFloat32Array()
var _end: float = 0.0
var _clock: float = 0.0
var _next: int = 0
var _playing: bool = false

@onready var _player: AudioStreamPlayer = _make_player()


func _process(delta: float) -> void:
	if not _playing:
		return
	_clock += delta
	while _next < _onsets.size() and _clock >= _onsets[_next]:
		var note: Enums.Note = _melody.notes[_next]
		if note < voices.size() and voices[note] != null:
			_player.stream = voices[note]
			_player.play()
		note_played.emit(_next)
		_next += 1
	if _next >= _onsets.size() and _clock >= _end:
		_playing = false
		finished.emit()

## Plays the first `count` notes (all when negative) at `tempo` times the written speed.
func play(melody: Melody, count: int = -1, tempo: float = 1.0) -> void:
	_melody = melody
	_onsets = melody.onsets(count, tempo)
	_end = melody.duration(count, tempo)
	_clock = 0.0
	_next = 0
	_playing = true

func stop() -> void:
	_playing = false
	_player.stop()

func is_playing() -> bool:
	return _playing

func _make_player() -> AudioStreamPlayer:
	var made := AudioStreamPlayer.new()
	made.max_polyphony = 4
	add_child(made)
	return made

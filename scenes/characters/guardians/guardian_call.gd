class_name GuardianCall extends Node

## Plays a guardian's note sequence and reports note and phrase completion.

signal note_sounded(index: int)
signal finished

## Seconds between call notes.
@export var note_interval: float = 0.55

var _notes: Array[Enums.Note] = []
var _index: int = -1
var _countdown: float = 0.0

@onready var _voice: MemorinaVoice = $Voice

func _ready() -> void:
	set_process(false)

func is_calling() -> bool:
	return _index >= 0 and _index < _notes.size()

## Duration of a complete call in seconds.
func duration() -> float:
	return note_interval * _notes.size()

## `lead_in` is the silence in seconds before the first note.
func play(notes: Array[Enums.Note], lead_in: float = 0.0) -> void:
	stop()
	_notes = notes.duplicate()
	set_process(true)
	if lead_in > 0.0:
		_countdown = lead_in
	else:
		_sound_next()

## Plays the mistake sound after any ringing note ends.
func groan() -> void:
	_voice.play_mistake_after_note()

## Stops an incomplete phrase; its window does not open.
func stop() -> void:
	_notes = []
	_index = -1
	set_process(false)
	_voice.stop()

func _process(delta: float) -> void:
	_countdown -= delta
	if _countdown <= 0.0:
		_sound_next()

func _sound_next() -> void:
	_index += 1
	_countdown = note_interval
	if _index >= _notes.size():
		_index = -1
		set_process(false)
		finished.emit()
		return
	_voice.play_note(_notes[_index])
	note_sounded.emit(_index)

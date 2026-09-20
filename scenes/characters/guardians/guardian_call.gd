class_name GuardianCall extends Node

## The guardian's side of the call-and-response: sounds a phrase one note at
## a time through a MemorinaVoice child, each note waiting for the one before
## it to finish - the same rhythm rule the player is held to. Reports which
## note is sounding so the sheet can light it, and when the phrase is done so
## the answer's window can open. Holds no opinion about the answer.

signal note_sounded(index: int)
signal finished

var _notes: Array[Enums.Note] = []
var _index: int = -1
## Seconds the last phrase took from its first note to its last note's end.
var _duration: float = 0.0
var _started_at: float = 0.0

@onready var _voice: MemorinaVoice = $Voice

func _ready() -> void:
	_voice.note_finished.connect(_on_note_finished)

func is_calling() -> bool:
	return _index >= 0 and _index < _notes.size()

## How long the last complete phrase took, so the answer can be given at
## least as long.
func duration() -> float:
	return _duration

func play(notes: Array[Enums.Note]) -> void:
	stop()
	_notes = notes.duplicate()
	_started_at = Time.get_ticks_msec() / 1000.0
	_sound_next()

## Cuts the phrase short. The window never opens for a call that was not
## heard out; the guardian decides what that means.
func stop() -> void:
	_notes = []
	_index = -1
	_voice.stop()

func _sound_next() -> void:
	_index += 1
	if _index >= _notes.size():
		_index = -1
		_duration = Time.get_ticks_msec() / 1000.0 - _started_at
		finished.emit()
		return
	_voice.play_note(_notes[_index])
	note_sounded.emit(_index)

func _on_note_finished() -> void:
	if is_calling():
		_sound_next()

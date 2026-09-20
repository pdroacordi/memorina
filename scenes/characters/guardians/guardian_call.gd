class_name GuardianCall extends Node

## The guardian's side of the call-and-response: sounds a phrase through a
## MemorinaVoice child, one note per beat, so the call is heard as a melody
## rather than six ringing tones. Reports which note is sounding so the sheet
## can light it, and when the phrase is done so the answer's window can open.
## Holds no opinion about the answer.

signal note_sounded(index: int)
signal finished

## Seconds between the notes of the call. The player answers at their own
## pace; this only sets how the guardian phrases it.
@export var note_interval: float = 0.55

var _notes: Array[Enums.Note] = []
var _index: int = -1
var _countdown: float = 0.0

@onready var _voice: MemorinaVoice = $Voice

func _ready() -> void:
	set_process(false)

func is_calling() -> bool:
	return _index >= 0 and _index < _notes.size()

## Seconds a complete call takes, so the answer can be given at least as long.
func duration() -> float:
	return note_interval * _notes.size()

func play(notes: Array[Enums.Note]) -> void:
	stop()
	_notes = notes.duplicate()
	set_process(true)
	_sound_next()

## Cuts the phrase short. The window never opens for a call that was not
## heard out; the guardian decides what that means.
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

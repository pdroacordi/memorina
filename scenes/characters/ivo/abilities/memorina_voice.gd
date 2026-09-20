class_name MemorinaVoice extends Node

## The instrument's sound: one note at a time, and the mistake that follows a
## wrong one. Holds no opinion about which notes are right - Player asks
## can_play_note() before it lets a press through, and MemorinaComponent
## decides what the press meant.
##
## A note rings for well over a second, far longer than a phrase is played
## at, so a new note CUTS the one still ringing - a pan flute stops sounding
## the pipe you left - once `min_note_gap` has passed. Presses inside the gap
## are mashing and are dropped; the gap is what keeps a rhythm to the playing.
##
## Mounted with an AudioStreamPlayer child, process_mode ALWAYS so a note can
## ring out while WorldFreeze holds the world still.

## The last note finished sounding on its own (not cut by the next). A queued
## mistake starts right after.
signal note_finished
signal mistake_finished

## Indexed by Enums.Note.
@export var note_streams: Array[AudioStream] = []
@export var mistake_stream: AudioStream
## Seconds a note must have sounded before the next may cut it.
@export var min_note_gap: float = 0.25

var _mistake_pending: bool = false
var _sounding_mistake: bool = false
var _note_started_msec: int = -1

@onready var _player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	assert(note_streams.size() == Enums.Note.size(),
		"MemorinaVoice has %d note streams for %d notes." % [note_streams.size(), Enums.Note.size()])
	_player.finished.connect(_on_player_finished)

## Whether a press right now would sound: never over the mistake, and not
## within the gap after the last note began.
func can_play_note() -> bool:
	if is_faulting():
		return false
	if not _player.playing or _note_started_msec < 0:
		return true
	return Time.get_ticks_msec() - _note_started_msec >= int(min_note_gap * 1000.0)

func play_note(note: Enums.Note) -> void:
	_mistake_pending = false
	_sounding_mistake = false
	_note_started_msec = Time.get_ticks_msec()
	_player.stream = note_streams[note]
	_player.play()

## Sounds the mistake once the note that is ringing has finished, or at once
## if nothing is sounding. is_busy() stays true until the mistake ends.
func play_mistake_after_note() -> void:
	if _player.playing and not _sounding_mistake:
		_mistake_pending = true
	else:
		_play_mistake()

## True while a note or the mistake sounds, or a mistake is waiting its turn.
## `_sounding_mistake` is checked on its own because `playing` drops on the
## mix thread a frame before `finished` is emitted; a note let through in that
## gap would replace the stream and swallow the mistake's end.
func is_busy() -> bool:
	return _player.playing or _mistake_pending or _sounding_mistake

## True while a mistake sounds or waits its turn: the instrument is in the
## middle of saying no, and a lesson must not begin over it.
func is_faulting() -> bool:
	return _mistake_pending or _sounding_mistake

func stop() -> void:
	_mistake_pending = false
	_sounding_mistake = false
	_player.stop()

func _play_mistake() -> void:
	_mistake_pending = false
	_sounding_mistake = true
	_player.stream = mistake_stream
	_player.play()

func _on_player_finished() -> void:
	if _sounding_mistake:
		_sounding_mistake = false
		mistake_finished.emit()
		return
	# Emitted even when a mistake is queued behind the note: whoever awaits the
	# ring-out must always be woken, and then asks the instrument whether the
	# performance still stands.
	note_finished.emit()
	if _mistake_pending:
		_play_mistake()

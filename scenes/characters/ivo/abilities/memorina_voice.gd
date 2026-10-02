class_name MemorinaVoice extends Node

## Plays one note at a time; `min_note_gap` sets the minimum interval between notes.

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

# Ivo's voice is ALWAYS so it rings through a performance freeze; a menu hold silences it.
func _process(_delta: float) -> void:
	_player.stream_paused = WorldFreeze.is_held()

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

func play_mistake_after_note() -> void:
	if _player.playing and not _sounding_mistake:
		_mistake_pending = true
	else:
		_play_mistake()

## True while a note or mistake sounds, or a mistake is queued; `_sounding_mistake` covers the frame before `finished` arrives.
func is_busy() -> bool:
	return _player.playing or _mistake_pending or _sounding_mistake

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
	if _mistake_pending:
		_play_mistake()

class_name SongPerformance extends Node

## Plays a stream and emits cue and finish signals; use ALWAYS process mode for audio that continues during a pause.

signal started
signal cue_reached(index: int)
## The natural end of the stream, or the end of the fade after a cut. Never
## emitted by stop().
signal finished

const SILENCE_DB := -60.0

var _tracker: CueTracker
var _stop_at: float = 0.0
var _fade: float = 0.0
var _fade_tween: Tween
## The volume authored on the player, restored after a fade.
var _base_volume_db: float = 0.0

@onready var _player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	_base_volume_db = _player.volume_db
	_player.finished.connect(_end)
	set_process(false)

func _process(_delta: float) -> void:
	assert(not WorldFreeze.is_held(), "A menu holds only a running world; a performance freezes it first")
	var position := _position()
	for index: int in _tracker.advance(position):
		cue_reached.emit(index)
	if _stop_at > 0.0 and _fade_tween == null and position >= _stop_at - _fade:
		_start_fade()

## Starts `stream` from the top. `stop_at` > 0 cuts it at that many seconds,
## fading over the last `fade` seconds; 0 plays it whole.
func play(stream: AudioStream, cues: PackedFloat32Array, stop_at: float = 0.0, fade: float = 0.0) -> void:
	stop()
	# Report completion for an empty stream so callers can thaw the world.
	if stream == null:
		finished.emit()
		return
	_tracker = CueTracker.new(cues)
	_stop_at = stop_at
	_fade = minf(fade, stop_at) if stop_at > 0.0 else 0.0
	_player.stream = stream
	_player.play()
	set_process(true)
	started.emit()

## Silences the performance without reporting it as finished.
func stop() -> void:
	_kill_fade()
	_player.stop()
	_player.volume_db = _base_volume_db
	set_process(false)

func is_playing() -> bool:
	return is_processing()

## Playback position corrected for audio latency, in seconds.
func _position() -> float:
	return _player.get_playback_position() \
		+ AudioServer.get_time_since_last_mix() \
		- AudioServer.get_output_latency()

func _start_fade() -> void:
	if _fade <= 0.0:
		_end()
		return
	_fade_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.tween_property(_player, "volume_db", SILENCE_DB, _fade)
	_fade_tween.finished.connect(_end)

func _end() -> void:
	if not is_processing():
		return
	stop()
	finished.emit()

func _kill_fade() -> void:
	if _fade_tween != null:
		_fade_tween.kill()
		_fade_tween = null

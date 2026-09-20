class_name SongPerformance extends Node

## Plays one stream and reports where it is in it: `cue_reached` as playback
## crosses each cue, `finished` when the stream ends or the cut it was given
## has faded out. Generic - the world excerpt, the lesson and, later, a
## guardian's call all sound through one of these.
##
## Mounted with an AudioStreamPlayer child. Set process_mode to ALWAYS when
## the performance must keep sounding through a paused tree, which is the
## case for the instrument (WorldFreeze pauses the world while it plays).

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
	var position := _position()
	for index: int in _tracker.advance(position):
		cue_reached.emit(index)
	if _stop_at > 0.0 and _fade_tween == null and position >= _stop_at - _fade:
		_start_fade()

## Starts `stream` from the top. `stop_at` > 0 cuts it at that many seconds,
## fading over the last `fade` seconds; 0 plays it whole.
func play(stream: AudioStream, cues: PackedFloat32Array, stop_at: float = 0.0, fade: float = 0.0) -> void:
	stop()
	# AudioStreamPlayer.play() is a no-op without a stream and would never
	# report `finished`, leaving whoever froze the world with nothing to thaw
	# it. Report the end at once instead: the song is simply heard silently.
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

## The audio clock, corrected for the mix that is already on its way to the
## speakers, so a cue lands when the note is heard rather than when it was
## queued.
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

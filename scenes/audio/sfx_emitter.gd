class_name SfxEmitter
extends Node2D
## Plays SoundCues for the node it belongs to, one player per cue made on first use (systems/sound-effects).

## A voice of `cue` started.
signal cue_played(cue: SoundCue)

const GROUP := &"sfx_emitters"
## px; the 640x384 frame's diagonal is about 746, so a source off screen fades out.
const MAX_DISTANCE := 800.0
const ATTENUATION := 1.0
const PANNING_STRENGTH := 0.6

## Voices are AudioStreamPlayer2D, heard by distance from the screen; otherwise centred.
@export var positional: bool = false

# One gate for every emitter, so a cue struck by three creatures in one frame sounds once.
static var _gate := CueGate.new()

var _players: Dictionary[SoundCue, Node] = {}


func _init() -> void:
	add_to_group(GROUP)

func _notification(what: int) -> void:
	# An idled room disables its contents without leaving the tree.
	if what == NOTIFICATION_DISABLED:
		stop_all()

## Starts a voice of `cue` at the emitter, `db_offset` dB over its level and `pitch` times its pitch; false when refused.
func play(cue: SoundCue, db_offset: float = 0.0, pitch: float = 1.0) -> bool:
	if not _can_start(cue):
		return false
	var player := _player_for(cue)
	if player is AudioStreamPlayer2D:
		(player as AudioStreamPlayer2D).position = Vector2.ZERO
	_voice(player, cue, db_offset, pitch)
	return true

## Starts a voice of `cue` at the global `point`; a non-positional emitter ignores the point.
func play_at(cue: SoundCue, point: Vector2, db_offset: float = 0.0) -> bool:
	if not _can_start(cue):
		return false
	var player := _player_for(cue)
	if player is AudioStreamPlayer2D:
		(player as AudioStreamPlayer2D).global_position = point
	_voice(player, cue, db_offset)
	return true

func stop_all() -> void:
	for player: Node in _players.values():
		if player is AudioStreamPlayer2D:
			(player as AudioStreamPlayer2D).stop()
		else:
			(player as AudioStreamPlayer).stop()

## The player made for `cue`, or null before its first voice.
func player_of(cue: SoundCue) -> Node:
	return _players.get(cue)

# A player that cannot process still starts a voice: centred it sounds through the pause,
# positional it starts late (gotchas/an-audio-player-that-cannot-process-still-starts-a-voice).
func _can_start(cue: SoundCue) -> bool:
	if cue == null or cue.stream == null or not is_inside_tree() or not can_process():
		return false
	return _gate.try_start(cue)

func _player_for(cue: SoundCue) -> Node:
	if _players.has(cue):
		return _players[cue]
	var player: Node
	if positional:
		var spatial := AudioStreamPlayer2D.new()
		spatial.max_distance = MAX_DISTANCE
		spatial.attenuation = ATTENUATION
		spatial.panning_strength = PANNING_STRENGTH
		spatial.bus = cue.bus()
		spatial.max_polyphony = cue.max_voices
		spatial.pitch_scale = cue.pitch_scale
		spatial.stream = cue.stream
		player = spatial
	else:
		var flat := AudioStreamPlayer.new()
		flat.bus = cue.bus()
		flat.max_polyphony = cue.max_voices
		flat.pitch_scale = cue.pitch_scale
		flat.stream = cue.stream
		player = flat
	add_child(player)
	_players[cue] = player
	return player

func _voice(player: Node, cue: SoundCue, db_offset: float, pitch: float = 1.0) -> void:
	if player is AudioStreamPlayer2D:
		var spatial := player as AudioStreamPlayer2D
		spatial.volume_db = cue.volume_db + db_offset
		spatial.pitch_scale = cue.pitch_scale * pitch
		spatial.play()
	else:
		var flat := player as AudioStreamPlayer
		flat.volume_db = cue.volume_db + db_offset
		flat.pitch_scale = cue.pitch_scale * pitch
		flat.play()
	cue_played.emit(cue)

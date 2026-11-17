class_name IvoMusicYield
extends Node
## Sinks the region's music while Ivo plays the Memorina or the guitar (SND-04, systems/music).

## How far the region's music sinks while he plays, dB.
const YIELD_DB := -30.0
const DUCK := &"ivo_plays"

var _open: bool = false

@onready var _player: Player = get_parent()


## Only a region's theme yields: a fight's music and its call duck, and a scene's music, stay as written.
static func yields(playing: MusicRequest) -> bool:
	return playing != null and playing.layer == MusicRequest.Layer.REGION


# Sampled each frame, so a duck Music closed while Ivo was disabled (a door's fade) opens again.
func _physics_process(_delta: float) -> void:
	var wanted := _player.is_playing_music() and yields(Music.playing())
	if wanted:
		Music.duck(DUCK, YIELD_DB, self)
	elif _open:
		Music.unduck(DUCK)
	_open = wanted

func _exit_tree() -> void:
	if _open:
		Music.unduck(DUCK)
		_open = false

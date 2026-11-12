class_name CutsceneMusicMark
extends CutsceneStep
## Waits until the playing music reaches `seconds`, so a cut lands on the music; over at once when no music plays
## (systems/music).

## Seconds into the playing cue.
@export var seconds: float = 0.0


func begin(context: CutsceneContext) -> CutsceneTask:
	var reached := func() -> bool:
		var at := context.music_position()
		return at < 0.0 or at >= seconds
	return CutsceneUntilTask.new(reached)

## Whether the mark can be reached in `cue`: before the end of its stream (a looping cue's position wraps there).
func fits(cue: MusicCue) -> bool:
	if seconds < 0.0:
		return false
	var length := cue.stream.get_length() if cue != null and cue.stream != null else 0.0
	return length <= 0.0 or seconds < length

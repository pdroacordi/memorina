class_name CutsceneMusicMark
extends CutsceneStep
## Waits until the playing music reaches `seconds`, so a cut lands on the music; over at once when no music plays
## (systems/music).

## Seconds into the playing cue.
@export var seconds: float = 0.0
## Seconds between marks after `seconds` (a bar); 0 waits for `seconds` alone. The wait ends on the first mark at or after
## the position the step began at, or when a looping cue wraps.
@export var every: float = 0.0


func begin(context: CutsceneContext) -> CutsceneTask:
	if every <= 0.0:
		var reached := func() -> bool:
			var at := context.music_position()
			return at < 0.0 or at >= seconds
		return CutsceneUntilTask.new(reached)
	var start := context.music_position()
	var target := next_mark(start)
	# A lambda captures locals by value: the last position read lives in an array it shares.
	var last: Array[float] = [start]
	var reached_next := func() -> bool:
		var at := context.music_position()
		var wrapped := at < last[0]
		last[0] = at
		return at < 0.0 or wrapped or at >= target
	return CutsceneUntilTask.new(reached_next)

## The first mark at or after `position` seconds: `seconds`, or `seconds + k * every` once `every` is set.
func next_mark(position: float) -> float:
	if every <= 0.0 or position <= seconds:
		return seconds
	return seconds + ceilf((position - seconds) / every) * every

## Whether the mark can be reached in `cue`: before the end of its stream (a looping cue's position wraps there).
func fits(cue: MusicCue) -> bool:
	if seconds < 0.0 or every < 0.0:
		return false
	var length := cue.stream.get_length() if cue != null and cue.stream != null else 0.0
	return length <= 0.0 or seconds < length

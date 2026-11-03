class_name CutsceneMusic
extends CutsceneStep
## Asks for background music for the rest of the scene, or releases it; never waits (architecture/music-system).

## Null releases the scene's music.
@export var cue: MusicCue
## Real seconds a release fades over; negative uses the cue's own (a one-shot then plays to its end).
@export var fade: float = -1.0


func begin(context: CutsceneContext) -> CutsceneTask:
	context.music(cue, fade)
	return CutsceneTask.new()

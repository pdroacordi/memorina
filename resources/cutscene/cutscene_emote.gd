class_name CutsceneEmote
extends CutsceneStep
## A bubble with a glyph and no words over an actor or Ivo, greyed with the place (systems/cutscenes, "default, 2026-10-16").

enum Emote { ELLIPSIS, NOTE, EXCLAIM }

@export var actor: StringName = &""
@export var emote: Emote = Emote.ELLIPSIS
## Scaled seconds shown; the step waits them out.
@export var seconds: float = 1.2
## Px over the feet; 0 is the subject's standing height (lower it for someone lying down).
@export var height: float = 0.0


func begin(context: CutsceneContext) -> CutsceneTask:
	context.emote(actor, emote, seconds, height)
	return CutsceneWaitTask.new(seconds)

func subjects() -> Array[StringName]:
	return [actor]

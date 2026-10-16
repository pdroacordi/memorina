class_name CutsceneEmote
extends CutsceneStep
## A bubble with a glyph and no words over an actor or Ivo, greyed with the place (systems/cutscenes, "default, 2026-10-16").

enum Emote { ELLIPSIS, NOTE, EXCLAIM }

@export var actor: StringName = &""
@export var emote: Emote = Emote.ELLIPSIS
## Scaled seconds shown; the step waits them out.
@export var seconds: float = 1.2


func begin(context: CutsceneContext) -> CutsceneTask:
	context.emote(actor, emote, seconds)
	return CutsceneWaitTask.new(seconds)

func subjects() -> Array[StringName]:
	return [actor]

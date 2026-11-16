class_name MenuSoundSet
extends Resource
## The menu cues, played by MenuSounds (systems/sound-effects); null is silent.

@export var move: SoundCue
@export var confirm: SoundCue
@export var back: SoundCue
## A holding screen opens: the pause or the notebook.
@export var open: SoundCue
@export var close: SoundCue
## A notebook page turns.
@export var page: SoundCue


func cue(which: MenuCueGate.Cue) -> SoundCue:
	match which:
		MenuCueGate.Cue.MOVE:
			return move
		MenuCueGate.Cue.CONFIRM:
			return confirm
		MenuCueGate.Cue.BACK:
			return back
		MenuCueGate.Cue.OPEN:
			return open
		MenuCueGate.Cue.CLOSE:
			return close
		MenuCueGate.Cue.PAGE:
			return page
	return null

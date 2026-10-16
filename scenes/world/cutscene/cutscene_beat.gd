class_name CutsceneBeat
extends DialogueBeat
## A talk's cue hands the talk to a cutscene (systems/cutscenes): Ivo is held STILL, the scene plays, and the talk resumes
## when it ends, is skipped or is dropped. A scene played from a beat holds no talk of its own.

@export var cutscene: Cutscene

var _director: CutsceneDirector


func start() -> void:
	assert(hold == Hold.STILL, "%s: a cutscene's beat holds Ivo STILL; the scene drives him" % name)
	super()
	_director = CutsceneDirector.find(get_tree())
	if _director == null or not _director.play(cutscene, self):
		push_error("%s: no cutscene director would play '%s'" % [name, cutscene.id if cutscene != null else "nothing"])
		finish.call_deferred()
		return
	_director.scene_ended.connect(_on_scene_ended)

func _on_scene_ended(scene: Cutscene) -> void:
	if scene != cutscene:
		return
	_director.scene_ended.disconnect(_on_scene_ended)
	finish()

class_name CutsceneBeat
extends DialogueBeat
## A talk's cue hands the talk to a cutscene (systems/cutscenes): Ivo is held STILL, the scene plays, and the talk resumes
## when it ends, is skipped or is dropped. A scene played from a beat holds no talk of its own.

@export var cutscene: Cutscene

var _director: CutsceneDirector
## The side the scene last turned Ivo to (-1 or 1); 0 when it did not.
var _turned: int = 0


func start() -> void:
	assert(hold == Hold.STILL, "%s: a cutscene's beat holds Ivo STILL; the scene drives him" % name)
	super()
	_director = CutsceneDirector.find(get_tree())
	if _director == null or not _director.play(cutscene, self):
		push_error("%s: no cutscene director would play '%s'" % [name, cutscene.id if cutscene != null else "nothing"])
		finish.call_deferred()
		return
	_turned = 0
	_director.scene_ended.connect(_on_scene_ended)

## A face the scene gave Ivo holds to the talk's end, as a beat's `face` does.
func face_after(facing: Vector2) -> Vector2:
	if _turned == 0 or _director == null or _director.ivo == null:
		return facing
	return _director.ivo.global_position + Vector2(_turned * 64.0, 0.0)

func _on_scene_ended(scene: Cutscene) -> void:
	if scene != cutscene:
		return
	_director.scene_ended.disconnect(_on_scene_ended)
	_turned = _director.ivo_turned()
	finish()

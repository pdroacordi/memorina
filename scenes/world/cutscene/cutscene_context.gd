class_name CutsceneContext
extends RefCounted
## The services a step acts through (systems/cutscenes). WorldCutsceneContext acts on the world; a test's fake records.
## Ids name actors, marks and visuals in the host's contents, or `&"ivo"`.


## An actor's or Ivo's feet, or a mark's or visual's point, in world px.
func point_of(_id: StringName) -> Vector2:
	return Vector2.ZERO

func walk(_id: StringName, _x: float, _pace: float) -> CutsceneTask:
	return CutsceneTask.new()

func place(_id: StringName, _point: Vector2) -> void:
	pass

## `direction` is -1 (west) or 1 (east).
func face(_id: StringName, _direction: int) -> void:
	pass

## Plays `clip`; the task is over once a one-shot has settled.
func gesture(_id: StringName, _clip: StringName) -> CutsceneTask:
	return CutsceneTask.new()

## Shows the clip `clip` settles on, at once.
func land_gesture(_id: StringName, _clip: StringName) -> void:
	pass

## `height` px over the feet; 0 is the subject's standing height.
func emote(_id: StringName, _emote: CutsceneEmote.Emote, _seconds: float, _height: float = 0.0) -> void:
	pass

func pose(_pose: DialogueBeat.Pose) -> void:
	pass

func bars(_open: bool, _seconds: float) -> void:
	pass

## Moves the frame's centre to `centre` (world px) and the zoom to `zoom` (0 keeps it).
func frame(_centre: Vector2, _zoom: float, _seconds: float) -> void:
	pass

## Starts the set's current dialogue spoken from `at`; the task is over when the talk ends.
func talk(_talk: DialogueSet, _at: Vector2) -> CutsceneTask:
	return CutsceneTask.new()

func sound(_stream: AudioStream) -> CutsceneTask:
	return CutsceneTask.new()

func melody(_melody: Melody, _count: int, _voices: Array[AudioStream]) -> CutsceneTask:
	return CutsceneTask.new()

func silence() -> void:
	pass

func fade(_to_black: bool, _seconds: float) -> void:
	pass

## `alpha` 0..1.
func show_visual(_id: StringName, _alpha: float, _seconds: float) -> void:
	pass

## The FactStaging `staging_id` stands in `child` (empty: nothing) over `seconds`.
func stage(_staging_id: StringName, _child: StringName, _seconds: float) -> void:
	pass

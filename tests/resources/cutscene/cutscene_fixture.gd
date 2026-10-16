extends RefCounted
## Builds cutscene data for the suites, and a context that records what steps ask of it.


static func scene(id: StringName, steps: Array[CutsceneStep]) -> Cutscene:
	var made := Cutscene.new()
	made.id = id
	made.steps = steps
	return made

static func wait(seconds: float) -> CutsceneWait:
	var made := CutsceneWait.new()
	made.seconds = seconds
	return made

static func together(steps: Array[CutsceneStep]) -> CutsceneTogether:
	var made := CutsceneTogether.new()
	made.steps = steps
	return made

static func sequence(steps: Array[CutsceneStep]) -> CutsceneSequence:
	var made := CutsceneSequence.new()
	made.steps = steps
	return made

static func branch(cases: Array[CutsceneCase]) -> CutsceneBranch:
	var made := CutsceneBranch.new()
	made.cases = cases
	return made

static func case_of(when: Array[SaveFact], steps: Array[CutsceneStep]) -> CutsceneCase:
	var made := CutsceneCase.new()
	made.when = when
	made.steps = steps
	return made

static func walk(actor: StringName, x: float, pace: float = 1.0) -> CutsceneWalk:
	var made := CutsceneWalk.new()
	made.actor = actor
	made.x = x
	made.pace = pace
	return made

static func gesture(actor: StringName, clip: StringName) -> CutsceneGesture:
	var made := CutsceneGesture.new()
	made.actor = actor
	made.clip = clip
	return made

static func talk(wait_for_it: bool = true) -> CutsceneTalk:
	var made := CutsceneTalk.new()
	made.talk = DialogueSet.new()
	made.speaker = CutsceneStep.IVO
	made.wait = wait_for_it
	return made

static func camera(targets: Array[StringName], zoom: float, seconds: float) -> CutsceneCamera:
	var made := CutsceneCamera.new()
	made.targets = targets
	made.zoom = zoom
	made.seconds = seconds
	return made


## Records every service call as "name:args"; points come from `points`.
class Recorder:
	extends CutsceneContext

	var calls: PackedStringArray = PackedStringArray()
	var points: Dictionary[StringName, Vector2] = {}

	func point_of(id: StringName) -> Vector2:
		return points.get(id, Vector2.ZERO)

	func walk(id: StringName, x: float, pace: float) -> CutsceneTask:
		calls.append("walk:%s:%d:%.2f" % [id, int(x), pace])
		return CutsceneWaitTask.new(1.0)

	func place(id: StringName, point: Vector2) -> void:
		calls.append("place:%s:%d,%d" % [id, int(point.x), int(point.y)])
		points[id] = point

	func face(id: StringName, direction: int) -> void:
		calls.append("face:%s:%d" % [id, direction])

	func gesture(id: StringName, clip: StringName) -> CutsceneTask:
		calls.append("gesture:%s:%s" % [id, clip])
		return CutsceneWaitTask.new(1.0)

	func land_gesture(id: StringName, clip: StringName) -> void:
		calls.append("land_gesture:%s:%s" % [id, clip])

	func emote(id: StringName, shown: CutsceneEmote.Emote, seconds: float) -> void:
		calls.append("emote:%s:%d:%.1f" % [id, shown, seconds])

	func pose(held: DialogueBeat.Pose) -> void:
		calls.append("pose:%d" % held)

	func bars(open: bool, seconds: float) -> void:
		calls.append("bars:%s:%.1f" % [open, seconds])

	func frame(centre: Vector2, zoom: float, seconds: float) -> void:
		calls.append("frame:%d,%d:%.1f:%.1f" % [int(centre.x), int(centre.y), zoom, seconds])

	func talk(_set: DialogueSet, at: Vector2) -> CutsceneTask:
		calls.append("talk:%d" % int(at.x))
		return CutsceneWaitTask.new(1.0)

	func sound(_stream: AudioStream) -> CutsceneTask:
		calls.append("sound")
		return CutsceneTask.new()

	func melody(_melody: Melody, count: int, _voices: Array[AudioStream]) -> CutsceneTask:
		calls.append("melody:%d" % count)
		return CutsceneTask.new()

	func silence() -> void:
		calls.append("silence")

	func fade(to_black: bool, seconds: float) -> void:
		calls.append("fade:%s:%.1f" % [to_black, seconds])

	func show_visual(id: StringName, alpha: float, seconds: float) -> void:
		calls.append("show:%s:%.1f:%.1f" % [id, alpha, seconds])

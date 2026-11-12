class_name CutsceneCatalog
extends Resource
## Every cutscene; `validate()` names what the data cannot hold (systems/cutscenes).

@export var scenes: Array[Cutscene] = []


## The scene with `id`; null when none has it.
func find(id: StringName) -> Cutscene:
	for scene: Cutscene in scenes:
		if scene != null and scene.id == id:
			return scene
	return null

## Problems, one line each; empty when the catalog is sound.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	var ids: Array[StringName] = []
	for scene: Cutscene in scenes:
		if scene == null:
			problems.append("a null scene")
			continue
		if scene.id == &"":
			problems.append("a scene with no id")
		elif ids.has(scene.id):
			problems.append("duplicate scene id '%s'" % scene.id)
		ids.append(scene.id)
	for scene: Cutscene in scenes:
		if scene != null:
			_check(scene.steps, scene, false, true, ids, problems)
			_check_marks(scene, problems)
	return problems

## Every leaf step under `steps`, branches' cases included.
static func leaves(steps: Array[CutsceneStep]) -> Array[CutsceneStep]:
	var found: Array[CutsceneStep] = []
	for item: CutsceneStep in steps:
		var children := _children(item)
		if children.is_empty() and not _is_container(item):
			found.append(item)
		else:
			found.append_array(leaves(children))
	return found

func _check(steps: Array[CutsceneStep], scene: Cutscene, together: bool, at_end: bool, ids: Array[StringName],
		problems: PackedStringArray) -> void:
	var subjects: Array[StringName] = []
	for i: int in steps.size():
		var item := steps[i]
		if item == null:
			problems.append("%s: a null step" % scene.id)
			continue
		var last := at_end and i == steps.size() - 1
		if item is CutsceneTogether:
			_check((item as CutsceneTogether).steps, scene, true, false, ids, problems)
		elif item is CutsceneSequence:
			_check((item as CutsceneSequence).steps, scene, together, last, ids, problems)
		elif item is CutsceneBranch:
			for case: CutsceneCase in (item as CutsceneBranch).cases:
				_check_facts(case.when, scene, ids, problems)
				_check_facts(case.unless, scene, ids, problems)
				_check(case.steps, scene, together, last, ids, problems)
		elif item is CutsceneTalk:
			if together:
				problems.append("%s: a talk inside a together" % scene.id)
			if not (item as CutsceneTalk).wait and not last:
				problems.append("%s: a talk that does not wait is not the scene's last step" % scene.id)
			if (item as CutsceneTalk).talk == null:
				problems.append("%s: a talk with no dialogue set" % scene.id)
		if together:
			for subject: StringName in _subjects_of(item):
				if subjects.has(subject):
					problems.append("%s: two steps of one together move '%s'" % [scene.id, subject])
				subjects.append(subject)

## A music mark must be reachable in every cue its own scene asks for; a cue asked elsewhere (a flashback's visit) is
## checked by its owner.
func _check_marks(scene: Cutscene, problems: PackedStringArray) -> void:
	var found := leaves(scene.steps)
	for mark: CutsceneStep in found:
		if not (mark is CutsceneMusicMark):
			continue
		var seconds := (mark as CutsceneMusicMark).seconds
		if seconds < 0.0:
			problems.append("%s: a music mark at %.2f s" % [scene.id, seconds])
		for music: CutsceneStep in found:
			var cue := (music as CutsceneMusic).cue if music is CutsceneMusic else null
			if cue != null and not (mark as CutsceneMusicMark).fits(cue):
				problems.append("%s: a music mark at %.2f s is past the end of '%s'" % [scene.id, seconds, cue.id])

func _check_facts(facts: Array[SaveFact], scene: Cutscene, ids: Array[StringName], problems: PackedStringArray) -> void:
	for fact: SaveFact in facts:
		if fact != null and fact.kind == SaveFact.Kind.SCENE_SEEN and not ids.has(fact.id):
			problems.append("%s: SCENE_SEEN '%s' names no scene" % [scene.id, fact.id])

## A container's subjects are its leaves' subjects.
static func _subjects_of(item: CutsceneStep) -> Array[StringName]:
	if not _is_container(item):
		return item.subjects()
	var found: Array[StringName] = []
	for leaf: CutsceneStep in leaves([item]):
		for subject: StringName in leaf.subjects():
			if not found.has(subject):
				found.append(subject)
	return found

static func _is_container(item: CutsceneStep) -> bool:
	return item is CutsceneSequence or item is CutsceneTogether or item is CutsceneBranch

static func _children(item: CutsceneStep) -> Array[CutsceneStep]:
	if item is CutsceneSequence:
		return (item as CutsceneSequence).steps
	if item is CutsceneTogether:
		return (item as CutsceneTogether).steps
	if item is CutsceneBranch:
		var found: Array[CutsceneStep] = []
		for case: CutsceneCase in (item as CutsceneBranch).cases:
			found.append_array(case.steps)
		return found
	return []

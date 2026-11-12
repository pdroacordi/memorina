class_name FlashbackCatalog
extends Resource
## Every flashback; `validate()` names what the data cannot hold (architecture/story-05-playable-flashbacks).

@export var flashbacks: Array[Flashback] = []


## The flashback whose crossing is `scene`; null when none is.
func by_crossing(scene: Cutscene) -> Flashback:
	if scene == null:
		return null
	for flashback: Flashback in flashbacks:
		if flashback != null and flashback.crossing != null and flashback.crossing.id == scene.id:
			return flashback
	return null

## Problems, one line each; empty when the catalog is sound against the scenes of `cutscenes`.
func validate(cutscenes: CutsceneCatalog) -> PackedStringArray:
	var problems := PackedStringArray()
	var numbers: Array[int] = []
	for flashback: Flashback in flashbacks:
		if flashback == null:
			problems.append("a null flashback")
			continue
		var n := flashback.number
		if n < 1 or n > FlashbackSchedule.COUNT:
			problems.append("flashback %d: a number outside 1..%d" % [n, FlashbackSchedule.COUNT])
		elif numbers.has(n):
			problems.append("flashback %d: listed twice" % n)
		numbers.append(n)
		_check_scenes(flashback, cutscenes, problems)
		_check_music(flashback, problems)
		if flashback.past_room == &"":
			problems.append("flashback %d: no past room" % n)
		if flashback.bars_thin < 0.0 or flashback.entry_fade < 0.0:
			problems.append("flashback %d: a negative bar or fade" % n)
	return problems

func _check_scenes(flashback: Flashback, cutscenes: CutsceneCatalog, problems: PackedStringArray) -> void:
	var n := flashback.number
	var roles := {&"crossing": flashback.crossing, &"opening": flashback.opening, &"leaving": flashback.leaving,
			&"returning": flashback.returning}
	for role: StringName in roles:
		var scene: Cutscene = roles[role]
		if scene == null:
			problems.append("flashback %d: no %s scene" % [n, role])
		elif cutscenes != null and cutscenes.find(scene.id) == null:
			problems.append("flashback %d: its %s '%s' is not in the cutscene catalog" % [n, role, scene.id])
	if flashback.leaving != null and flashback.leaving.id != FlashbackSchedule.id(n):
		problems.append("flashback %d: its leaving scene is '%s', not '%s'" % [n, flashback.leaving.id, FlashbackSchedule.id(n)])
	# Its host is the room Ivo stood in, any of several: only Ivo resolves in all of them.
	if flashback.returning != null:
		for leaf: CutsceneStep in CutsceneCatalog.leaves(flashback.returning.steps):
			for id: StringName in leaf.names():
				if id != CutsceneStep.IVO:
					problems.append("flashback %d: its returning scene names '%s'" % [n, id])

## The entry mark and every music mark of the visit's scenes lie inside the visit's music.
func _check_music(flashback: Flashback, problems: PackedStringArray) -> void:
	var n := flashback.number
	if flashback.music == null:
		problems.append("flashback %d: no music" % n)
		return
	var entry := CutsceneMusicMark.new()
	entry.seconds = flashback.entry_mark
	if not entry.fits(flashback.music):
		problems.append("flashback %d: its entry mark %.2f s is outside '%s'" % [n, flashback.entry_mark, flashback.music.id])
	for scene: Cutscene in [flashback.opening, flashback.leaving]:
		if scene == null:
			continue
		for leaf: CutsceneStep in CutsceneCatalog.leaves(scene.steps):
			if leaf is CutsceneMusicMark and not (leaf as CutsceneMusicMark).fits(flashback.music):
				problems.append("flashback %d: '%s' has a music mark at %.2f s outside '%s'" % [n, scene.id,
						(leaf as CutsceneMusicMark).seconds, flashback.music.id])

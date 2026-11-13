class_name BearerFragmentCatalog
extends Resource
## Every bearer fragment; `validate()` names what the data cannot hold (architecture/story-04-bearer-fragments).

## The shipped guardians' stats, whose `song` each fragment must name.
const GUARDIAN_STATS := {
	Enums.Guardian.FROST: "res://resources/characters/guardians/frost_guardian/frost_guardian_stats.tres",
	Enums.Guardian.BLOOM: "res://resources/characters/guardians/bloom_guardian/bloom_guardian_stats.tres",
	Enums.Guardian.AUTUMN: "res://resources/characters/guardians/autumn_guardian/autumn_guardian_stats.tres",
	Enums.Guardian.SUMMER: "res://resources/characters/guardians/summer_guardian/summer_guardian_stats.tres",
}
const MIN_FRAMES := 4
const MAX_FRAMES := 5
const MAX_CAPTIONS := 2
## Scaled seconds an engraving scene runs, its fades and clear included.
const MIN_SECONDS := 25.0
const MAX_SECONDS := 35.0

@export var fragments: Array[BearerFragment] = []


## Guardian -> its GuardianStats, loaded from GUARDIAN_STATS.
static func shipped_stats() -> Dictionary:
	var stats := {}
	for guardian: int in GUARDIAN_STATS:
		stats[guardian] = load(GUARDIAN_STATS[guardian]) as GuardianStats
	return stats

## Scaled seconds `steps` take played in order: a CutsceneTogether takes its longest; steps that wait on nothing count 0.
static func seconds_of(steps: Array[CutsceneStep]) -> float:
	var total := 0.0
	for step: CutsceneStep in steps:
		total += _seconds_of(step)
	return total

## The fragment `song` wakes; null when none.
func by_song(song: Song) -> BearerFragment:
	if song == null:
		return null
	for fragment: BearerFragment in fragments:
		if fragment != null and fragment.song != null and fragment.song.id == song.id:
			return fragment
	return null

## The guardians with no fragment listed.
func missing() -> Array[int]:
	var listed: Array[int] = []
	for fragment: BearerFragment in fragments:
		if fragment != null:
			listed.append(fragment.guardian)
	var absent: Array[int] = []
	for guardian: int in Enums.Guardian.values():
		if not listed.has(guardian):
			absent.append(guardian)
	return absent

## Problems with the fragments listed, one line each, against `cutscenes`, `guardian_stats` (guardian -> GuardianStats)
## and the engraving's `paper`; empty when sound. Missing guardians are `missing()`'s.
func validate(cutscenes: CutsceneCatalog, guardian_stats: Dictionary, paper: Color) -> PackedStringArray:
	var problems := PackedStringArray()
	var seen: Array[int] = []
	for fragment: BearerFragment in fragments:
		if fragment == null:
			problems.append("a null fragment")
			continue
		var name := String(Enums.Guardian.keys()[fragment.guardian]).to_lower()
		if seen.has(fragment.guardian):
			problems.append("%s: listed twice" % name)
		seen.append(fragment.guardian)
		var stats := guardian_stats.get(fragment.guardian) as GuardianStats
		if fragment.song == null or stats == null or stats.song == null or stats.song.id != fragment.song.id:
			problems.append("%s: its song is not its guardian's" % name)
		_check_scenes(fragment, name, cutscenes, problems)
		_check_call(fragment, name, paper, problems)
		if fragment.engraving != null:
			_check_engraving(fragment, name, problems)
		# "A faixa da própria canção (Recommended)" (user, 2026-11-13).
		if fragment.music == null or fragment.song == null or fragment.music.stream != fragment.song.track:
			problems.append("%s: its music is not its song's track" % name)
		if fragment.stage_room == &"":
			problems.append("%s: no stage room" % name)
	return problems

func _check_scenes(fragment: BearerFragment, name: String, cutscenes: CutsceneCatalog, problems: PackedStringArray) -> void:
	var roles := {&"call": fragment.call, &"engraving": fragment.engraving, &"returning": fragment.returning}
	for role: StringName in roles:
		var scene: Cutscene = roles[role]
		if scene == null:
			problems.append("%s: no %s scene" % [name, role])
		elif cutscenes != null and cutscenes.find(scene.id) == null:
			problems.append("%s: its %s '%s' is not in the cutscene catalog" % [name, role, scene.id])
		elif role != &"engraving" and scene.skippable:
			problems.append("%s: its %s is skippable" % [name, role])
	if fragment.engraving != null and fragment.engraving.id != BearerSchedule.id(fragment.guardian):
		problems.append("%s: its engraving is '%s', not '%s'" % [name, fragment.engraving.id,
				BearerSchedule.id(fragment.guardian)])
	# Its host is the room Ivo stood in, any of many: only Ivo resolves in all of them.
	if fragment.returning != null:
		for leaf: CutsceneStep in CutsceneCatalog.leaves(fragment.returning.steps):
			for id: StringName in leaf.names():
				if id != CutsceneStep.IVO:
					problems.append("%s: its returning scene names '%s'" % [name, id])

func _check_call(fragment: BearerFragment, name: String, paper: Color, problems: PackedStringArray) -> void:
	if fragment.call == null:
		return
	var last: CutsceneFade = null
	for leaf: CutsceneStep in CutsceneCatalog.leaves(fragment.call.steps):
		if leaf is CutsceneFade:
			last = leaf as CutsceneFade
	if last == null or not last.to_black or not last.colour.is_equal_approx(paper):
		problems.append("%s: its call does not end covered in the paper" % name)

func _check_engraving(fragment: BearerFragment, name: String, problems: PackedStringArray) -> void:
	var frames: Array[CutsceneEngraving] = []
	for leaf: CutsceneStep in CutsceneCatalog.leaves(fragment.engraving.steps):
		if leaf is CutsceneEngraving:
			frames.append(leaf as CutsceneEngraving)
	if frames.size() < MIN_FRAMES or frames.size() > MAX_FRAMES:
		problems.append("%s: %d frames, not %d..%d" % [name, frames.size(), MIN_FRAMES, MAX_FRAMES])
	for i: int in frames.size():
		var step := frames[i]
		if step.frame == null:
			problems.append("%s: frame %d has no frame" % [name, i + 1])
			continue
		if step.frame.captions.is_empty() or step.frame.captions.size() > MAX_CAPTIONS:
			problems.append("%s: frame %d has %d captions" % [name, i + 1, step.frame.captions.size()])
		if not EngravingMath.fits(step.frame):
			problems.append("%s: frame %d pans outside its canvas" % [name, i + 1])
		if step.dissolve != (i > 0):
			problems.append("%s: frame %d %s" % [name, i + 1, "dissolves over nothing" if i == 0 else "does not dissolve"])
		if fragment.song != null and step.ink != fragment.song.palette:
			problems.append("%s: frame %d is not inked in its song's palette" % [name, i + 1])
	var seconds := seconds_of(fragment.engraving.steps)
	if seconds < MIN_SECONDS or seconds > MAX_SECONDS:
		problems.append("%s: its engraving runs %.1f s, not %.0f..%.0f" % [name, seconds, MIN_SECONDS, MAX_SECONDS])

static func _seconds_of(step: CutsceneStep) -> float:
	if step is CutsceneTogether:
		var longest := 0.0
		for inner: CutsceneStep in (step as CutsceneTogether).steps:
			longest = maxf(longest, _seconds_of(inner))
		return longest
	if step is CutsceneSequence:
		return seconds_of((step as CutsceneSequence).steps)
	if step is CutsceneEngraving:
		return (step as CutsceneEngraving).frame.seconds if (step as CutsceneEngraving).frame != null else 0.0
	if step is CutsceneEngravingClear:
		return (step as CutsceneEngravingClear).seconds
	if step is CutsceneWait:
		return (step as CutsceneWait).seconds
	if step is CutsceneFade:
		return (step as CutsceneFade).seconds
	if step is CutsceneBars:
		return (step as CutsceneBars).seconds
	return 0.0

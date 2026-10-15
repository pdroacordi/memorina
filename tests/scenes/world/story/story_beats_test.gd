class_name StoryBeatsTest extends GdUnitTestSuite

## Every cue a talk names has exactly one beat in the rooms' contents and the song trials, and no beat answers a cue no
## talk names: DialogueBeat.find takes the first it meets (systems/story). Read from the scene files, not instanced.

const ROOMS := "res://scenes/world/rooms"
const CATALOG := "res://resources/dialogue/dialogue_catalog.tres"


func _contents(dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_contents(dir.path_join(sub)))
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with("_contents.tscn") or (dir == ROOMS and file.begins_with("trials_") and file.ends_with(".tscn")):
			found.append(dir.path_join(file))
	return found

## Cue -> the scenes that hold a beat answering it.
func _beats() -> Dictionary[StringName, PackedStringArray]:
	var beats: Dictionary[StringName, PackedStringArray] = {}
	for path: String in _contents(ROOMS):
		var state := (load(path) as PackedScene).get_state()
		for node: int in state.get_node_count():
			for i: int in state.get_node_property_count(node):
				if state.get_node_property_name(node, i) != &"cue":
					continue
				var cue := StringName(state.get_node_property_value(node, i))
				var where: PackedStringArray = beats.get(cue, PackedStringArray())
				where.append(path.get_file())
				beats[cue] = where
	return beats

func _cues() -> Array[StringName]:
	var cues: Array[StringName] = []
	for line: DialogueLine in (load(CATALOG) as DialogueCatalog).lines():
		if line.cue != &"" and not cues.has(line.cue):
			cues.append(line.cue)
	return cues

func test_every_cue_has_exactly_one_beat() -> void:
	var beats := _beats()
	var problems := PackedStringArray()
	for cue: StringName in _cues():
		var where: PackedStringArray = beats.get(cue, PackedStringArray())
		if where.size() != 1:
			problems.append("cue '%s' has %d beats: %s" % [cue, where.size(), ", ".join(where)])
	assert_array(Array(problems)).is_empty()

func test_every_beat_answers_a_cue() -> void:
	var cues := _cues()
	var problems := PackedStringArray()
	for cue: StringName in _beats():
		if not cues.has(cue):
			problems.append("a beat answers '%s', which no talk names" % cue)
	assert_array(Array(problems)).is_empty()

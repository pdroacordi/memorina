class_name StoryBeatsTest extends GdUnitTestSuite

## Every cue a talk names has exactly one beat in the rooms' contents and the song trials, and no beat answers a cue no
## talk names: DialogueBeat.find takes the first it meets (systems/story). The same holds for a line's gesture and its
## LineGesture (STORY-37). Read from the scene files, not instanced.

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

## Gesture -> the scenes that hold a LineGesture playing it.
func _line_gestures() -> Dictionary[StringName, PackedStringArray]:
	var found: Dictionary[StringName, PackedStringArray] = {}
	for path: String in _contents(ROOMS):
		var state := (load(path) as PackedScene).get_state()
		for node: int in state.get_node_count():
			for i: int in state.get_node_property_count(node):
				if state.get_node_property_name(node, i) != &"gesture":
					continue
				var id := StringName(state.get_node_property_value(node, i))
				var where: PackedStringArray = found.get(id, PackedStringArray())
				where.append(path.get_file())
				found[id] = where
	return found

func test_every_gesture_has_exactly_one_line_gesture_and_each_is_named() -> void:
	var named: Array[StringName] = []
	for line: DialogueLine in (load(CATALOG) as DialogueCatalog).lines():
		if line.gesture != &"" and not named.has(line.gesture):
			named.append(line.gesture)
	var found := _line_gestures()
	var problems := PackedStringArray()
	for id: StringName in named:
		var where: PackedStringArray = found.get(id, PackedStringArray())
		if where.size() != 1:
			problems.append("gesture '%s' has %d LineGestures: %s" % [id, where.size(), ", ".join(where)])
	for id: StringName in found:
		if not named.has(id):
			problems.append("a LineGesture plays '%s', which no line names" % id)
	assert_array(Array(problems)).is_empty()

## Each LineGesture names a FactStaging and a one-shot StagedStrip child of it; read from the instanced contents scenes.
func test_every_line_gesture_stands_in_a_one_shot_strip() -> void:
	var problems := PackedStringArray()
	for path: String in _contents(ROOMS):
		if not _line_gestures_in(path):
			continue
		var root := (load(path) as PackedScene).instantiate()
		for node: Node in root.find_children("*", "LineGesture", true, false):
			var gesture := node as LineGesture
			var staging := gesture.get_node_or_null(gesture.staging) as FactStaging
			var strip := staging.get_node_or_null(NodePath(gesture.child)) as StagedStrip if staging != null else null
			if strip == null:
				problems.append("%s: %s names no StagedStrip under a FactStaging" % [path.get_file(), gesture.name])
			elif strip.intro.is_empty() or not strip.loop.is_empty() or strip.sprite_frames.get_animation_loop(strip.intro):
				problems.append("%s: %s's strip is not a one-shot intro" % [path.get_file(), gesture.name])
		root.free()
	assert_array(Array(problems)).is_empty()

func _line_gestures_in(path: String) -> bool:
	return FileAccess.get_file_as_string(path).contains("line_gesture.gd")

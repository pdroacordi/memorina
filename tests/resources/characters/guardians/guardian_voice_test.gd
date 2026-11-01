class_name GuardianVoiceTest extends GdUnitTestSuite

## Every guardian has its words and its clips: a GuardianVoice with a bark per cure step, a retry bark and talks in the
## catalog, a speaker with a plate and a portrait, every key in the CSV, and every resolver clip in its tree on a strip
## of its frame size (systems/guardians, "Talks"; GRD-04 adds a guardian here).

const STATS_DIR := "res://resources/characters/guardians"
const SCENES_DIR := "res://scenes/characters/guardians"
const CATALOG := "res://resources/dialogue/dialogue_catalog.tres"
const CSV := "res://i18n/translations.csv"


func _all_stats() -> Array[GuardianStats]:
	var found: Array[GuardianStats] = []
	for dir: String in DirAccess.get_directories_at(STATS_DIR):
		for file: String in DirAccess.get_files_at(STATS_DIR.path_join(dir)):
			var stats := load(STATS_DIR.path_join(dir).path_join(file)) as GuardianStats if file.ends_with(".tres") else null
			if stats != null:
				found.append(stats)
	return found

func _scenes() -> Array[PackedScene]:
	var found: Array[PackedScene] = []
	for dir: String in DirAccess.get_directories_at(SCENES_DIR):
		for file: String in DirAccess.get_files_at(SCENES_DIR.path_join(dir)):
			if file.get_extension() == "tscn":
				found.append(load(SCENES_DIR.path_join(dir).path_join(file)) as PackedScene)
	return found

func _csv_keys() -> Dictionary:
	var keys := {}
	var file := FileAccess.open(CSV, FileAccess.READ)
	file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() >= 3:
			keys[row[0]] = row
	return keys

func test_every_guardian_has_a_voice_with_a_bark_per_cure_step() -> void:
	var all := _all_stats()
	assert_int(all.size()).is_greater_equal(2)
	var catalog := load(CATALOG) as DialogueCatalog
	var csv := _csv_keys()
	for stats: GuardianStats in all:
		var label := stats.resource_path.get_file()
		assert_object(stats.voice).override_failure_message("%s has no voice" % label).is_not_null()
		var voice := stats.voice
		assert_int(voice.lucid_barks.size()).override_failure_message(label).is_equal(stats.cycles_to_restore)
		assert_str(voice.retry_bark).override_failure_message(label).is_not_empty()
		assert_bool(catalog.sets.has(voice.talks)).override_failure_message("%s's talks are not in the catalog" % label).is_true()
		assert_object(voice.speaker).is_not_null()
		assert_object(voice.speaker.portrait).override_failure_message("%s's speaker has no portrait" % label).is_not_null()
		var keys: Array[String] = voice.lucid_barks.duplicate()
		keys.append(voice.retry_bark)
		keys.append(voice.speaker.name_key)
		for key: String in keys:
			assert_bool(csv.has(key)).override_failure_message("%s has no CSV row" % key).is_true()
			for cell: String in (csv.get(key, []) as PackedStringArray).slice(1):
				assert_str(cell).override_failure_message("%s has an empty cell" % key).is_not_empty()

func test_the_bark_follows_the_cycle_and_a_failure() -> void:
	var voice := GuardianVoice.new()
	voice.lucid_barks = ["A", "B"]
	voice.retry_bark = "R"
	assert_str(voice.bark_for(0, false)).is_equal("A")
	assert_str(voice.bark_for(1, false)).is_equal("B")
	assert_str(voice.bark_for(1, true)).is_equal("R")
	assert_str(voice.bark_for(5, false)).is_equal("B")

func test_the_first_talk_opens_on_restoration_and_the_second_after_it() -> void:
	for stats: GuardianStats in _all_stats():
		var data := PlayerData.new()
		var talks := stats.voice.talks
		assert_object(talks.current(data)).is_null()
		# The mentor's talk opens on the world restored (GRD-06), the others' on their own restoration.
		if stats.finale != null:
			data.world_restored = true
		else:
			data.restored_guardians[stats.id] = true
		var first := talks.current(data)
		assert_object(first).is_not_null()
		assert_bool(first.once).is_true()
		var tones: Array[int] = []
		for line: DialogueLine in first.lines:
			for choice: DialogueChoice in line.choices:
				tones.append(choice.tone)
		assert_array(tones).override_failure_message("%s's first talk has one HOLD/LET gesture" % first.id).contains_exactly_in_any_order(
				[DialogueChoice.Tone.HOLD_ON, DialogueChoice.Tone.LET_GO])
		data.dialogues_heard.append(first.id)
		var again := talks.current(data)
		assert_object(again).is_not_null()
		assert_bool(again.once).is_false()

func test_every_resolver_clip_is_in_every_guardian_tree_on_a_strip_of_its_frame_size() -> void:
	var scenes := _scenes()
	assert_int(scenes.size()).is_greater_equal(2)
	for scene: PackedScene in scenes:
		var guardian := auto_free(scene.instantiate()) as Guardian
		var tree := guardian.get_node(^"AnimationTree") as AnimationTree
		var machine := tree.tree_root as AnimationNodeStateMachine
		var player := guardian.get_node(^"AnimationPlayer") as AnimationPlayer
		var idle := player.get_animation(GuardianAnimationResolver.IDLE)
		var frame := _frame_size(idle)
		for clip: StringName in GuardianAnimationResolver.CLIPS:
			assert_bool(machine.has_node(clip)).override_failure_message("%s has no %s" % [scene.resource_path, clip]).is_true()
			var animation := player.get_animation(clip)
			assert_object(animation).override_failure_message("%s has no %s clip" % [scene.resource_path, clip]).is_not_null()
			if animation != null:
				assert_vector(_frame_size(animation)).override_failure_message("%s %s" % [scene.resource_path, clip]).is_equal(frame)

## A clip's frame in px: its texture split by its hframes.
func _frame_size(animation: Animation) -> Vector2:
	var texture: Texture2D
	var hframes := 1
	for track: int in animation.get_track_count():
		var path := String(animation.track_get_path(track))
		if path == "Sprite2D:texture":
			texture = animation.track_get_key_value(track, 0)
		elif path == "Sprite2D:hframes":
			hframes = animation.track_get_key_value(track, 0)
	if texture == null:
		return Vector2.ZERO
	return Vector2(texture.get_width() / float(hframes), texture.get_height())

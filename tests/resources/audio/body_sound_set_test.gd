class_name BodySoundSetTest extends GdUnitTestSuite

## Every EnemyStats and GuardianStats carries a sound set with a struck cue, and every creature and guardian scene a
## BodySounds; a creature's death ends before its body dissolves and is freed (systems/sound-effects).

const STATS_DIR := "res://resources/characters"
const CREATURE_DIR := "res://scenes/characters/creatures"
const GUARDIAN_DIR := "res://scenes/characters/guardians"


func test_every_stats_has_sounds_with_a_struck_cue() -> void:
	var stats := PackedStringArray()
	for path: String in _files(STATS_DIR, ".tres"):
		var res := load(path)
		if res is EnemyStats or res is GuardianStats:
			stats.append(path)
	assert_int(stats.size()).is_greater_equal(12)
	for path: String in stats:
		var res := load(path)
		var sounds: BodySoundSet = res.sounds
		assert_object(sounds).override_failure_message("%s has no sounds" % path).is_not_null()
		assert_object(sounds.struck).override_failure_message("%s has no struck cue" % path).is_not_null()
		if res is EnemyStats:
			assert_object(sounds.death).override_failure_message("%s has no death cue" % path).is_not_null()

func test_every_creature_and_guardian_scene_has_body_sounds() -> void:
	var scenes := _bodies()
	assert_int(scenes.size()).is_greater_equal(11)
	for path: String in scenes:
		var root := (load(path) as PackedScene).instantiate()
		assert_object(root.get_node_or_null(^"BodySounds") as BodySounds) \
				.override_failure_message("%s has no BodySounds" % path).is_not_null()
		root.free()

## The emitter is freed with the body once CorruptionEdge has dissolved it.
func test_a_creature_death_ends_before_the_body_is_gone() -> void:
	var shortest := INF
	for path: String in _files(CREATURE_DIR, ".tscn"):
		var root := (load(path) as PackedScene).instantiate()
		var edge := root.get_node_or_null(^"CorruptionEdge") as CorruptionEdge
		if edge != null:
			shortest = minf(shortest, edge.vanish_time)
		root.free()
	assert_float(shortest).is_less(INF)
	for path: String in _files(STATS_DIR, ".tres"):
		var stats := load(path) as EnemyStats
		if stats != null and stats.sounds != null and stats.sounds.death != null:
			assert_float(stats.sounds.death.length()) \
					.override_failure_message("%s: death outlasts the dissolve" % path).is_less_equal(shortest)

func _bodies() -> PackedStringArray:
	var found := PackedStringArray()
	for path: String in _files(CREATURE_DIR, ".tscn") + _files(GUARDIAN_DIR, ".tscn"):
		var root := (load(path) as PackedScene).instantiate()
		if root is Enemy or root is Guardian:
			found.append(path)
		root.free()
	return found

func _files(dir: String, suffix: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_files(dir.path_join(sub), suffix))
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with(suffix):
			found.append(dir.path_join(file))
	return found

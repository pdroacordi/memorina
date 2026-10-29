class_name EnemyStatsTest extends GdUnitTestSuite

## Every shipped EnemyStats validates; a bad one says why.

const ROOT := "res://resources/characters/creatures/"


func test_every_shipped_enemy_stats_validates() -> void:
	var found := 0
	for path: String in _tres_under(ROOT):
		var resource := load(path)
		if resource is EnemyStats:
			found += 1
			var problems := (resource as EnemyStats).validate()
			assert_array(Array(problems)).override_failure_message("%s: %s" % [path, problems]).is_empty()
	assert_int(found).is_greater_equal(3)

func test_empty_stats_report_the_missing_parts() -> void:
	var problems := EnemyStats.new().validate()
	assert_bool(_mentions(problems, "locomotion")).is_true()
	assert_bool(_mentions(problems, "moves is empty")).is_true()

func test_a_stop_distance_past_every_reach_is_refused() -> void:
	var stats := _valid()
	stats.stop_distance = stats.moves[0].reach.end.x + 1.0
	assert_bool(_mentions(stats.validate(), "stop_distance")).is_true()

func test_a_move_without_a_hitbox_is_refused() -> void:
	var stats := _valid()
	stats.moves[0].hitbox = &""
	assert_bool(_mentions(stats.validate(), "hitbox")).is_true()

func test_valid_stats_report_nothing() -> void:
	assert_array(Array(_valid().validate())).is_empty()

func _valid() -> EnemyStats:
	var stats := EnemyStats.new()
	stats.locomotion = LocomotionStats.new()
	var move := EnemyMove.new()
	move.hitbox = &"StrikeHitbox"
	move.reach = Rect2(0, -40, 60, 48)
	stats.moves = [move]
	stats.stop_distance = 40.0
	return stats

func _mentions(problems: PackedStringArray, text: String) -> bool:
	for problem: String in problems:
		if problem.contains(text):
			return true
	return false

func _tres_under(dir_path: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir_path):
		found.append_array(_tres_under(dir_path.path_join(sub)))
	for file: String in DirAccess.get_files_at(dir_path):
		if file.ends_with(".tres"):
			found.append(dir_path.path_join(file))
	return found

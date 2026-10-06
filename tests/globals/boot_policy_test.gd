class_name BootPolicyTest extends GdUnitTestSuite

## Headless runs and the playtest runner stay in memory; debug boots slot 1 unless --title; release begins nothing.

var _no_args := PackedStringArray()


func test_a_headless_run_is_memory_only() -> void:
	assert_int(BootPolicy.decide(true, true, _no_args, _no_args)).is_equal(BootPolicy.Session.MEMORY)
	assert_int(BootPolicy.decide(true, false, _no_args, _no_args)).is_equal(BootPolicy.Session.MEMORY)

## Windowed and debug, the runner still never reads, moves or writes a save.
func test_the_playtest_runner_is_memory_only_however_it_is_named() -> void:
	for scene: String in ["res://tools/playtest/playtest_runner.tscn", "tools/playtest/playtest_runner.tscn"]:
		var args := PackedStringArray(["--path", ".", scene])
		var user_args := PackedStringArray(["--script=res://tools/playtest/scripts/x.json", "--out=C:/out"])
		assert_int(BootPolicy.decide(false, true, args, user_args)).is_equal(BootPolicy.Session.MEMORY)

## The editor's GdUnit panel runs the suite windowed, by play_custom_scene or by a child process.
func test_the_gdunit_runner_is_memory_only_from_the_editor() -> void:
	var scene := "res://addons/gdUnit4/src/core/runners/GdUnitTestRunner.tscn"
	for args: PackedStringArray in [
		PackedStringArray(["--editor-pid", "31800", "--scene", scene]),
		PackedStringArray(["--no-window", "--path", "D:/Projects/memorina/", scene]),
	]:
		assert_int(BootPolicy.decide(false, true, args, _no_args)).is_equal(BootPolicy.Session.MEMORY)

func test_a_debug_build_continues_slot_1_or_starts_it_fresh() -> void:
	assert_int(BootPolicy.decide(false, true, _no_args, _no_args)).is_equal(BootPolicy.Session.SLOT_1)
	var fresh := PackedStringArray([BootPolicy.NEW_GAME_ARG])
	assert_int(BootPolicy.decide(false, true, _no_args, fresh)).is_equal(BootPolicy.Session.SLOT_1_FRESH)

func test_title_lets_a_debug_build_reach_the_title() -> void:
	var title := PackedStringArray([BootPolicy.TITLE_ARG])
	assert_int(BootPolicy.decide(false, true, _no_args, title)).is_equal(BootPolicy.Session.NONE)

func test_a_release_build_begins_nothing() -> void:
	assert_int(BootPolicy.decide(false, false, _no_args, _no_args)).is_equal(BootPolicy.Session.NONE)
	var fresh := PackedStringArray([BootPolicy.NEW_GAME_ARG])
	assert_int(BootPolicy.decide(false, false, _no_args, fresh)).is_equal(BootPolicy.Session.NONE)

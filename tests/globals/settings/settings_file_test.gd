class_name SettingsFileTest extends GdUnitTestSuite

## The file is written and read in its directory; with no directory nothing is written and nothing is read.

const DIR := "user://settings_file_test"


func before_test() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))

func after_test() -> void:
	for debug: bool in [true, false]:
		var path := DIR.path_join(SettingsFile.file_name(debug))
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(DIR))

func test_write_then_read_round_trips() -> void:
	var file := SettingsFile.new(DIR, true)
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", 4)
	assert_bool(file.write(cfg)).is_true()
	var read := file.read()
	assert_object(read).is_not_null()
	assert_int(int(read.get_value("audio", "music", 0))).is_equal(4)

func test_an_absent_file_reads_null() -> void:
	assert_object(SettingsFile.new(DIR, false).read()).is_null()

func test_no_disk_writes_nothing_and_reads_null() -> void:
	var file := SettingsFile.new("", true)
	assert_bool(file.has_disk()).is_false()
	assert_str(file.path()).is_empty()
	assert_bool(file.write(ConfigFile.new())).is_false()
	assert_object(file.read()).is_null()

func test_debug_builds_use_their_own_file() -> void:
	assert_str(SettingsFile.file_name(true)).is_equal("settings_debug.cfg")
	assert_str(SettingsFile.file_name(false)).is_equal("settings.cfg")

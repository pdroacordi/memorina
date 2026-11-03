class_name RegionMusicTest extends GdUnitTestSuite

## RegionMusic asks for the theme of the region Ivo is in, keeps it across that region's rooms and lifts the memory
## stem with the region's memory.

const ROAD_CUE := "res://resources/music/region_threshold.tres"
const LAKE_CUE := "res://resources/music/region_frozen_lake.tres"

var _music: RegionMusic


func before_test() -> void:
	SaveSystem.begin("", true)
	_music = auto_free(RegionMusic.new()) as RegionMusic
	add_child(_music)

func after_test() -> void:
	var left := Music.playing()
	while left != null:
		Music.release(left, 0.0)
		left = Music.playing()
	SaveSystem.begin("", true)

## A region with two rooms, its memory at `memory` and its theme `cue` (a path, or "" for none).
func _region(cue: String, memory: float) -> Region:
	var region := Region.new()
	if not cue.is_empty():
		region.music = load(cue) as MusicCue
	var store := RegionMemory.new()
	store.name = "Memory"
	store.authored = memory
	region.add_child(store)
	for i: int in 2:
		var room := Room.new()
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		room.add_child(shape)
		region.add_child(room)
	add_child(region)
	return auto_free(region)

func _room(region: Region, index: int) -> Room:
	return region.get_child(1 + index) as Room

func test_the_memory_stem_is_the_square_of_the_memory() -> void:
	assert_float(RegionMusic.memory_level(0.0)).is_equal(0.0)
	assert_float(RegionMusic.memory_level(0.3)).is_equal_approx(0.09, 0.0001)
	assert_float(RegionMusic.memory_level(1.0)).is_equal(1.0)
	assert_float(RegionMusic.memory_level(1.5)).is_equal(1.0)

func test_entering_a_region_plays_its_theme_with_the_memory_stem_at_its_level() -> void:
	var road := _region(ROAD_CUE, 0.3)
	_music.on_room_changed(_room(road, 0))
	var playing := Music.playing()
	assert_object(playing).is_not_null()
	assert_object(playing.cue).is_same(road.music)
	assert_float(playing.levels[RegionMusic.MEMORY_STEM]).is_equal_approx(0.09, 0.0001)

func test_another_room_of_the_same_region_keeps_the_same_request() -> void:
	var road := _region(ROAD_CUE, 0.3)
	_music.on_room_changed(_room(road, 0))
	var first := Music.playing()
	_music.on_room_changed(_room(road, 1))
	assert_object(Music.playing()).is_same(first)

func test_a_change_of_memory_moves_the_stem_without_a_new_request() -> void:
	var road := _region(ROAD_CUE, 0.3)
	_music.on_room_changed(_room(road, 0))
	var first := Music.playing()
	road.get_node(^"Memory").restore(0.0)
	assert_object(Music.playing()).is_same(first)
	assert_float(first.levels[RegionMusic.MEMORY_STEM]).is_equal(1.0)

func test_a_new_region_takes_over_and_a_silent_one_releases() -> void:
	var road := _region(ROAD_CUE, 0.3)
	var lake := _region(LAKE_CUE, 0.3)
	var frost := _region("", 0.05)
	_music.on_room_changed(_room(road, 0))
	_music.on_room_changed(_room(lake, 0))
	assert_object(Music.playing().cue).is_same(lake.music)
	_music.on_room_changed(_room(frost, 0))
	assert_object(Music.playing()).is_null()

func test_every_region_cue_names_base_and_memory() -> void:
	for path: String in DirAccess.get_files_at("res://resources/music"):
		if not path.begins_with("region_"):
			continue
		var cue := load("res://resources/music/" + path) as MusicCue
		assert_array(Array(cue.validate())).is_empty()
		assert_array(cue.stems).is_equal([&"base", &"memory"])

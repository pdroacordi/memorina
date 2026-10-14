class_name RegionTitleWatcherTest extends GdUnitTestSuite

## The watcher records the first room silently, announces a new region once and keeps the save in step.

const ROAD := "res://scenes/world/rooms/threshold.tscn"
const ROAD_ROOMS: Array[String] = [
	"res://scenes/world/rooms/threshold/threshold_fields.tscn",
	"res://scenes/world/rooms/threshold/threshold_bridge.tscn",
]
const FROST := "res://scenes/world/rooms/frost_edge.tscn"
const FROST_ROOMS: Array[String] = [
	"res://scenes/world/rooms/frost_edge/frost_shore.tscn",
	"res://scenes/world/rooms/frost_edge/frost_cliffs.tscn",
]
const TRIALS := "res://scenes/world/rooms/trials_winter.tscn"

var _watcher: RegionTitleWatcher
var _heard: Array[PackedStringArray] = []


func before_test() -> void:
	SaveSystem.begin("", true)
	_heard.clear()
	_watcher = auto_free(RegionTitleWatcher.new()) as RegionTitleWatcher
	add_child(_watcher)
	_watcher.announced.connect(func(name_key: String, epithet_key: String) -> void:
		_heard.append(PackedStringArray([name_key, epithet_key])))

func after_test() -> void:
	SaveSystem.begin("", true)

## A region with a room per path in `rooms`; the scene paths key them the way placed scenes are keyed.
func _region(scene: String, name_key: String, rooms: Array[String], shows_title: bool = true) -> Region:
	var region := Region.new()
	region.scene_file_path = scene
	region.name_key = name_key
	region.epithet_key = name_key + "_EPITHET"
	region.shows_title = shows_title
	var memory := RegionMemory.new()
	memory.name = "Memory"
	region.add_child(memory)
	for path: String in rooms:
		var room := Room.new()
		room.scene_file_path = path
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		room.add_child(shape)
		region.add_child(room)
	add_child(region)
	return auto_free(region)

func _room(region: Region, index: int) -> Room:
	return region.get_child(1 + index) as Room

func test_the_first_room_is_recorded_without_a_title() -> void:
	var road := _region(ROAD, "REGION_THRESHOLD", ROAD_ROOMS)
	_watcher.on_room_changed(_room(road, 0))
	assert_array(_heard).is_empty()
	assert_bool(SaveSystem.is_region_announced(SceneKey.of(road))).is_true()

func test_a_new_region_is_announced_with_its_keys_and_saved() -> void:
	var road := _region(ROAD, "REGION_THRESHOLD", ROAD_ROOMS)
	var frost := _region(FROST, "REGION_FROST_EDGE", FROST_ROOMS)
	_watcher.on_room_changed(_room(road, 0))
	_watcher.on_room_changed(_room(frost, 0))
	assert_int(_heard.size()).is_equal(1)
	assert_array(Array(_heard[0])).is_equal(["REGION_FROST_EDGE", "REGION_FROST_EDGE_EPITHET"])
	assert_array(SaveSystem.player_data.announced_regions).contains_exactly(
			[StringName(SceneKey.of(road)), StringName(SceneKey.of(frost))])

func test_walking_back_and_forth_announces_once() -> void:
	var road := _region(ROAD, "REGION_THRESHOLD", ROAD_ROOMS)
	var frost := _region(FROST, "REGION_FROST_EDGE", FROST_ROOMS)
	_watcher.on_room_changed(_room(road, 0))
	for i: int in 3:
		_watcher.on_room_changed(_room(frost, 0))
		_watcher.on_room_changed(_room(frost, 1))
		_watcher.on_room_changed(_room(road, 1))
	assert_int(_heard.size()).is_equal(1)

## A rebuilt world (a death, a load) starts with a fresh watcher on a save that already holds the region.
func test_a_region_announced_before_the_rebuild_stays_quiet() -> void:
	var road := _region(ROAD, "REGION_THRESHOLD", ROAD_ROOMS)
	var frost := _region(FROST, "REGION_FROST_EDGE", FROST_ROOMS)
	SaveSystem.announce_region(SceneKey.of(frost))
	_watcher.on_room_changed(_room(road, 0))
	_watcher.on_room_changed(_room(frost, 0))
	assert_array(_heard).is_empty()

## A region without a title (the village, a test bed) is neither announced nor recorded, even as the first room.
func test_an_untitled_region_is_neither_announced_nor_recorded() -> void:
	var trials := _region(TRIALS, "REGION_TRIALS", [], false)
	var room := Room.new()
	room.scene_file_path = "res://scenes/world/rooms/trials/trial_winter.tscn"
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	room.add_child(shape)
	trials.add_child(room)
	var road := _region(ROAD, "REGION_THRESHOLD", ROAD_ROOMS)
	_watcher.on_room_changed(room)
	_watcher.on_room_changed(_room(road, 0))
	assert_int(_heard.size()).is_equal(1)
	assert_bool(SaveSystem.is_region_announced(SceneKey.of(trials))).is_false()

## A save made before the title, or a dev slot, already has rooms on the map: their regions stay quiet.
func test_regions_explored_on_the_map_are_recorded_at_the_first_room() -> void:
	var road := _region(ROAD, "REGION_THRESHOLD", ROAD_ROOMS)
	var frost := _region(FROST, "REGION_FROST_EDGE", FROST_ROOMS)
	var untitled := _region(TRIALS, "REGION_TRIALS", [], false)
	SaveSystem.set_map_seen(SceneKey.of(_room(frost, 1)), PackedByteArray([1, 0, 1, 0, 1]))
	_watcher.on_room_changed(_room(road, 0))
	assert_bool(SaveSystem.is_region_announced(SceneKey.of(frost))).is_true()
	assert_bool(SaveSystem.is_region_announced(SceneKey.of(untitled))).is_false()
	_watcher.on_room_changed(_room(frost, 0))
	assert_array(_heard).is_empty()

## The map is read once, at the first room: a region first seen later in this world still announces.
func test_the_map_is_read_only_at_the_first_room() -> void:
	var road := _region(ROAD, "REGION_THRESHOLD", ROAD_ROOMS)
	var frost := _region(FROST, "REGION_FROST_EDGE", FROST_ROOMS)
	_watcher.on_room_changed(_room(road, 0))
	SaveSystem.set_map_seen(SceneKey.of(_room(frost, 0)), PackedByteArray([1, 0, 1, 0, 1]))
	_watcher.on_room_changed(_room(frost, 0))
	assert_int(_heard.size()).is_equal(1)

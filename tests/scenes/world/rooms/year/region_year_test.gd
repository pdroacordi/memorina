class_name RegionYearTest extends GdUnitTestSuite

## RegionYear advances only on an open room of its region, out of any story and with no forgetting source in view; it
## holds mid-turn, commits with season_changed, and only the year the field follows advances.

const VILLAGE := "res://scenes/world/rooms/home_village.tscn"
const THRESHOLD := "res://scenes/world/rooms/threshold.tscn"

var _field: MemoryField
var _village: Region


func before_test() -> void:
	SaveSystem.begin("", true)
	_field = auto_free(MemoryField.new()) as MemoryField
	add_child(_field)
	_village = auto_free((load(VILLAGE) as PackedScene).instantiate()) as Region
	add_child(_village)

func after_test() -> void:
	SaveSystem.begin("", true)

func _year() -> RegionYear:
	return _village.year

func test_the_village_carries_its_year_and_starts_in_its_own_season() -> void:
	assert_object(_year()).is_not_null()
	assert_int(_year().season()).is_equal(_village.season)
	assert_int(_village.current_season()).is_equal(_village.season)
	assert_float(_year().turn()).is_equal(0.0)

func test_the_rule_needs_an_open_room_of_its_region_out_of_story_and_no_forgetting() -> void:
	var square := _village.get_node("VillageSquare") as Room
	var house := _village.get_node("VillageHouse") as Room
	var threshold := auto_free((load(THRESHOLD) as PackedScene).instantiate()) as Region
	add_child(threshold)
	var elsewhere: Room = threshold.find_children("*", "Room", false).filter(func(room: Room) -> bool: return room.has_sky())[0]
	for room: Variant in [square, house, elsewhere, null]:
		for gate: bool in [false, true]:
			for in_story: bool in [false, true]:
				for forgetting: bool in [false, true]:
					var expected: bool = room == square and gate and not in_story and not forgetting
					assert_bool(RegionYear.may_advance(gate, room as Room, _village, in_story, forgetting)).is_equal(expected)

func test_a_negative_source_in_view_is_forgetting_and_a_pulse_is_not() -> void:
	var view := Rect2(0, 0, 640, 360)
	var mark := auto_free(MemorySource.new()) as MemorySource
	mark.strength = -0.5
	mark.position = Vector2(320, 180)
	add_child(mark)
	_field.register(mark)
	assert_bool(RegionYear.forgetting_in_view(_field, view)).is_true()
	assert_bool(RegionYear.forgetting_in_view(_field, Rect2(5000, 5000, 640, 360))).is_false()
	mark.strength = 0.6
	assert_bool(RegionYear.forgetting_in_view(_field, view)).is_false()
	mark.strength = -0.5
	mark.visible = false
	assert_bool(RegionYear.forgetting_in_view(_field, view)).is_false()

func test_it_holds_until_the_field_follows_it() -> void:
	SaveSystem.restore_world()
	assert_bool(_year().can_advance()).is_false()
	_field.year = auto_free(RegionYear.new()) as RegionYear
	assert_bool(_year().can_advance()).is_false()

func test_it_holds_mid_turn_and_commits_with_season_changed() -> void:
	var commits: Array[int] = []
	_year().season_changed.connect(func(season: Enums.Season) -> void: commits.append(season))
	var stats := _year().stats
	_year().advance(stats.season_seconds - stats.turn_seconds * 0.5)
	var held := _year().turn()
	assert_float(held).is_between(0.01, 0.99)
	assert_array(commits).is_empty()
	for frame: int in range(0, 30):
		_year()._physics_process(1.0 / 60.0)
	assert_float(_year().turn()).is_equal(held)
	_year().advance(stats.turn_seconds)
	assert_array(commits).is_equal([Enums.Season.SUMMER])
	assert_int(_village.current_season()).is_equal(Enums.Season.SUMMER)
	_year().advance(stats.season_seconds * 3.0)
	assert_array(commits).is_equal([Enums.Season.SUMMER, Enums.Season.AUTUMN, Enums.Season.WINTER, Enums.Season.SPRING])

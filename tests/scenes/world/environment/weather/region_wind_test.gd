class_name RegionWindTest extends GdUnitTestSuite

## The region's push blows only under its own sky and outside a lee, restarts in a calm on walking out from under
## rock, and is never a memory source (architecture/regional-weather-push).

const WIND := preload("res://scenes/world/environment/weather/region_wind.tscn")
const SHELTER := preload("res://scenes/world/environment/weather/weather_shelter.tscn")
const THRESHOLD := "res://scenes/world/rooms/threshold.tscn"
const FROST_EDGE := "res://scenes/world/rooms/frost_edge.tscn"
## Profile seconds that put the blizzard at full gust: its calm and its rise.
const TO_GUST := 7.5

var _threshold: Region
var _frost_edge: Region
var _wind: RegionWind


func before_test() -> void:
	_threshold = auto_free((load(THRESHOLD) as PackedScene).instantiate()) as Region
	_frost_edge = auto_free((load(FROST_EDGE) as PackedScene).instantiate()) as Region
	add_child(_threshold)
	add_child(_frost_edge)
	_wind = auto_free(WIND.instantiate()) as RegionWind
	add_child(_wind)

func _room(region: Region, node_name: String) -> Room:
	return region.get_node(node_name) as Room

func _centre(region: Region, node_name: String) -> Vector2:
	return _room(region, node_name).get_bounds().get_center()

## Walks into `node_name` and runs the clock to full gust.
func _gusting_in(node_name: String) -> void:
	_wind.on_room_changed(_room(_threshold, node_name))
	(_wind.get(&"_gust") as WeatherGust).step(TO_GUST, 1.0, false)

func test_it_blows_west_under_the_sky() -> void:
	_gusting_in("ThresholdFields")
	var profile := load("res://resources/world/weather/winter_blizzard.tres") as WeatherProfile
	assert_vector(_wind.wind_at(_centre(_threshold, "ThresholdFields"))).is_equal(Vector2(-profile.speed, 0.0))
	assert_float(_wind.drive()).is_equal(-1.0)

func test_it_is_still_indoors_under_rock_and_in_another_region() -> void:
	_gusting_in("ThresholdFields")
	assert_vector(_wind.wind_at(_centre(_threshold, "ThresholdFarmhouse"))).is_equal(Vector2.ZERO)
	assert_vector(_wind.wind_at(_centre(_threshold, "ThresholdRavineCave"))).is_equal(Vector2.ZERO)
	assert_vector(_wind.wind_at(_centre(_frost_edge, "FrostShore"))).is_equal(Vector2.ZERO)

func test_it_is_still_inside_a_weather_shelter() -> void:
	_gusting_in("ThresholdFields")
	var shelter := auto_free(SHELTER.instantiate()) as WeatherShelter
	var at := _centre(_threshold, "ThresholdFields")
	shelter.position = at + Vector2(0, 16)
	add_child(shelter)
	assert_vector(_wind.wind_at(at)).is_equal(Vector2.ZERO)
	assert_vector(_wind.wind_at(at + Vector2(200, 0))).is_not_equal(Vector2.ZERO)

func test_intensity_scales_the_push() -> void:
	_gusting_in("ThresholdFields")
	Settings.set_weather(0)
	var still := _wind.wind_at(_centre(_threshold, "ThresholdFields"))
	Settings.set_weather(GameSettings.WEATHER_STEPS)
	assert_vector(still).is_equal(Vector2.ZERO)

func test_leaving_a_covered_room_restarts_in_a_calm() -> void:
	_gusting_in("ThresholdBridge")
	_wind.on_room_changed(_room(_threshold, "ThresholdRavineCave"))
	assert_float(_wind.drive()).override_failure_message("a cave does not restart the clock").is_equal(-1.0)
	_wind.on_room_changed(_room(_threshold, "ThresholdBridge"))
	assert_float(_wind.drive()).is_equal(0.0)

func test_walking_on_under_the_sky_keeps_the_gust() -> void:
	_gusting_in("ThresholdFields")
	_wind.on_room_changed(_room(_threshold, "ThresholdBridge"))
	assert_float(_wind.drive()).is_equal(-1.0)

func test_another_region_restarts_in_a_calm() -> void:
	_gusting_in("ThresholdWayshrine")
	_wind.on_room_changed(_room(_frost_edge, "FrostShore"))
	assert_float(_wind.drive()).is_equal(0.0)

func test_it_holds_no_memory_source() -> void:
	var wind := auto_free(WIND.instantiate()) as Node
	var found: Array[Node] = [wind]
	found.append_array(wind.find_children("*", "", true, false))
	for node: Node in found:
		assert_bool(node is MemorySource).override_failure_message("%s is a MemorySource" % node.name).is_false()
		assert_bool(node is ColorPulse).override_failure_message("%s is a ColorPulse" % node.name).is_false()

func test_a_hazard_respawn_restarts_in_a_calm() -> void:
	_gusting_in("ThresholdBridge")
	_wind.on_hazard_respawned()
	assert_float(_wind.drive()).is_equal(0.0)

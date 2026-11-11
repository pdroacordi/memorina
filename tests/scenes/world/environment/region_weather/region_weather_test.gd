class_name RegionWeatherTest extends GdUnitTestSuite

## The ambient sky fades out under rock, the gust layer follows the drive and the intensity, and neither writes `amount`
## (architecture/regional-weather-push).

const WEATHER := preload("res://scenes/world/environment/region_weather/region_weather.tscn")
const WIND := preload("res://scenes/world/environment/weather/region_wind.tscn")
const THRESHOLD := "res://scenes/world/rooms/threshold.tscn"
const WINTER := "res://resources/songs/palettes/winter_palette.tres"
const FRAME := 1.0 / 60.0

var _threshold: Region
var _wind: RegionWind
var _weather: RegionWeather


func before_test() -> void:
	var field := auto_free(MemoryField.new()) as MemoryField
	field.season = Enums.Season.WINTER
	field.palette = load(WINTER) as SeasonPalette
	add_child(field)
	_threshold = auto_free((load(THRESHOLD) as PackedScene).instantiate()) as Region
	add_child(_threshold)
	_wind = auto_free(WIND.instantiate()) as RegionWind
	add_child(_wind)
	_weather = auto_free(WEATHER.instantiate()) as RegionWeather
	_weather.wind = _wind
	add_child(_weather)
	_enter("ThresholdFields")

func after_test() -> void:
	Settings.set_weather(GameSettings.WEATHER_STEPS)

func _enter(node_name: String) -> void:
	var room := _threshold.get_node(node_name) as Room
	_wind.on_room_changed(room)
	_weather.on_room_changed(room)
	_weather._process(FRAME)

func _ambient() -> CPUParticles2D:
	return _weather.get_node("WinterPulseParticles") as CPUParticles2D

func _gusts() -> CPUParticles2D:
	return _weather.get_node("WinterGustParticles") as CPUParticles2D

func _to_gust() -> void:
	(_wind.get(&"_gust") as WeatherGust).step(7.5, 1.0, false)
	_weather._process(FRAME)

func test_the_sky_fades_out_under_rock() -> void:
	assert_bool(_weather.visible).is_true()
	_enter("ThresholdRavineCave")
	assert_bool(_weather.visible).override_failure_message("fading, not cut").is_true()
	_weather._process(RegionWeather.SKY_FADE)
	assert_bool(_weather.visible).is_false()
	_enter("ThresholdFields")
	_weather._process(RegionWeather.SKY_FADE)
	assert_bool(_weather.visible).is_true()

func test_the_gusts_blow_with_the_drive() -> void:
	assert_float(_gusts().modulate.a).override_failure_message("a calm on entry").is_equal(0.0)
	_to_gust()
	assert_float(_gusts().modulate.a).is_equal(1.0)
	assert_float(_gusts().direction.x).is_equal(-1.0)

func test_intensity_zero_hides_the_gusts_and_the_sky() -> void:
	_to_gust()
	Settings.set_weather(0)
	_weather._process(FRAME)
	assert_float(_gusts().modulate.a).is_equal(0.0)
	assert_float(_ambient().modulate.a).is_equal(0.0)
	assert_bool(_weather.visible).is_false()

func test_intensity_never_writes_amount() -> void:
	var amount := _ambient().amount
	var gust_amount := _gusts().amount
	for step: int in [5, 0, 10]:
		Settings.set_weather(step)
		_weather._process(FRAME)
		assert_int(_ambient().amount).is_equal(amount)
		assert_int(_gusts().amount).is_equal(gust_amount)

func test_half_intensity_halves_the_ambient_alpha() -> void:
	var full := _ambient().modulate.a
	Settings.set_weather(5)
	_weather._process(FRAME)
	assert_float(_ambient().modulate.a).is_equal_approx(full * 0.5, 0.001)

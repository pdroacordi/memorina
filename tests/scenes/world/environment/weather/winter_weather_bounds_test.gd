class_name WinterWeatherBoundsTest extends GdUnitTestSuite

## The winter blizzard's bounds against Ivo's real tuning: the calm is still air for every jump and long enough for a
## song, a full gust breaks a drawn Memorina, and a fight's gust never moves his feet (architecture/regional-weather-push).

const BLIZZARD := "res://resources/world/weather/winter_blizzard.tres"
const PLAYER := "res://scenes/characters/ivo/player.gd"
## Px/s of air a calm may carry.
const CALM_AIR := 3.0
## Px a calm headwind may take off any jump.
const JUMP_SLACK := 4.0
## Real seconds of a six-note song.
const SONG_TIME := 3.0
const CELL := 32.0

var _profile: WeatherProfile
var _reach: JumpReach


func before() -> void:
	_profile = load(BLIZZARD) as WeatherProfile
	_reach = MapGuide.ivo_reach()

func _calm_air() -> float:
	return _profile.speed * _profile.gusts.calm_strength

func _shelter() -> float:
	return (load(PLAYER) as Script).get_property_default_value("memorina_shelter")

## The ground drift Ivo's feet take from `wind_x`, through the real LocomotionComponent.
func _drift(wind_x: float) -> float:
	var locomotion := LocomotionComponent.new()
	locomotion.stats = _reach.locomotion
	var drift := locomotion.ground_drift(wind_x)
	locomotion.free()
	return drift

## Seconds of a running jump from take-off until it is back at take-off height.
func _airtime() -> float:
	var points := _reach.arc()
	for i: int in range(1, points.size()):
		if points[i].y >= 0.0 and points[i].y > points[i - 1].y:
			return i * JumpReach.STEP
	return points.size() * JumpReach.STEP

func test_the_calm_is_still_air() -> void:
	assert_float(_calm_air()).is_less_equal(CALM_AIR)

func test_a_calm_headwind_keeps_every_jump() -> void:
	var still := MapGuide.ivo_reach()
	var headwind := MapGuide.ivo_reach()
	var air := Vector2(-_calm_air(), 0.0)
	headwind.wind = func(_at: Vector2) -> Vector2: return air
	assert_float(still.gap() - headwind.gap()).is_less_equal(JUMP_SLACK)
	for k: int in 5:
		var lost := still.reach_at(CELL * k) - headwind.reach_at(CELL * k)
		assert_float(lost).override_failure_message("a jump %d cells up loses %.1f px" % [k, lost]).is_less_equal(JUMP_SLACK)

func test_a_calm_holds_a_song_and_a_jump() -> void:
	assert_float(_profile.gusts.calm_time).is_greater_equal(SONG_TIME + _airtime())

func test_a_full_gust_breaks_a_drawn_memorina() -> void:
	assert_float(absf(_drift(_profile.speed * _shelter()))).is_greater_equal(Player.STILL_SPEED_EPSILON)

func test_a_fights_gust_never_moves_his_feet() -> void:
	assert_float(_profile.speed * _profile.fight_scale).is_less(_reach.locomotion.wind_deadzone)

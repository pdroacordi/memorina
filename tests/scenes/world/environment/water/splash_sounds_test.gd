class_name SplashSoundsTest extends GdUnitTestSuite

## A splash in a pool or shallow water sounds where it broke the surface: small under `large_speed`, large at or over
## it, levelled by speed (systems/sound-effects).

const POOL := "res://scenes/world/environment/water/water_pool.tscn"
const SHALLOW := "res://scenes/world/environment/water/water_shallow.tscn"
const SET := preload("res://resources/audio/sfx/world/splash_sounds.tres")

var _played: Array[SoundCue] = []


func before_test() -> void:
	_played.clear()

func _spawn(path: String) -> WaterBody:
	var body := (load(path) as PackedScene).instantiate() as WaterBody
	body.position = Vector2(300, 200)
	add_child(body)
	auto_free(body)
	var sounds := body.get_node(^"SplashSounds") as SplashSounds
	sounds.emitter().cue_played.connect(func(cue: SoundCue) -> void: _played.append(cue))
	return body

func test_the_cue_follows_the_speed() -> void:
	assert_object(SET.cue_for(SET.large_speed - 1.0)).is_same(SET.small)
	assert_object(SET.cue_for(SET.large_speed)).is_same(SET.large)

func test_both_scenes_sound_a_splash() -> void:
	for path: String in [POOL, SHALLOW]:
		# Past the cue's cooldown, which every emitter shares.
		await await_millis(int(SET.large.cooldown * 1000.0) + 30)
		_played.clear()
		var body := _spawn(path)
		body.splash(body.global_position.x, SET.large_speed + 100.0)
		assert_array(_played).override_failure_message(path).contains_exactly([SET.large])

func test_a_splash_sounds_at_the_surface_levelled_by_speed() -> void:
	var body := _spawn(POOL)
	var x := body.global_position.x + 20.0
	var surface := body.surface_y(x)
	var speed := 300.0
	body.splash(x, speed)
	assert_array(_played).contains_exactly([SET.small])
	var sounds := body.get_node(^"SplashSounds") as SplashSounds
	var player := sounds.emitter().player_of(SET.small) as AudioStreamPlayer2D
	assert_vector(player.global_position).is_equal_approx(Vector2(x, surface), Vector2.ONE * 0.01)
	var expected := SET.small.volume_db + ImpactLevel.db(speed, SET.quiet_speed, SET.full_speed)
	assert_float(player.volume_db).is_equal_approx(expected, 0.001)

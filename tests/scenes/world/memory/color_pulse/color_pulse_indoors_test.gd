class_name ColorPulseIndoorsTest extends GdUnitTestSuite

## "No season indoors (Recommended)" (user, 2026-10-13): a pulse played in an interior lets no petals or snow fall
## (systems/seasonal-art). "não faz muito sentido chover, ventar, etc. dentro de lugares fechados" (user, 2026-11-17):
## Chuva and Vendaval mount no effect indoors.

const PULSE := preload("res://scenes/world/memory/color_pulse/color_pulse.tscn")
const SONG := preload("res://resources/songs/freeze.tres")
const WEATHER_SONGS: Array[Song] = [preload("res://resources/songs/rain.tres"), preload("res://resources/songs/gale.tres")]


func _pulse_in(interior: bool, song: Song = SONG, with_effect: bool = false) -> ColorPulse:
	var room := Room.new()
	room.interior = interior
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(640, 384)
	shape.shape = rect
	shape.position = rect.size * 0.5
	room.add_child(shape)
	add_child(auto_free(room))
	var pulse := PULSE.instantiate() as ColorPulse
	add_child(auto_free(pulse))
	pulse.global_position = Vector2(320, 200)
	pulse.start(song, null, with_effect)
	return pulse

func _has_particles(pulse: ColorPulse) -> bool:
	for child: Node in pulse.get_children():
		if child is CPUParticles2D:
			return true
	return false

func test_a_pulse_outdoors_lets_its_season_fall() -> void:
	assert_object(SONG.palette.pulse_particles).is_not_null()
	assert_bool(_has_particles(_pulse_in(false))).is_true()

func test_a_pulse_indoors_lets_nothing_fall() -> void:
	assert_bool(_has_particles(_pulse_in(true))).is_false()

func _has_effect(pulse: ColorPulse) -> bool:
	for child: Node in pulse.get_children():
		if child is PulseEffect:
			return true
	return false

func test_rain_and_gale_blow_outdoors() -> void:
	for song: Song in WEATHER_SONGS:
		assert_bool(song.weather).is_true()
		assert_bool(_has_effect(_pulse_in(false, song, true))).override_failure_message(song.resource_path).is_true()

func test_rain_and_gale_do_nothing_under_a_roof() -> void:
	for song: Song in WEATHER_SONGS:
		assert_bool(_has_effect(_pulse_in(true, song, true))).override_failure_message(song.resource_path).is_false()

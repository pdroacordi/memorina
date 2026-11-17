class_name PulseCarryTest extends GdUnitTestSuite

## "se eu tocar a musica no lugar fechado, e sair para o lugar aberto (desde que dentro do raio de distancia de onde eu
## toquei), vai estar? seria legal se estivesse" (user, 2026-11-17): a weather pulse holding Ivo at the door opens outside.

const PULSE := preload("res://scenes/world/memory/color_pulse/color_pulse.tscn")
const RAIN := preload("res://resources/songs/rain.tres")
const FREEZE := preload("res://resources/songs/freeze.tres")
const INSIDE := Vector2(320, 200)
const OUTSIDE := Vector2(1320, 200)


func before_test() -> void:
	_room(Vector2.ZERO, true)
	_room(Vector2(1000, 0), false)

func _room(at: Vector2, interior: bool) -> void:
	var room := Room.new()
	room.interior = interior
	room.position = at
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(640, 384)
	shape.shape = rect
	shape.position = rect.size * 0.5
	room.add_child(shape)
	add_child(auto_free(room))

func _played(song: Song = RAIN, with_effect: bool = true) -> ColorPulse:
	var pulse := PULSE.instantiate() as ColorPulse
	add_child(auto_free(pulse))
	pulse.global_position = INSIDE
	pulse.start(song, null, with_effect)
	# Past the attack: the disc holds its full reach.
	pulse._physics_process(1.0)
	return pulse

func _has_effect(pulse: ColorPulse) -> bool:
	for child: Node in pulse.get_children():
		if child is PulseEffect:
			return true
	return false

func test_rain_played_inside_opens_outside_with_ivo() -> void:
	var inside := _played()
	assert_bool(_has_effect(inside)).is_false()
	var carries := PulseCarry.held_at(get_tree(), INSIDE + Vector2(40, 0))
	assert_int(carries.size()).is_equal(1)
	var outside := auto_free(carries[0].open_at(OUTSIDE)) as ColorPulse
	assert_object(outside).is_not_null()
	assert_vector(outside.global_position).is_equal(OUTSIDE)
	assert_bool(_has_effect(outside)).is_true()
	assert_float(outside.max_radius()).is_equal_approx(inside.max_radius() - 40.0, 0.01)
	assert_int(outside.phase()).is_equal(inside.phase())
	assert_bool(outside.acts()).is_true()

func test_nothing_goes_out_from_beyond_the_disc() -> void:
	var inside := _played()
	assert_array(PulseCarry.held_at(get_tree(), INSIDE + Vector2(inside.radius() + 8.0, 0))).is_empty()

func test_only_weather_goes_out() -> void:
	_played(FREEZE)
	assert_array(PulseCarry.held_at(get_tree(), INSIDE)).is_empty()

func test_a_pulse_that_does_not_act_stays_inside() -> void:
	_played(RAIN, false)
	assert_array(PulseCarry.held_at(get_tree(), INSIDE)).is_empty()

func test_a_pulse_that_ended_behind_the_cover_opens_nothing() -> void:
	var inside := _played()
	var carries := PulseCarry.held_at(get_tree(), INSIDE)
	inside.free()
	assert_object(carries[0].open_at(OUTSIDE)).is_null()

func test_the_reach_left_is_what_the_walk_did_not_spend() -> void:
	assert_float(PulseCarry.reach_left(160.0, 40.0)).is_equal(120.0)
	assert_float(PulseCarry.reach_left(160.0, 200.0)).is_equal(0.0)

func test_a_carried_timeline_keeps_its_moment_and_scales_its_reach() -> void:
	var stats := PulseStats.new()
	var timeline := PulseTimeline.new(stats, 1.0)
	timeline.advance(stats.attack_time + stats.sustain_time + stats.contract_time * 0.5)
	assert_bool(timeline.stretch(2.0, 2.0)).is_false()
	var copy := timeline.carried(80.0)
	assert_int(copy.phase).is_equal(PulseTimeline.Phase.CONTRACT)
	assert_float(copy.radius()).is_equal_approx(timeline.radius() * 0.5, 0.01)
	copy.advance(stats.contract_time)
	assert_bool(copy.is_finished()).is_true()

func test_a_stretch_taken_inside_is_not_taken_again_outside() -> void:
	var stats := PulseStats.new()
	var timeline := PulseTimeline.new(stats, 1.0)
	timeline.advance(stats.attack_time + 0.1)
	assert_bool(timeline.stretch(1.5, 1.5)).is_true()
	assert_bool(timeline.carried(100.0).stretch(1.5, 1.5)).is_false()

class_name FlightComponentTest extends GdUnitTestSuite

## A flyer steers toward its desired velocity plus the air's, with no gravity (architecture/one-air-channel).

const STEP := 1.0 / 60.0

var _stats: LocomotionStats


func before_test() -> void:
	_stats = LocomotionStats.new()
	_stats.acceleration = 600.0
	_stats.deceleration = 1200.0
	_stats.air_wind = 1.0

func test_it_accelerates_toward_the_steer() -> void:
	var velocity := FlightComponent.steered(Vector2.ZERO, Vector2(90, 0), Vector2.ZERO, _stats, STEP)
	assert_float(velocity.x).is_equal_approx(10.0, 0.001)
	for i: int in 60:
		velocity = FlightComponent.steered(velocity, Vector2(90, 0), Vector2.ZERO, _stats, STEP)
	assert_vector(velocity).is_equal_approx(Vector2(90, 0), Vector2(0.001, 0.001))

func test_it_steers_in_two_dimensions() -> void:
	var velocity := Vector2.ZERO
	for i: int in 60:
		velocity = FlightComponent.steered(velocity, Vector2(0, -80), Vector2.ZERO, _stats, STEP)
	assert_vector(velocity).is_equal_approx(Vector2(0, -80), Vector2(0.001, 0.001))

func test_no_gravity_without_steer_or_wind() -> void:
	var velocity := FlightComponent.steered(Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, _stats, STEP)
	assert_vector(velocity).is_equal(Vector2.ZERO)

func test_it_brakes_at_the_deceleration_when_not_steering() -> void:
	var velocity := FlightComponent.steered(Vector2(100, 0), Vector2.ZERO, Vector2.ZERO, _stats, STEP)
	assert_float(velocity.x).is_equal_approx(80.0, 0.001)

func test_wind_is_carried_on_top_of_the_steer() -> void:
	var velocity := Vector2.ZERO
	for i: int in 120:
		velocity = FlightComponent.steered(velocity, Vector2(60, 0), Vector2(0, 40), _stats, STEP)
	assert_vector(velocity).is_equal_approx(Vector2(60, 40), Vector2(0.001, 0.001))

func test_air_wind_scales_the_carry() -> void:
	_stats.air_wind = 0.5
	var velocity := Vector2.ZERO
	for i: int in 120:
		velocity = FlightComponent.steered(velocity, Vector2.ZERO, Vector2(80, 0), _stats, STEP)
	assert_vector(velocity).is_equal_approx(Vector2(40, 0), Vector2(0.001, 0.001))

func test_fly_update_writes_the_body_velocity() -> void:
	var body := auto_free(CharacterBody2D.new()) as CharacterBody2D
	var flight := FlightComponent.new()
	flight.stats = _stats
	body.add_child(flight)
	add_child(body)
	flight.fly_update(STEP, Vector2(90, 0), Vector2.ZERO)
	assert_float(body.velocity.x).is_equal_approx(10.0, 0.001)

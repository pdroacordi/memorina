class_name PlayerWindTest extends GdUnitTestSuite

## MEM-16: a standing Ivo leans into a wind he faces, and the wind never slides him off a ledge while he stands.

const IVO := preload("res://scenes/characters/ivo/ivo.tscn")

const FLOOR_Y := 300.0
## The test floor runs x 220..420.
const LIP_X := 420.0
## Px/s east: over the deadzone, so a standing Ivo slides.
const GALE := 300.0

var _ivo: Player
var _world: Node2D


func before_test() -> void:
	SaveSystem.begin("", true)

func after_test() -> void:
	SaveSystem.begin("", true)

func _build(x: float) -> Pusher:
	_world = auto_free(Node2D.new()) as Node2D
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 2
	floor_body.position = Vector2(320, FLOOR_Y + 10.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(200, 20)
	shape.shape = rect
	floor_body.add_child(shape)
	_world.add_child(floor_body)
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(x, FLOOR_Y - 40.0)
	_world.add_child(_ivo)
	var pusher := Pusher.new()
	pusher.body = _ivo
	_world.add_child(pusher)
	add_child(_world)
	return pusher

func _land() -> void:
	for i: int in 120:
		await get_tree().physics_frame
		if _ivo.is_on_floor():
			return
	fail("Ivo never landed on the test floor")

func test_the_wind_never_slides_a_standing_ivo_off_the_lip() -> void:
	var pusher := _build(390.0)
	await _land()
	pusher.wind = Vector2(GALE, 0.0)
	for i: int in 120:
		await get_tree().physics_frame
	assert_bool(_ivo.is_on_floor()).override_failure_message("slid off at x %.1f" % _ivo.global_position.x).is_true()
	assert_float(_ivo.global_position.x).is_greater(395.0)

## Braced facing the wind, he stops with the rear boot's heel on the stone, not just the capsule.
func test_a_braced_slide_stops_with_the_rear_boot_on_the_stone() -> void:
	var pusher := _build(360.0)
	await _land()
	_ivo.facing = -1
	pusher.wind = Vector2(GALE, 0.0)
	for i: int in 120:
		await get_tree().physics_frame
	assert_bool(pusher.bracing).is_true()
	assert_float(_ivo.global_position.x + Player.BRACE_HEEL).is_less_equal(LIP_X + 1.0)
	assert_float(_ivo.global_position.x + Player.BRACE_HEEL).is_greater(LIP_X - 4.0)

## bugs/a-gust-never-breaks-a-song-played-at-a-downwind-lip: parked at the lip by the wind, he is not still.
func test_a_slide_held_at_the_lip_is_not_still() -> void:
	var pusher := _build(390.0)
	await _land()
	pusher.wind = Vector2(GALE, 0.0)
	for i: int in 120:
		await get_tree().physics_frame
	assert_float(absf(_ivo.velocity.x)).is_less(Player.STILL_SPEED_EPSILON)
	assert_bool(pusher.still).is_false()

func test_standing_facing_the_wind_braces() -> void:
	var pusher := _build(260.0)
	await _land()
	pusher.wind = Vector2(GALE, 0.0)
	_ivo.facing = -1
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_bool(pusher.bracing).is_true()

func test_standing_with_the_back_to_the_wind_does_not_brace() -> void:
	var pusher := _build(260.0)
	await _land()
	pusher.wind = Vector2(GALE, 0.0)
	_ivo.facing = 1
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_bool(pusher.bracing).is_false()


class Pusher extends Node:
	var body: Player
	var wind := Vector2.ZERO
	## `is_bracing()` sampled after the push, while the frame's carry holds it.
	var bracing := false
	## `is_still()` sampled at the same point.
	var still := true

	func _ready() -> void:
		process_physics_priority = -5

	func _physics_process(_delta: float) -> void:
		body.push(wind)
		bracing = body.is_bracing()
		still = body.is_still()

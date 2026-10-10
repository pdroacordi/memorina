class_name GameCameraTest extends GdUnitTestSuite

## A glide between room bounds starts where the frame stood and ends on the new clamp; a plain bind jumps.

const ROOM_A := Rect2(0, 0, 1280, 384)
const ROOM_B := Rect2(1280, 0, 1280, 384)

var _camera: GameCamera
var _subject: Node2D


func before_test() -> void:
	_subject = auto_free(Node2D.new()) as Node2D
	add_child(_subject)
	_camera = auto_free(GameCamera.new()) as GameCamera
	_camera.bounds_glide_time = 0.2
	add_child(_camera)
	_camera.follow(_subject)

func _centre() -> Vector2:
	return _camera.global_position + _camera.offset

func _half_width() -> float:
	return _camera.get_viewport_rect().size.x * 0.5

func _cross_into_b(glide: bool) -> float:
	_subject.global_position = Vector2(1270, 300)
	_camera.set_bounds(ROOM_A)
	for i: int in 3:
		await get_tree().physics_frame
	var before := _centre().x
	_subject.global_position = Vector2(1290, 300)
	_camera.set_bounds(ROOM_B, glide)
	return before

func test_a_glide_starts_where_the_frame_stood() -> void:
	var before: float = await _cross_into_b(true)
	await get_tree().physics_frame
	assert_float(absf(_centre().x - before)).is_less(40.0)

func test_a_glide_ends_on_the_new_clamp() -> void:
	await _cross_into_b(true)
	for i: int in 30:
		await get_tree().physics_frame
	assert_float(_centre().x).is_equal_approx(ROOM_B.position.x + _half_width(), 0.5)

func test_without_a_glide_the_frame_jumps() -> void:
	await _cross_into_b(false)
	await get_tree().physics_frame
	assert_float(_centre().x).is_equal_approx(ROOM_B.position.x + _half_width(), 0.5)

## bugs/a-room-glide-while-a-pair-is-framed-jumps-by-the-pair-offset: the pair midpoint lies inside room B's clamp.
func test_a_glide_while_a_pair_is_framed_starts_where_the_frame_stood() -> void:
	var other := auto_free(Node2D.new()) as Node2D
	other.global_position = Vector2(2200, 300)
	add_child(other)
	_camera.pair_duration = 0.05
	_camera.frame_pair(other)
	for i: int in 10:
		await get_tree().physics_frame
	var before: float = await _cross_into_b(true)
	await get_tree().physics_frame
	assert_float(absf(_centre().x - before)).is_less(40.0)

func test_snap_ends_a_glide() -> void:
	await _cross_into_b(true)
	_camera.snap()
	await get_tree().physics_frame
	assert_float(_centre().x).is_equal_approx(ROOM_B.position.x + _half_width(), 0.5)

## bugs/a-hop-below-a-seam-flips-the-room-twice: astride a room's top edge the body stays in frame.
func test_the_clamp_yields_to_keep_the_body_in_frame() -> void:
	var body := auto_free(BodySubject.new()) as BodySubject
	body.global_position = Vector2(600, 20)
	add_child(body)
	_camera.follow(body)
	_camera.set_bounds(ROOM_A)
	await get_tree().physics_frame
	var view := _camera.view_rect()
	assert_float(view.position.y).is_less_equal(body.body_rect().position.y - _camera.subject_margin + 0.5)

## A subject with a body, as Character has: 16x48 px standing on its position.
class BodySubject extends Node2D:
	func body_rect() -> Rect2:
		return Rect2(global_position + Vector2(-8.0, -48.0), Vector2(16.0, 48.0))

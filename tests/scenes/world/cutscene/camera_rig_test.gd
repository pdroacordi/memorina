class_name CameraRigTest extends GdUnitTestSuite

## A cutscene's rig takes the frame where it stands and hands it back to Ivo's framed centre: neither move shifts the
## frame by a pixel. A zoom on the rig lets a one-screen room pan.

const ROOM := Rect2(0, 0, 640, 384)

var _camera: GameCamera
var _subject: Node2D
var _rig: CameraRig


func before_test() -> void:
	_subject = auto_free(Node2D.new()) as Node2D
	_subject.global_position = Vector2(300, 300)
	add_child(_subject)
	_camera = auto_free(GameCamera.new()) as GameCamera
	add_child(_camera)
	_camera.set_bounds(Rect2(-2000, -2000, 4000, 4000))
	_camera.follow(_subject)
	_rig = auto_free(CameraRig.new()) as CameraRig
	add_child(_rig)

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

func test_the_rig_takes_the_frame_without_a_jump() -> void:
	await _frames(30)
	var shown := _camera.shown_centre()
	_rig.move_to(_camera.rig_point_for(shown), 0.0)
	_camera.follow(_rig)
	await _frames(2)
	assert_float(_camera.shown_centre().distance_to(shown)).is_less(1.0)

func test_the_frame_returns_to_its_subject_without_a_jump() -> void:
	await _frames(30)
	_rig.move_to(_camera.rig_point_for(_camera.shown_centre()), 0.0)
	_camera.follow(_rig)
	await _frames(2)
	_rig.move_to(_camera.rig_point_for(_camera.centre_for(_subject)), 0.0)
	await _frames(2)
	var shown := _camera.shown_centre()
	_camera.follow(_subject)
	await _frames(2)
	assert_float(_camera.shown_centre().distance_to(shown)).is_less(1.0)

func test_zoom_two_lets_a_one_screen_room_pan() -> void:
	_camera.set_bounds(ROOM)
	_rig.move_to(_camera.rig_point_for(Vector2(60, 250)), 0.0)
	_camera.follow(_rig)
	await _frames(2)
	var at_one := _camera.shown_centre().x
	_camera.zoom_to(2.0, 0.0)
	await _frames(2)
	assert_float(at_one).is_equal_approx(320.0, 0.5)
	assert_float(_camera.shown_centre().x).is_equal_approx(160.0, 0.5)

func test_a_rig_move_runs_on_the_physics_clock() -> void:
	_rig.move_to(Vector2(400, 0), 0.5)
	assert_bool(_rig.is_moving()).is_true()
	await await_millis(700)
	assert_bool(_rig.is_moving()).is_false()
	assert_vector(_rig.global_position).is_equal_approx(Vector2(400, 0), Vector2(0.5, 0.5))

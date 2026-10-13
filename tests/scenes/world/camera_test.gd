class_name GameCameraTest extends GdUnitTestSuite

## A glide between room bounds starts where the frame stood and ends on the new clamp; a plain bind jumps.

const ROOM_A := Rect2(0, 0, 1280, 384)
const ROOM_B := Rect2(1280, 0, 1280, 384)
const ROOM_BELOW := Rect2(0, 384, 1280, 384)
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")

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

## bugs/a-stale-glide-timer-idles-the-left-rooms-neighbours-mid-glide: crossing A, B, A, B within one glide time
## retargets the glide, so glide_finished fires once, when the last glide ends, never mid-glide.
func test_a_retargeted_glide_finishes_once_at_its_end() -> void:
	var finished: Array[int] = []
	_camera.glide_finished.connect(func() -> void: finished.append(Engine.get_physics_frames()))
	await _cross_into_b(true)
	var started := Engine.get_physics_frames()
	for target: Rect2 in [ROOM_A, ROOM_B]:
		for i: int in 3:
			await get_tree().physics_frame
		_subject.global_position = Vector2(1270 if target == ROOM_A else 1290, 300)
		_camera.set_bounds(target, true)
		started = Engine.get_physics_frames()
	var ticks := ceili(_camera.bounds_glide_time * Engine.physics_ticks_per_second)
	for i: int in ticks - 2:
		await get_tree().physics_frame
	assert_array(finished).is_empty()
	for i: int in 6:
		await get_tree().physics_frame
	assert_int(finished.size()).is_equal(1)
	assert_int(finished[0] - started).is_greater_equal(ticks - 1)

func test_snap_mid_glide_finishes_it() -> void:
	var finished := [0]
	_camera.glide_finished.connect(func() -> void: finished[0] += 1)
	await _cross_into_b(true)
	await get_tree().physics_frame
	_camera.snap()
	assert_int(finished[0]).is_equal(1)
	_camera.snap()
	assert_int(finished[0]).is_equal(1)

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
	# A room above room A: the frame may yield up into it.
	_camera.set_bounds(ROOM_A)
	_camera.set_reach(ROOM_A.merge(Rect2(0, -384, 1280, 384)))
	await _two_steps()
	var view := _camera.view_rect()
	assert_float(view.position.y).is_less_equal(body.body_rect().position.y - _camera.subject_margin + 0.5)

## bugs/the-out-of-room-safety-net-fires-on-a-double-jump-above-an-open-room-top: with no room above, no void shows.
func test_the_frame_never_yields_past_the_rooms() -> void:
	var body := auto_free(BodySubject.new()) as BodySubject
	body.global_position = Vector2(600, 20)
	add_child(body)
	_camera.follow(body)
	_camera.set_bounds(ROOM_A)
	await _two_steps()
	assert_float(_camera.view_rect().position.y).is_greater_equal(ROOM_A.position.y - 0.5)

## bugs/the-woods-pond-shelf-jump-takes-ivo-out-of-the-top-of-the-frame: a full jump's apex over an open top, the frame
## rises into the room's ring to keep him whole.
func test_over_an_open_top_the_frame_yields_into_the_ring() -> void:
	var body := _body_at(Vector2(600, -80))
	_camera.set_bounds(ROOM_A)
	_camera.set_reach(RoomRing.reach(ROOM_A))
	await _two_steps()
	assert_float(_camera.view_rect().position.y).is_less_equal(body.body_rect().position.y - _camera.subject_margin + 0.5)

## bugs/a-hop-above-a-neighbours-open-top-drops-it-from-the-camera-reach: a jump on the seam wall top, over room A's
## columns while room B is current, keeps him whole sideways at any height inside the ring.
func test_a_jump_over_a_neighbours_columns_stays_in_frame() -> void:
	for feet: float in [-16.0, -90.0]:
		var body := _body_at(Vector2(1270, feet))
		_camera.set_bounds(ROOM_B)
		_camera.set_reach(RoomRing.reach(ROOM_B))
		await _two_steps()
		var view := _camera.view_rect()
		assert_float(view.position.x).is_less_equal(body.body_rect().position.x - _camera.subject_margin + 0.5)
		assert_float(view.position.y).is_less_equal(body.body_rect().position.y - _camera.subject_margin + 0.5)

## bugs/a-region-cut-frames-one-step-without-the-open-sky: set_bounds drops the reach to the room, so Game sets the new
## room's reach after the swap; with it, the cut frame keeps his head in the ring.
func test_a_region_cut_keeps_the_ring_when_the_reach_follows_the_swap() -> void:
	var body := _body_at(Vector2(1300, 27))
	_camera.set_bounds(ROOM_A)
	await _two_steps()
	_camera.set_bounds(ROOM_B)
	_camera.set_reach(RoomRing.reach(ROOM_B))
	_camera.snap(true)
	await _two_steps()
	assert_float(_camera.view_rect().position.y).is_less_equal(body.body_rect().position.y - _camera.subject_margin + 0.5)

func test_set_bounds_drops_the_reach_to_the_room() -> void:
	_body_at(Vector2(1300, 27))
	_camera.set_reach(RoomRing.reach(ROOM_B))
	_camera.set_bounds(ROOM_B)
	await _two_steps()
	assert_float(_camera.view_rect().position.y).is_equal_approx(ROOM_B.position.y, 0.5)

## A double jump's apex is past the ring: the frame stops at its edge, never in the void.
func test_the_frame_never_yields_past_the_ring() -> void:
	_body_at(Vector2(600, -400))
	_camera.set_bounds(ROOM_A)
	_camera.set_reach(RoomRing.reach(ROOM_A))
	await _two_steps()
	assert_float(_camera.view_rect().position.y).is_equal_approx(ROOM_A.position.y - RoomRing.WIDTH, 0.5)

## Falling at full speed toward a room below, the frame yields into it to show the ground under the feet.
func test_a_fall_keeps_the_ground_below_in_frame() -> void:
	var body := _falling_body(1.0)
	_camera.set_reach(ROOM_A, ROOM_A.merge(ROOM_BELOW))
	await _lead_grown()
	var feet := body.body_rect().end.y
	assert_float(_camera.view_rect().end.y).is_greater_equal(feet + _camera.subject_margin + _camera.fall_view - 0.5)

## A landing eases the frame back instead of jumping it up.
func test_the_fall_view_eases_back_after_a_landing() -> void:
	var body := _falling_body(1.0)
	_camera.set_reach(ROOM_A, ROOM_A.merge(ROOM_BELOW))
	await _lead_grown()
	var falling_end := _camera.view_rect().end.y
	body.air = 0.0
	await get_tree().physics_frame
	assert_float(_camera.view_rect().end.y).is_greater(falling_end - 40.0)
	for i: int in 90:
		await get_tree().physics_frame
	assert_float(_camera.view_rect().end.y).is_equal_approx(ROOM_A.end.y, 0.5)

## bugs/the-fall-lead-dips-the-frame-below-a-solid-floor-on-a-hard-landing: the lead stops at the coming ground.
func test_the_fall_view_stops_at_the_ground_below() -> void:
	var floor_body := auto_free(StaticBody2D.new()) as StaticBody2D
	floor_body.collision_layer = GroundCollision.COLLISION_LAYER
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(1280, 32)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(640, 356)
	add_child(floor_body)
	_falling_body(1.0)
	_camera.set_reach(ROOM_A, ROOM_A.merge(ROOM_BELOW))
	await _lead_grown()
	await _two_steps()
	assert_float(_camera.fall_lead()).is_equal_approx(10.0 + GameCamera.LANDING_GROUND, 0.5)
	assert_float(_camera.view_rect().end.y).is_equal_approx(ROOM_A.end.y, 0.5)

## bugs/the-fall-lead-jumps-the-frame-into-a-room-the-body-already-touches-below: the body's reach is not the lead's.
func test_the_fall_view_yields_only_into_the_fall_reach() -> void:
	_falling_body(1.0)
	_camera.set_reach(ROOM_A.merge(ROOM_BELOW), ROOM_A)
	await _lead_grown()
	assert_float(_camera.view_rect().end.y).is_less_equal(ROOM_A.end.y + 0.5)

## bugs/the-fall-lead-jumps-the-frame-when-a-glide-swaps-into-a-narrow-room: a reach that opens below moves the frame
## no faster than `fall_lead_follow`.
func test_the_lead_moves_the_frame_no_faster_than_it_follows() -> void:
	_falling_body(1.0)
	_camera.set_reach(ROOM_A, ROOM_A)
	await _lead_grown()
	var step := _camera.fall_lead_follow / Engine.physics_ticks_per_second
	var before := _camera.view_rect().end.y
	_camera.set_reach(ROOM_A, ROOM_A.merge(ROOM_BELOW))
	await get_tree().physics_frame
	assert_float(_camera.view_rect().end.y - before).is_less_equal(step + 0.5)
	await _lead_grown()
	assert_float(_camera.view_rect().end.y - before).is_greater(step)

## With no room below, the fall view shows no void.
func test_the_fall_view_never_yields_past_the_rooms() -> void:
	_falling_body(1.0)
	await _lead_grown()
	assert_float(_camera.view_rect().end.y).is_less_equal(ROOM_A.end.y + 0.5)

## A walk-off eases the frame down: no step grows the lead by more than `fall_lead_rise` allows.
func test_the_lead_grows_no_faster_than_its_rise() -> void:
	_falling_body(1.0)
	_camera.set_reach(ROOM_A, ROOM_A.merge(ROOM_BELOW))
	await _two_steps()
	var step := _camera.fall_lead_rise / Engine.physics_ticks_per_second
	assert_float(_camera.fall_lead()).is_less_equal(2.0 * step + 0.5)

## bugs/the-frame-stalls-at-the-floor-seam-before-the-fall-lead-takes-over: the lead never shows less than the follow.
func test_the_lead_is_never_shorter_than_the_follow() -> void:
	_camera.framing_offset_y = 100.0
	_camera.offset.y = 100.0
	var body := _falling_body(1.0)
	_camera.set_reach(ROOM_A, ROOM_A.merge(ROOM_BELOW))
	for i: int in 30:
		await get_tree().physics_frame
	var follow := 100.0 + _camera.get_viewport_rect().size.y * 0.5 - _camera.subject_margin
	assert_float(_camera.fall_lead()).is_greater(_camera.fall_view)
	assert_float(_camera.fall_lead()).is_equal_approx(follow, 1.0)
	assert_object(body).is_not_null()

## Descending past a ledge's edge: ground under one side only does not cap the lead.
func test_a_descent_past_an_edge_keeps_its_lead() -> void:
	_floor(Vector2(560, 340), 36.0)
	_falling_body(1.0)
	_camera.set_reach(ROOM_A, ROOM_A.merge(ROOM_BELOW))
	await _lead_grown()
	assert_float(_camera.fall_lead()).is_equal_approx(_camera.fall_view, 0.5)

## Standing at an edge after a landing: the nearer ground caps the lead, so the frame does not dip.
func test_a_stance_at_an_edge_does_not_dip() -> void:
	_floor(Vector2(560, 330), 36.0)
	var body := _falling_body(1.0)
	_camera.set_reach(ROOM_A, ROOM_A.merge(ROOM_BELOW))
	await _lead_grown()
	body.air = 0.0
	await _two_steps()
	assert_float(_camera.fall_lead()).is_less_equal(GameCamera.LANDING_GROUND + 0.5)

## A region cut mid-fall keeps the lead.
func test_a_snap_that_keeps_the_fall_lead_keeps_it() -> void:
	_falling_body(1.0)
	_camera.set_reach(ROOM_A, ROOM_A.merge(ROOM_BELOW))
	await _lead_grown()
	var lead := _camera.fall_lead()
	_camera.snap(true)
	assert_float(_camera.fall_lead()).is_equal(lead)
	_camera.snap()
	assert_float(_camera.fall_lead()).is_equal(0.0)

## The steady frame leaves the shake out.
func test_the_steady_frame_leaves_the_shake_out() -> void:
	_falling_body(0.0)
	await _two_steps()
	var steady := _camera.view_rect()
	_camera.shake(6.0)
	await get_tree().physics_frame
	assert_vector(_camera.steady_view_rect().position).is_equal_approx(steady.position, Vector2(0.5, 0.5))

## bugs/a-facing-turn-in-a-one-screen-wide-room-slides-the-frame-past-its-bounds: a turn's look-ahead never shows past
## a room one screen wide, read after every tween step.
func test_a_turn_in_a_room_one_screen_wide_keeps_the_frame_inside() -> void:
	var ivo := IVO.instantiate() as Player
	ivo.position = Vector2(_half_width(), 330.0)
	add_child(ivo)
	auto_free(ivo)
	_floor(Vector2(0.0, 330.0), _half_width() * 2.0)
	var room := Rect2(0.0, 0.0, _half_width() * 2.0, 384.0)
	# The reach Game sets: the ring around the room (bugs/a-facing-turn-in-a-one-screen-wide-room-slides-the-frame-past-its-bounds).
	_camera.set_bounds(room, false, RoomRing.reach(room))
	_camera.follow(ivo)
	_camera.snap()
	await _two_steps()
	for facing: float in [-1.0, 1.0]:
		ivo.face_towards(facing)
		for i: int in ceili(_camera.look_ahead_duration * Engine.physics_ticks_per_second) + 4:
			await get_tree().physics_frame
			var view := _camera.view_rect()
			assert_float(view.position.x).is_greater_equal(room.position.x - 0.01)
			assert_float(view.end.x).is_less_equal(room.end.x + 0.01)
	assert_float(_camera.offset.x).is_equal_approx(_camera.look_ahead_distance, 0.01)

func _falling_body(air: float) -> FallingSubject:
	var body := auto_free(FallingSubject.new()) as FallingSubject
	body.air = air
	body.global_position = Vector2(600, 330)
	add_child(body)
	_camera.follow(body)
	_camera.set_bounds(ROOM_A)
	return body

## A BodySubject at `feet` the camera follows.
func _body_at(feet: Vector2) -> BodySubject:
	var body := auto_free(BodySubject.new()) as BodySubject
	body.global_position = feet
	add_child(body)
	_camera.follow(body)
	return body

## A world-layer floor whose top-left corner is `top_left`, `width` px wide.
func _floor(top_left: Vector2, width: float) -> void:
	var floor_body := auto_free(StaticBody2D.new()) as StaticBody2D
	floor_body.collision_layer = GroundCollision.COLLISION_LAYER
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, 32.0)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = top_left + rect.size * 0.5
	add_child(floor_body)

## The lead grows at `fall_lead_rise`: enough steps for the whole `fall_view`.
func _lead_grown() -> void:
	for i: int in ceili(_camera.fall_view / _camera.fall_lead_rise * Engine.physics_ticks_per_second) + 2:
		await get_tree().physics_frame

## physics_frame is emitted before the step's nodes process: the second await is after the camera's first step.
func _two_steps() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame

## A subject with a body, as Character has: 16x48 px standing on its position.
class BodySubject extends Node2D:
	func body_rect() -> Rect2:
		return Rect2(global_position + Vector2(-8.0, -48.0), Vector2(16.0, 48.0))

## A body with camera intent, as Player has: `air` is its air_axis().
class FallingSubject extends BodySubject:
	var air := 0.0

	func air_axis() -> float:
		return air

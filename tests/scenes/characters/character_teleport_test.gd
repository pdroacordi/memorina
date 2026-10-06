class_name CharacterTeleportTest extends GdUnitTestSuite

## Pins the engine behaviour behind Character.teleport (docs/knowledge/gotchas/a-teleported-kinematic-body-overlaps-from-its-old-place-for-one-step.md):
## a kinematic body moved by a position write is still at its old place for one step; teleport_body moves the server too.

const AREA_SIZE := Vector2(200, 200)
const AWAY := Vector2(1000, 0)

var _holder: Node2D
var _area: Area2D
var _events: Array[String] = []


func before_test() -> void:
	_events.clear()
	_holder = auto_free(Node2D.new()) as Node2D
	add_child(_holder)
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = 1
	_area.add_child(_shape(RectangleShape2D.new(), AREA_SIZE))
	_holder.add_child(_area)
	_area.body_entered.connect(func(_body: Node2D) -> void: _events.append("enter"))
	_area.body_exited.connect(func(_body: Node2D) -> void: _events.append("exit"))

## The control: if this starts failing, the engine no longer lags and teleport_body can go.
func test_a_plain_position_write_still_overlaps_from_the_old_place() -> void:
	var body := await _body_entered_inside_then_disabled()
	body.global_position = AWAY
	body.process_mode = Node.PROCESS_MODE_INHERIT
	await _steps(4)
	assert_array(_events).contains_exactly(["enter", "exit"])

## Arrival: added at the authored start inside the area, disabled, seated far away, re-enabled.
func test_teleport_body_leaves_no_stale_overlap() -> void:
	var body := await _body_entered_inside_then_disabled()
	Character.teleport_body(body, AWAY)
	var server: Transform2D = PhysicsServer2D.body_get_state(body.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM)
	assert_object(server.origin).is_equal(AWAY)
	body.process_mode = Node.PROCESS_MODE_INHERIT
	await _steps(4)
	assert_array(_events).is_empty()

## After a teleport the body is still an ordinary kinematic body: it lands, and a walk into the area is a real entry.
func test_after_a_teleport_the_body_lands_and_enters_by_walking() -> void:
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 2
	floor_body.position = Vector2(500, 120)
	floor_body.add_child(_shape(RectangleShape2D.new(), Vector2(4000, 20)))
	_holder.add_child(floor_body)
	var body := await _body_entered_inside_then_disabled()
	Character.teleport_body(body, AWAY)
	body.process_mode = Node.PROCESS_MODE_INHERIT
	var landed := false
	for i: int in 240:
		body.velocity.y += 20.0
		if body.is_on_floor():
			landed = true
			body.velocity.x = -600.0
		body.move_and_slide()
		await get_tree().physics_frame
		if _events.has("enter"):
			break
	assert_bool(landed).is_true()
	assert_array(_events).contains_exactly(["enter"])

func _body_entered_inside_then_disabled() -> CharacterBody2D:
	var body := CharacterBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 2
	var capsule := CapsuleShape2D.new()
	capsule.radius = 11
	capsule.height = 54
	var shape := CollisionShape2D.new()
	shape.shape = capsule
	body.add_child(shape)
	_holder.add_child(body)
	# Out of the space before any step, as Game._arrive does with Ivo.
	body.process_mode = Node.PROCESS_MODE_DISABLED
	await _steps(2)
	return body

func _shape(shape: Shape2D, size: Vector2) -> CollisionShape2D:
	(shape as RectangleShape2D).size = size
	var node := CollisionShape2D.new()
	node.shape = shape
	return node

func _steps(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

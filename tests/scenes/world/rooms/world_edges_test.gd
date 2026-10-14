class_name WorldEdgesTest extends GdUnitTestSuite

## A real Ivo against the walls WorldEdges builds from two touching rooms: the ceiling over an open top, a void side, a
## seam, no grip on an edge wall, and no way onto a closed first-row run (systems/rooms "Edges").

const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
## Px: the floor's top, in the rooms' last row.
const FLOOR_Y := 352.0
## Px/s up: more than a double jump, so only the ceiling stops the rise.
const LAUNCH := 1400.0

var _holder: Node2D
var _ivo: Player
var _edges: WorldEdges


func before_test() -> void:
	SaveSystem.begin("", true)
	_holder = auto_free(Node2D.new()) as Node2D
	add_child(_holder)
	# Columns 0-9 of the west room's first row are stone, 10-19 open; the east room's first row is all stone.
	var west := _room(Vector2.ZERO, "SSSSSSSSSS..........")
	var east := _room(Vector2(640, 0), "SSSSSSSSSSSSSSSSSSSS")
	_add_block(Rect2(0, FLOOR_Y, 1280, 32))
	_edges = WorldEdges.new()
	_holder.add_child(_edges)
	_edges.build([west, east] as Array[Room])
	_ivo = IVO.instantiate() as Player
	_holder.add_child(_ivo)

func after_test() -> void:
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	SaveSystem.begin("", true)

func test_the_walls_lie_on_the_edges_layer_only_ivo_masks() -> void:
	assert_int(_edges.collision_layer).is_equal(WorldEdges.LAYER)
	assert_int(_edges.collision_mask).is_equal(0)
	assert_int(_ivo.collision_mask & WorldEdges.LAYER).is_equal(WorldEdges.LAYER)
	assert_int(_edges.get_child_count()).is_greater(0)

func test_a_rise_over_an_open_top_stops_at_the_ceiling() -> void:
	_ivo.teleport(Vector2(480, 20))
	_ivo.velocity = Vector2(0, -LAUNCH)
	var highest := INF
	for i: int in 40:
		await get_tree().physics_frame
		highest = minf(highest, _ivo.body_rect().position.y)
	assert_float(highest).is_greater_equal(-RoomEdges.CEILING_RISE - 1.0)
	assert_float(highest).is_less(-RoomEdges.CEILING_RISE + 8.0)
	assert_float(_ivo.velocity.y).is_greater(0.0)

func test_a_walk_into_a_void_side_stops_at_the_bounds() -> void:
	await _land_at(100.0)
	Input.action_press(&"move_left")
	await _frames(60)
	assert_float(_ivo.body_rect().position.x).is_greater_equal(-0.5)

func test_a_walk_across_the_seam_is_not_stopped() -> void:
	await _land_at(560.0)
	Input.action_press(&"move_right")
	await _frames(60)
	assert_float(_ivo.global_position.x).is_greater(720.0)

func test_an_edge_wall_never_starts_a_wall_slide() -> void:
	SaveSystem.unlock_skill(Enums.PlayerSkill.WALL_CLIMB)
	_ivo.teleport(Vector2(16, 200))
	Input.action_press(&"move_left")
	var slid := false
	for i: int in 20:
		await get_tree().physics_frame
		slid = slid or _ivo.is_wall_sliding()
	assert_bool(slid).is_false()

## The control for the test above: the same push into a real wall slides.
func test_a_real_wall_starts_a_wall_slide() -> void:
	SaveSystem.unlock_skill(Enums.PlayerSkill.WALL_CLIMB)
	_add_block(Rect2(0, 100, 64, 252))
	_ivo.teleport(Vector2(80, 200))
	Input.action_press(&"move_left")
	var slid := false
	for i: int in 30:
		await get_tree().physics_frame
		slid = slid or _ivo.is_wall_sliding()
	assert_bool(slid).is_true()

## Over the open run at column 10, pushing west into the closed run: his feet never rise over column 9.
func test_a_closed_first_row_run_is_never_stood_on() -> void:
	_ivo.teleport(Vector2(340, 20))
	_ivo.velocity = Vector2(0, -LAUNCH)
	Input.action_press(&"move_left")
	for i: int in 60:
		await get_tree().physics_frame
		var body := _ivo.body_rect()
		assert_bool(body.position.x < 319.5 and body.end.y < 0.5).override_failure_message("over the closed run at %s" % body).is_false()

# A Room at `at`, 640x384, whose map's first row is `top` (stone or air) over air.
func _room(at: Vector2, top: String) -> Room:
	var rows := PackedStringArray([top])
	for y: int in 11:
		rows.append(".".repeat(20))
	var map := ReachFixture.map(rows)
	var contents := RoomMapNode.new()
	contents.map = map
	var packed := PackedScene.new()
	packed.pack(contents)
	contents.free()
	var room := Room.new()
	room.contents_scene = packed
	room.position = at + Vector2(320, 192)
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(640, 384)
	shape.shape = rect
	room.add_child(shape)
	_holder.add_child(room)
	return room

func _add_block(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.add_child(shape)
	_holder.add_child(body)

func _land_at(x: float) -> void:
	_ivo.teleport(Vector2(x, FLOOR_Y - 2.0))
	await _frames(10)
	assert_bool(_ivo.is_on_floor()).is_true()

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

class_name ClimbComponentTest extends GdUnitTestSuite

## Climbing out of the top of a root pole or shaft (bugs/the-climbs-over-the-top-hop-never-fires).

const IVO_SCENE := "res://scenes/characters/ivo/ivo.tscn"
## A root pillar's geometry; the rig's sensor is read from ivo.tscn, so a change to it is tested as built.
const POLE_TOP := 128.0
const POLE_HEIGHT := 160.0

func test_hands_that_came_off_above_the_top_came_off_over_it() -> void:
	assert_bool(ClimbComponent.cleared_top(POLE_TOP - 1.0, POLE_TOP)).is_true()
	assert_bool(ClimbComponent.cleared_top(POLE_TOP, POLE_TOP)).is_true()

func test_hands_that_came_off_below_the_top_came_off_its_side() -> void:
	assert_bool(ClimbComponent.cleared_top(POLE_TOP + 1.0, POLE_TOP)).is_false()

func test_a_climbable_with_nothing_left_has_no_top_to_clear() -> void:
	assert_bool(ClimbComponent.cleared_top(POLE_TOP - 50.0, INF)).is_false()

func test_letting_go_partway_up_is_not_over_the_top() -> void:
	var rig := await _rig(POLE_TOP + 60.0)
	rig.climb.grab()
	# Off the pole's side: the body moves sideways past it, below its top.
	rig.body.global_position.x += 40.0
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_int(rig.climb.update(1.0 / 60.0, Vector2(0.0, -1.0))).is_equal(ClimbComponent.Exit.LET_GO)

func test_ivos_top_hop_lifts_his_feet_over_a_one_way_cell_on_the_climbable() -> void:
	var ivo := (load(IVO_SCENE) as PackedScene).instantiate()
	var hop: float = (ivo.get_node("Climb") as ClimbComponent).top_hop_height
	var sensor := ivo.get_node("ClimbSensor/CollisionShape2D") as CollisionShape2D
	# Feet below the sensor's bottom: where the feet are when the sensor leaves the climbable's top.
	var feet_below_sensor := -(sensor.position.y + (sensor.shape as RectangleShape2D).size.y * 0.5)
	ivo.free()
	var peak := 0.0
	for height: float in MapGuide.ivo_reach().heights(hop):
		peak = maxf(peak, height)
	# The knot's top is one cell over the pole's top; a landing needs the feet above it, with a few px to spare.
	assert_float(peak - feet_below_sensor).is_greater_equal(float(RoomMap.CELL_PX) + 4.0)

func test_climbing_up_out_of_a_pole_leaves_over_the_top() -> void:
	var rig := await _rig(POLE_TOP + 20.0)
	assert_bool(rig.climb.can_grab()).is_true()
	rig.climb.grab()
	# Up held: the body rises until the sensor no longer overlaps the pole.
	var exit := ClimbComponent.Exit.HOLDING
	for i: int in 120:
		exit = rig.climb.update(1.0 / 60.0, Vector2(0.0, -1.0))
		if exit != ClimbComponent.Exit.HOLDING:
			break
		rig.body.global_position.y += rig.body.velocity.y / 60.0
		await get_tree().physics_frame
	assert_int(exit).is_equal(ClimbComponent.Exit.OVER_THE_TOP)

func _rig(feet_y: float) -> Dictionary:
	var pole := Climbable.new()
	pole.grip = Climbable.Grip.POLE
	var pole_shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(8.0, POLE_HEIGHT)
	pole_shape.shape = box
	pole_shape.position = Vector2(0.0, POLE_TOP + POLE_HEIGHT * 0.5)
	pole.add_child(pole_shape)
	add_child(auto_free(pole))

	var body := CharacterBody2D.new()
	body.collision_layer = 0
	body.collision_mask = 0
	var sensor := Area2D.new()
	sensor.name = "ClimbSensor"
	sensor.collision_layer = 0
	sensor.collision_mask = Climbable.LAYER
	sensor.monitorable = false
	sensor.add_child(_ivo_sensor_shape())
	body.add_child(sensor)
	var climb := ClimbComponent.new()
	climb.name = "Climb"
	body.add_child(climb)
	body.position = Vector2(0.0, feet_y)
	add_child(auto_free(body))
	await get_tree().physics_frame
	await get_tree().physics_frame
	return {"body": body, "climb": climb}

## A copy of Ivo's own climb sensor shape (its box and offset).
func _ivo_sensor_shape() -> CollisionShape2D:
	var ivo := (load(IVO_SCENE) as PackedScene).instantiate()
	var shape := (ivo.get_node("ClimbSensor/CollisionShape2D") as CollisionShape2D).duplicate() as CollisionShape2D
	ivo.free()
	return shape

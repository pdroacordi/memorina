class_name SoftLandingTest extends GdUnitTestSuite

## A SoftLanding zone stands on its cell's floor, sized in cells, and tells the body it holds (systems/rooms).

const SCENE := preload("res://scenes/world/environment/soft_landing/soft_landing.tscn")


class Body:
	extends Node2D
	var zones := 0

	func enter_soft_landing() -> void:
		zones += 1

	func exit_soft_landing() -> void:
		zones -= 1


func test_the_zone_rises_from_its_floor_sized_in_cells() -> void:
	var zone: SoftLanding = SCENE.instantiate()
	zone.width_cells = 6
	zone.height_cells = 5
	add_child(zone)
	var shape := zone.get_node("CollisionShape2D") as CollisionShape2D
	assert_vector((shape.shape as RectangleShape2D).size).is_equal(Vector2(192, 160))
	assert_vector(shape.position).is_equal(Vector2(0, -80))
	zone.free()

func test_it_tells_the_body_it_holds() -> void:
	var zone: SoftLanding = auto_free(SCENE.instantiate())
	var body: Body = auto_free(Body.new())
	zone.body_entered.emit(body)
	assert_int(body.zones).is_equal(0)
	add_child(zone)
	zone.body_entered.emit(body)
	assert_int(body.zones).is_equal(1)
	zone.body_exited.emit(body)
	assert_int(body.zones).is_equal(0)
	remove_child(zone)

func test_it_listens_only_to_the_player_body() -> void:
	var zone: SoftLanding = auto_free(SCENE.instantiate())
	assert_int(zone.collision_layer).is_equal(0)
	assert_int(zone.collision_mask).is_equal(256)

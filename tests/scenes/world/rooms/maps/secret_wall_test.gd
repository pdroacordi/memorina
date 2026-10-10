class_name SecretWallTest extends GdUnitTestSuite

## A closed wall opens for Ivo's body, fades out, hides and records its id; a found id starts open (architecture/secret-false-walls).

const ID := &"test@1,2"


func before_test() -> void:
	SaveSystem.begin("", true)

func after_test() -> void:
	SaveSystem.begin("", true)

func _wall() -> SecretWall:
	var wall := SecretWall.new()
	var front: Array[CanvasItem] = []
	var layer := Node2D.new()
	wall.add_child(layer)
	front.append(layer)
	var rects: Array[Rect2] = [Rect2(0, 0, 64, 32)]
	wall.setup(ID, front, rects)
	add_child(wall)
	auto_free(wall)
	return wall

func test_the_front_copy_draws_only_in_the_foreground_pass() -> void:
	var wall := _wall()
	assert_int(wall.get_child(0).visibility_layer).is_equal(CanvasPass.FOREGROUND)

func test_ivos_body_opens_it_for_good() -> void:
	var wall := _wall()
	var found: Array[StringName] = []
	wall.found.connect(func(id: StringName) -> void: found.append(id))
	var trigger := wall.get_node("Trigger") as Area2D
	assert_int(trigger.collision_mask).is_equal(SecretWall.PLAYER_BODY_MASK)
	trigger.body_entered.emit(auto_free(Node2D.new()))
	assert_bool(SaveSystem.is_secret_found(ID)).is_true()
	assert_array(found).contains_exactly([ID])
	await get_tree().create_timer(SecretWall.FADE_TIME + 0.2).timeout
	assert_float(wall.modulate.a).is_equal_approx(0.0, 0.01)
	assert_bool(wall.visible).is_false()

func test_a_found_secret_starts_open() -> void:
	SaveSystem.find_secret(ID)
	var wall := _wall()
	assert_bool(wall.visible).is_false()
	assert_object(wall.get_node_or_null("Trigger")).is_null()

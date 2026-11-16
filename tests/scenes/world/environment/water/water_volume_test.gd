class_name WaterVolumeTest extends GdUnitTestSuite

## A wading volume tells a body it holds as it enters and leaves, a removed body included; a pool volume does not.

class Wader extends CharacterBody2D:
	var wading: int = 0

	func enter_wading() -> void:
		wading += 1

	func exit_wading() -> void:
		wading -= 1


var _volume: WaterVolume
var _wader: Wader


func _setup(wade: bool) -> void:
	_volume = auto_free(WaterVolume.new()) as WaterVolume
	_volume.wade = wade
	_volume.collision_mask = 256
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(64, 64)
	shape.shape = rect
	_volume.add_child(shape)
	add_child(_volume)
	_wader = auto_free(Wader.new()) as Wader
	_wader.collision_layer = 256
	var body_shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(8, 8)
	body_shape.shape = box
	_wader.add_child(body_shape)
	_wader.position = Vector2(500, 0)
	add_child(_wader)
	await _frames(3)

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

func test_a_wading_volume_counts_a_body_in_and_out() -> void:
	await _setup(true)
	_wader.position = Vector2.ZERO
	await _frames(3)
	assert_int(_wader.wading).is_equal(1)
	_wader.position = Vector2(500, 0)
	await _frames(3)
	assert_int(_wader.wading).is_equal(0)

func test_a_removed_body_is_told_it_left() -> void:
	await _setup(true)
	_wader.position = Vector2.ZERO
	await _frames(3)
	remove_child(_wader)
	await _frames(3)
	assert_int(_wader.wading).is_equal(0)

func test_a_pool_volume_says_nothing() -> void:
	await _setup(false)
	_wader.position = Vector2.ZERO
	await _frames(3)
	assert_int(_wader.wading).is_equal(0)

func test_the_shallow_scene_wades() -> void:
	var shallow := auto_free(load("res://scenes/world/environment/water/water_shallow.tscn").instantiate()) as Node
	assert_bool((shallow.get_node("Volume") as WaterVolume).wade).is_true()

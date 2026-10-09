class_name AmbientMotionTest extends GdUnitTestSuite

## With no memory field (a scene opened alone) a prop runs at memory 1; a hidden prop holds its frame.


func _prop() -> Sprite2D:
	var sprite := auto_free(Sprite2D.new()) as Sprite2D
	var image := Image.create_empty(32, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.hframes = 4
	var motion := AmbientMotion.new()
	motion.frames_per_second = 60.0
	motion.phase = 0.0
	sprite.add_child(motion)
	add_child(sprite)
	return sprite

func test_it_advances_at_memory_one_without_a_field() -> void:
	var sprite := _prop()
	var seen := {}
	for i: int in 8:
		await get_tree().physics_frame
		seen[sprite.frame] = true
	assert_int(seen.size()).is_greater(1)

func test_a_hidden_prop_holds_its_frame() -> void:
	var sprite := _prop()
	sprite.visible = false
	var before := sprite.frame
	for i: int in 8:
		await get_tree().physics_frame
	assert_int(sprite.frame).is_equal(before)

func test_it_is_pausable_even_under_an_always_parent() -> void:
	var sprite := _prop()
	assert_int(sprite.get_child(0).process_mode).is_equal(Node.PROCESS_MODE_PAUSABLE)

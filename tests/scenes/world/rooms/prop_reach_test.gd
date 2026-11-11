class_name PropReachTest extends GdUnitTestSuite

## PropReach holds everything a contents scene's authored art draws, so RoomResidency builds a waiting room before the view
## meets it (systems/rooms, "Staggered builds").


func _scene(root: Node) -> PackedScene:
	for child: Node in root.get_children():
		child.owner = root
		for grandchild: Node in child.get_children():
			grandchild.owner = root
	var scene := PackedScene.new()
	scene.pack(root)
	root.free()
	return scene

func _sprite(size: Vector2i, at: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8))
	sprite.position = at
	return sprite

func test_the_reach_holds_nested_and_hidden_art() -> void:
	var root := Node2D.new()
	var props := Node2D.new()
	props.name = "Props"
	props.position = Vector2(100, 50)
	root.add_child(props)
	var tower := _sprite(Vector2i(40, 200), Vector2(0, -100))
	props.add_child(tower)
	var hidden := _sprite(Vector2i(20, 20), Vector2(300, 0))
	hidden.visible = false
	props.add_child(hidden)
	var reach := PropReach.of(_scene(root))
	assert_bool(reach.encloses(Rect2(80, -150, 40, 200))).is_true()
	assert_bool(reach.encloses(Rect2(390, 40, 20, 20))).is_true()

func test_the_backdrop_tiles_and_foreground_are_not_art() -> void:
	var root := Node2D.new()
	for skipped: StringName in PropReach.SKIPPED:
		var holder := Node2D.new()
		holder.name = skipped
		root.add_child(holder)
		holder.add_child(_sprite(Vector2i(64, 64), Vector2(5000, 0)))
	assert_bool(PropReach.of(_scene(root)).has_area()).is_false()

## Measured independently of PropReach in every room the game places: each texture or polygon its authored art draws.
func test_every_rooms_art_lies_in_its_reach() -> void:
	var misses := PackedStringArray()
	var measured := 0
	var past_bounds := 0
	for room: Dictionary in WorldRoomsFixture.rooms():
		var scene: PackedScene = room.contents
		var reach := PropReach.of(scene)
		var bounds := Rect2((room.bounds as Rect2).position - (room.at as Vector2), (room.bounds as Rect2).size)
		if reach.has_area() and not bounds.encloses(reach):
			past_bounds += 1
		var contents := scene.instantiate()
		var stack: Array[Node] = [contents]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			if node != contents and node.name in PropReach.SKIPPED:
				continue
			stack.append_array(node.get_children())
			var drawn := _drawn(node)
			if not drawn.has_area():
				continue
			measured += 1
			var placed := _placed(node) * drawn
			if not reach.grow(0.01).encloses(placed):
				misses.append("%s: %s draws %s outside %s" % [room.id, contents.get_path_to(node), placed, reach])
		contents.free()
	assert_int(measured).is_greater(100)
	# The gate towers, the bell tower facade and the border cairn stand past their rooms' tops.
	assert_int(past_bounds).is_greater_equal(4)
	assert_array(misses).is_empty()

func _drawn(node: Node) -> Rect2:
	if node is Sprite2D:
		var sprite := node as Sprite2D
		if sprite.texture == null:
			return Rect2()
		var size := sprite.texture.get_size() / Vector2(sprite.hframes, sprite.vframes)
		if sprite.region_enabled:
			size = sprite.region_rect.size
		return Rect2((-size * 0.5 if sprite.centered else Vector2.ZERO) + sprite.offset, size)
	if node is AnimatedSprite2D:
		var animated := node as AnimatedSprite2D
		if animated.sprite_frames == null or not animated.sprite_frames.has_animation(animated.animation):
			return Rect2()
		var texture := animated.sprite_frames.get_frame_texture(animated.animation, animated.frame)
		if texture == null:
			return Rect2()
		var frame_size := texture.get_size()
		return Rect2((-frame_size * 0.5 if animated.centered else Vector2.ZERO) + animated.offset, frame_size)
	if node is Polygon2D:
		var polygon := node as Polygon2D
		if polygon.polygon.is_empty():
			return Rect2()
		var box := Rect2(polygon.polygon[0], Vector2.ZERO)
		for point: Vector2 in polygon.polygon:
			box = box.expand(point)
		return Rect2(box.position + polygon.offset, box.size)
	return Rect2()

func _placed(node: Node) -> Transform2D:
	var xform := Transform2D.IDENTITY
	var at := node
	while at != null:
		if at is Node2D:
			xform = (at as Node2D).transform * xform
		at = at.get_parent()
	return xform

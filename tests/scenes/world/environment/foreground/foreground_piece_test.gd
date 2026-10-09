class_name ForegroundPieceTest extends GdUnitTestSuite

## A piece draws only on the foreground bit, its parent keeps its bits plus the foreground's, and
## update_for places it and fades it in and out.


func _piece(parent: Node2D) -> ForegroundPiece:
	var piece := ForegroundPiece.new()
	var image := Image.create_empty(40, 40, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	piece.texture = ImageTexture.create_from_image(image)
	piece.position = Vector2(100, 100)
	parent.add_child(piece)
	return piece

func _parent() -> Node2D:
	var parent := auto_free(Node2D.new()) as Node2D
	add_child(parent)
	return parent

func test_the_piece_is_on_the_foreground_bit_alone() -> void:
	var parent := _parent()
	var before := parent.visibility_layer
	var piece := _piece(parent)
	assert_int(piece.visibility_layer).is_equal(CanvasPass.FOREGROUND)
	assert_int(parent.visibility_layer).is_equal(before | CanvasPass.FOREGROUND)
	assert_int(piece.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)

func test_update_for_places_it_by_parallax() -> void:
	var piece := _piece(_parent())
	piece.scroll_scale = Vector2(1.5, 1.0)
	piece.update_for(Vector2(0, 100), [], 0.0)
	assert_vector(piece.position).is_equal(Vector2(150, 100))

func test_it_fades_while_a_body_stands_behind_and_comes_back() -> void:
	var piece := _piece(_parent())
	var behind: Array[Rect2] = [Rect2(85, 85, 10, 20)]
	for i: int in 30:
		piece.update_for(Vector2(100, 100), behind, 0.05)
	assert_float(piece.modulate.a).is_equal_approx(piece.faded_alpha, 0.001)
	for i: int in 30:
		piece.update_for(Vector2(100, 100), [], 0.05)
	assert_float(piece.modulate.a).is_equal(1.0)

func test_a_piece_that_does_not_reveal_stays_opaque() -> void:
	var piece := _piece(_parent())
	piece.reveals = false
	var behind: Array[Rect2] = [Rect2(85, 85, 10, 20)]
	for i: int in 30:
		piece.update_for(Vector2(100, 100), behind, 0.05)
	assert_float(piece.modulate.a).is_equal(1.0)

class_name CanvasPassTest extends GdUnitTestSuite

## Each pass removes its own bit from the root's cull mask while it is in the tree and gives it back
## when it leaves, in any order, and again after a re-add (systems/foreground).

var _mask_before: int


func before_test() -> void:
	_mask_before = get_tree().root.canvas_cull_mask

func after_test() -> void:
	get_tree().root.canvas_cull_mask = _mask_before

func _pass(layer: int) -> CanvasPass:
	var pass_node := CanvasPass.new()
	pass_node.layer = layer
	return pass_node

func test_a_pass_owns_its_bit_while_in_the_tree() -> void:
	var creatures := _pass(CanvasPass.CREATURES)
	add_child(creatures)
	assert_int(get_tree().root.canvas_cull_mask & CanvasPass.CREATURES).is_equal(0)
	remove_child(creatures)
	assert_int(get_tree().root.canvas_cull_mask & CanvasPass.CREATURES).is_equal(CanvasPass.CREATURES)
	creatures.free()

func test_two_passes_leave_in_either_order() -> void:
	for first_out: int in [0, 1]:
		var passes: Array[CanvasPass] = [_pass(CanvasPass.CREATURES), _pass(CanvasPass.FOREGROUND)]
		for pass_node: CanvasPass in passes:
			add_child(pass_node)
		var leaving := passes[first_out]
		var staying := passes[1 - first_out]
		remove_child(leaving)
		assert_int(get_tree().root.canvas_cull_mask & staying.layer).is_equal(0)
		assert_int(get_tree().root.canvas_cull_mask & leaving.layer).is_equal(leaving.layer)
		remove_child(staying)
		for pass_node: CanvasPass in passes:
			pass_node.free()
		assert_int(get_tree().root.canvas_cull_mask).is_equal(_mask_before)

## bugs/a-canvas-pass-re-added-to-the-tree-stops-culling-its-bit
func test_a_pass_re_added_culls_its_bit_again() -> void:
	var foreground := _pass(CanvasPass.FOREGROUND)
	add_child(foreground)
	remove_child(foreground)
	add_child(foreground)
	assert_int(get_tree().root.canvas_cull_mask & CanvasPass.FOREGROUND).is_equal(0)
	remove_child(foreground)
	foreground.free()

func test_join_layer_puts_the_item_on_the_bit_and_its_parent_keeps_its_own() -> void:
	var parent := auto_free(Node2D.new()) as Node2D
	var child := Node2D.new()
	parent.add_child(child)
	CanvasPass.join_layer(child, CanvasPass.FOREGROUND)
	assert_int(child.visibility_layer).is_equal(CanvasPass.FOREGROUND)
	assert_int(parent.visibility_layer).is_equal(1 | CanvasPass.FOREGROUND)

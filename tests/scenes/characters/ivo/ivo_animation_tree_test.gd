class_name IvoAnimationTreeTest extends GdUnitTestSuite

## Ivo's AnimationTree runs through a freeze only while a performance holds it,
## so a menu stops him (docs/knowledge/architecture/pause-menu-worldfreeze-reuse.md).

const IVO := preload("res://scenes/characters/ivo/ivo.tscn")


func test_the_tree_runs_always_only_during_a_performance() -> void:
	var ivo := auto_free(IVO.instantiate()) as Player
	add_child(ivo)
	var tree := ivo.get_node("AnimationTree") as AnimationTree
	assert_int(tree.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	ivo.performance_started.emit()
	assert_int(tree.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)
	ivo.performance_finished.emit()
	assert_int(tree.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)

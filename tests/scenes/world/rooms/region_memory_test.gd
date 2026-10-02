class_name RegionMemoryTest extends GdUnitTestSuite

## Loaded restored regions retain saved death marks; live restoration removes them with erase_marks.

var _region: Node2D
var _memory: RegionMemory

func before_test() -> void:
	_region = auto_free(Node2D.new())
	_region.position = Vector2(1000, 500)
	_memory = RegionMemory.new()
	_region.add_child(_memory)
	add_child(_region)

func test_one_mark_per_cluster_of_deaths_at_the_region_point() -> void:
	_memory.mark_deaths(PackedVector2Array([Vector2(10, 0), Vector2(14, 0), Vector2(400, 0)]))
	var marks := _memory.marks()
	assert_int(marks.size()).is_equal(2)
	assert_vector(marks[0].global_position).is_equal(Vector2(1012, 500))
	assert_float(marks[0].strength).is_less(0.0)

func test_marks_survive_a_restoration_loaded_whole() -> void:
	_memory.mark_deaths(PackedVector2Array([Vector2(10, 0)]))
	_memory.restore(0.0)
	assert_int(_memory.marks().size()).is_equal(1)

func test_erase_marks_takes_them_away() -> void:
	_memory.mark_deaths(PackedVector2Array([Vector2(10, 0), Vector2(400, 0)]))
	_memory.erase_marks(0.0)
	assert_array(_memory.marks()).is_empty()

func test_marking_again_replaces_the_old_marks() -> void:
	_memory.mark_deaths(PackedVector2Array([Vector2(10, 0), Vector2(400, 0)]))
	_memory.mark_deaths(PackedVector2Array([Vector2(10, 0)]))
	assert_int(_memory.marks().size()).is_equal(1)

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

func test_level_for_without_steps_is_authored() -> void:
	var none: Dictionary[int, float] = {}
	assert_float(RegionMemory.level_for(0.8, none, 3)).is_equal(0.8)

func test_level_for_takes_the_step_from_its_count_on() -> void:
	var village: Dictionary[int, float] = {2: 0.6}
	assert_float(RegionMemory.level_for(0.8, village, 0)).is_equal(0.8)
	assert_float(RegionMemory.level_for(0.8, village, 1)).is_equal(0.8)
	assert_float(RegionMemory.level_for(0.8, village, 2)).is_equal(0.6)
	assert_float(RegionMemory.level_for(0.8, village, 3)).is_equal(0.6)

func test_level_for_takes_the_highest_key_reached_in_any_order() -> void:
	var out_of_order: Dictionary[int, float] = {4: 0.4, 2: 0.6}
	assert_float(RegionMemory.level_for(0.8, out_of_order, 3)).is_equal(0.6)
	assert_float(RegionMemory.level_for(0.8, out_of_order, 5)).is_equal(0.4)

func test_follow_restorations_sets_the_step_once() -> void:
	_memory.steps = {2: 0.6}
	var levels: Array[float] = []
	_memory.changed.connect(func(level: float) -> void: levels.append(level))
	_memory.follow_restorations(2)
	assert_float(_memory.current()).is_equal(0.6)
	_memory.follow_restorations(2)
	assert_array(levels).is_equal([0.6])

func test_a_restored_region_ignores_the_steps() -> void:
	_memory.steps = {2: 0.6}
	_memory.restore(0.0)
	_memory.follow_restorations(2)
	assert_float(_memory.current()).is_equal(1.0)

func test_a_running_restoration_is_not_pulled_down() -> void:
	_memory.steps = {2: 0.6}
	_memory.restore(6.0)
	_memory.follow_restorations(2)
	assert_float(_memory.current()).is_greater_equal(0.8)
	await await_millis(500)
	assert_float(_memory.current()).is_greater(0.8)

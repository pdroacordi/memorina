class_name RegionTest extends GdUnitTestSuite

## A region's baseline follows how many guardians are restored, and its own guardian still wins.


func before_test() -> void:
	SaveSystem.begin("", true)

func after_test() -> void:
	SaveSystem.begin("", true)

func _region(has_guardian: bool, guardian: Enums.Guardian) -> Region:
	var region := Region.new()
	# A scene path keys the region quietly (SceneKey warns for a bare node).
	region.scene_file_path = "res://scenes/world/rooms/home_village.tscn"
	region.has_guardian = has_guardian
	region.guardian = guardian
	var memory := RegionMemory.new()
	memory.name = "Memory"
	memory.authored = 0.8
	memory.steps = {2: 0.6}
	region.add_child(memory)
	add_child(region)
	return auto_free(region)

func test_restored_guardian_count_counts_every_restoration() -> void:
	assert_int(SaveSystem.restored_guardian_count()).is_equal(0)
	SaveSystem.restore_guardian(Enums.Guardian.FROST)
	assert_int(SaveSystem.restored_guardian_count()).is_equal(1)
	SaveSystem.restore_guardian(Enums.Guardian.BLOOM)
	assert_int(SaveSystem.restored_guardian_count()).is_equal(2)

func test_a_region_built_after_two_restorations_starts_on_the_step() -> void:
	SaveSystem.restore_guardian(Enums.Guardian.FROST)
	SaveSystem.restore_guardian(Enums.Guardian.BLOOM)
	var region := _region(false, Enums.Guardian.FROST)
	assert_float(region.current_baseline()).is_equal(0.6)

func test_the_second_restoration_lowers_a_running_region() -> void:
	SaveSystem.restore_guardian(Enums.Guardian.FROST)
	var region := _region(false, Enums.Guardian.FROST)
	assert_float(region.current_baseline()).is_equal(0.8)
	var levels: Array[float] = []
	region.memory_changed.connect(func(level: float) -> void: levels.append(level))
	SaveSystem.restore_guardian(Enums.Guardian.BLOOM)
	assert_float(region.current_baseline()).is_equal(0.6)
	assert_array(levels).is_equal([0.6])

func test_a_region_whose_own_guardian_is_second_reaches_whole() -> void:
	SaveSystem.restore_guardian(Enums.Guardian.FROST)
	var region := _region(true, Enums.Guardian.BLOOM)
	region.get_node("Memory").lift_time = 0.0
	SaveSystem.restore_guardian(Enums.Guardian.BLOOM)
	assert_float(region.current_baseline()).is_equal(1.0)

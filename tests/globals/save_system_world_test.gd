class_name SaveSystemWorldTest extends GdUnitTestSuite

## The final battle's victory writes the save at once, the one exception to benches ("Exceção: salva na hora", user,
## 2026-10-30; GRD-06); a death after it keeps the restored world.


func before_test() -> void:
	SaveSystem.begin("", true)

func after_test() -> void:
	SaveSystem.begin("", true)

func test_restoring_the_world_saves_at_once_and_survives_a_death() -> void:
	var heard: Array[bool] = []
	SaveSystem.world_restored.connect(func() -> void: heard.append(true))
	SaveSystem.restore_world()
	assert_bool(SaveSystem.is_world_restored()).is_true()
	assert_array(heard).has_size(1)
	# A rewind returns to the last commit: the victory is in it.
	SaveSystem.rewind()
	assert_bool(SaveSystem.is_world_restored()).is_true()

func test_the_revelation_is_marked_once_and_kept() -> void:
	assert_bool(SaveSystem.is_finale_revealed()).is_false()
	SaveSystem.mark_finale_revealed()
	SaveSystem.rewind()
	assert_bool(SaveSystem.is_finale_revealed()).is_true()

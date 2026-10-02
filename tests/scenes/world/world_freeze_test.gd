class_name WorldFreezeTest extends GdUnitTestSuite

## A freeze runs at time scale 1, a hold at 0, a thaw or release returns to a
## recall's slow, and a world leaving the tree leaves a running clock behind.

var _freeze: WorldFreeze


func before_test() -> void:
	_freeze = WorldFreeze.new()
	_freeze.slow_ramp = 0.0
	add_child(_freeze)

func after_test() -> void:
	if is_instance_valid(_freeze):
		if _freeze.is_inside_tree():
			remove_child(_freeze)
		_freeze.free()

func test_a_freeze_runs_at_full_speed_during_a_recall() -> void:
	_freeze.slow()
	assert_float(Engine.time_scale).is_equal_approx(_freeze.slow_scale, 0.0001)
	_freeze.freeze()
	var paused := get_tree().paused
	var scale := Engine.time_scale
	_freeze.thaw()
	assert_bool(paused).is_true()
	assert_float(scale).is_equal(1.0)

func test_a_thaw_returns_to_the_recall_slow() -> void:
	_freeze.slow()
	_freeze.freeze()
	_freeze.thaw()
	assert_bool(get_tree().paused).is_false()
	assert_float(Engine.time_scale).is_equal_approx(_freeze.slow_scale, 0.0001)

func test_a_thaw_without_a_recall_runs_at_full_speed() -> void:
	_freeze.freeze()
	_freeze.thaw()
	assert_float(Engine.time_scale).is_equal(1.0)

## The hit-stop restores the clock itself when it ends.
func test_a_thaw_leaves_a_hit_stop_in_flight() -> void:
	_freeze.slow()
	_freeze.hit_stop()
	_freeze.freeze()
	_freeze.thaw()
	assert_float(Engine.time_scale).is_equal_approx(_freeze.hit_stop_scale, 0.0001)
	await get_tree().create_timer(_freeze.hit_stop_time + 0.05, true, false, true).timeout
	assert_float(Engine.time_scale).is_equal_approx(_freeze.slow_scale, 0.0001)

func test_leaving_the_tree_resets_the_clock() -> void:
	_freeze.slow()
	_freeze.freeze()
	remove_child(_freeze)
	assert_bool(get_tree().paused).is_false()
	assert_float(Engine.time_scale).is_equal(1.0)

func test_a_hold_pauses_at_scale_zero() -> void:
	_freeze.hold()
	var paused := get_tree().paused
	var scale := Engine.time_scale
	var held := WorldFreeze.is_held()
	_freeze.release()
	assert_bool(paused).is_true()
	assert_float(scale).is_equal(0.0)
	assert_bool(held).is_true()
	assert_bool(WorldFreeze.is_held()).is_false()

func test_a_release_returns_to_the_recall_slow() -> void:
	_freeze.slow()
	_freeze.hold()
	_freeze.release()
	assert_bool(get_tree().paused).is_false()
	assert_float(Engine.time_scale).is_equal_approx(_freeze.slow_scale, 0.0001)

## A hit-stop that ends under a hold leaves the clock stopped.
func test_a_hit_stop_ending_under_a_hold_keeps_scale_zero() -> void:
	_freeze.hit_stop()
	_freeze.hold()
	await get_tree().create_timer(_freeze.hit_stop_time + 0.05, true, false, true).timeout
	var scale := Engine.time_scale
	_freeze.release()
	assert_float(scale).is_equal(0.0)
	assert_float(Engine.time_scale).is_equal(1.0)

func test_leaving_the_tree_clears_the_hold() -> void:
	_freeze.hold()
	remove_child(_freeze)
	assert_bool(WorldFreeze.is_held()).is_false()
	assert_bool(get_tree().paused).is_false()
	assert_float(Engine.time_scale).is_equal(1.0)

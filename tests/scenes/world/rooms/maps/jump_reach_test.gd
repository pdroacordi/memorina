class_name JumpReachTest extends GdUnitTestSuite

## Checks jump reach using the configured gravity curve.

func _reach(double_jump_height: float = 0.0) -> JumpReach:
	var jump := JumpStats.new()
	jump.jump_height = 100.0
	jump.rise_gravity_mult = 1.0
	jump.fall_gravity_mult = 1.0
	jump.apex_gravity_mult = 1.0
	jump.terminal_velocity = 10000.0
	var locomotion := LocomotionStats.new()
	locomotion.move_speed = 100.0
	return JumpReach.new(1000.0, jump, locomotion, double_jump_height, 0.0)

func test_a_plain_jump_peaks_at_its_height() -> void:
	# Match engine integration order: velocity updates before position.
	assert_float(_reach().peak()).is_equal_approx(100.0, 5.0)

func test_a_plain_arc_is_symmetric() -> void:
	# At these settings, rise and fall each take about 0.447 seconds.
	assert_float(_reach().gap()).is_equal_approx(89.4, 3.0)

func test_the_double_jump_adds_its_height_at_the_apex() -> void:
	assert_float(_reach(50.0).peak(true)).is_equal_approx(150.0, 8.0)

func test_the_double_jump_carries_further() -> void:
	var reach := _reach(50.0)
	assert_float(reach.gap(true)).is_greater(reach.gap())

func test_a_higher_ledge_is_reached_sooner() -> void:
	var reach := _reach()
	assert_float(reach.reach_at(32.0)).is_less(reach.gap())

func test_a_ledge_above_the_peak_is_out_of_reach() -> void:
	assert_float(_reach().reach_at(200.0)).is_equal(0.0)

func test_the_body_overhangs_both_edges() -> void:
	var jump := JumpStats.new()
	var locomotion := LocomotionStats.new()
	var thin := JumpReach.new(1000.0, jump, locomotion, 0.0, 0.0)
	var wide := JumpReach.new(1000.0, jump, locomotion, 0.0, 10.0)
	assert_float(wide.gap() - thin.gap()).is_equal_approx(20.0, 0.01)

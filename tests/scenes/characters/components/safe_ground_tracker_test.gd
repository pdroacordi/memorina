class_name SafeGroundTrackerTest extends GdUnitTestSuite

## Where a hazard may send a body back to: firm floor under BOTH probes, and
## never ground that will not be there (FREEZE's ice).

func _ground(unsafe := false) -> Node:
	var ground: Node = auto_free(Node.new())
	if unsafe:
		ground.add_to_group(SafeGroundTracker.UNSAFE)
	return ground

func test_firm_ground_under_both_probes_is_firm() -> void:
	assert_bool(SafeGroundTracker.is_firm(_ground(), _ground())).is_true()

func test_a_probe_over_the_edge_is_not_firm() -> void:
	# The lip of a ledge: one probe finds nothing.
	assert_bool(SafeGroundTracker.is_firm(_ground(), null)).is_false()
	assert_bool(SafeGroundTracker.is_firm(null, _ground())).is_false()

func test_nothing_under_either_probe_is_not_firm() -> void:
	assert_bool(SafeGroundTracker.is_firm(null, null)).is_false()

func test_ice_is_never_ground_to_come_back_to() -> void:
	var ice := _ground(true)
	assert_bool(SafeGroundTracker.is_firm(ice, ice)).is_false()

func test_a_probe_on_ice_and_a_probe_on_the_bank_is_not_firm() -> void:
	assert_bool(SafeGroundTracker.is_firm(_ground(), _ground(true))).is_false()

func test_ground_that_is_not_a_node_counts_as_firm() -> void:
	# A raw collider object with no groups must not be mistaken for unsafe.
	var plain: RefCounted = RefCounted.new()
	assert_bool(SafeGroundTracker.is_firm(plain, plain)).is_true()

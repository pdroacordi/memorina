class_name SafeGroundTrackerTest extends GdUnitTestSuite

## Where a hazard may send a body back to: standing, with firm floor under
## BOTH feet, and never on ground that will not be there (FREEZE's ice).

func _ground(unsafe := false) -> Node:
	var ground: Node = auto_free(Node.new())
	if unsafe:
		ground.add_to_group(SafeGroundTracker.UNSAFE)
	return ground

func test_standing_on_firm_ground_is_safe() -> void:
	assert_bool(SafeGroundTracker.is_safe(true, _ground(), _ground())).is_true()

func test_in_the_air_is_never_safe() -> void:
	assert_bool(SafeGroundTracker.is_safe(false, _ground(), _ground())).is_false()

func test_a_foot_over_the_edge_is_not_safe() -> void:
	# The lip of a ledge: one probe finds nothing.
	assert_bool(SafeGroundTracker.is_safe(true, _ground(), null)).is_false()
	assert_bool(SafeGroundTracker.is_safe(true, null, _ground())).is_false()

func test_ice_is_never_ground_to_come_back_to() -> void:
	var ice := _ground(true)
	assert_bool(SafeGroundTracker.is_safe(true, ice, ice)).is_false()

func test_a_foot_on_ice_and_a_foot_on_the_bank_is_not_safe() -> void:
	assert_bool(SafeGroundTracker.is_safe(true, _ground(), _ground(true))).is_false()

func test_ground_that_is_not_a_node_counts_as_firm() -> void:
	# A TileMapLayer's physics comes back as the layer node, but a raw
	# collider object with no groups must not be mistaken for unsafe.
	var plain: RefCounted = RefCounted.new()
	assert_bool(SafeGroundTracker.is_safe(true, plain, plain)).is_true()

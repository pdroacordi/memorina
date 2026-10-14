class_name RegionTitlePolicyTest extends GdUnitTestSuite

## A region's title plays once, on an entry that is not the first room of a world build.

const NONE := RegionTitlePolicy.Action.NONE
const RECORD := RegionTitlePolicy.Action.RECORD
const ANNOUNCE := RegionTitlePolicy.Action.ANNOUNCE


func test_the_first_room_of_a_world_records_silently() -> void:
	assert_int(RegionTitlePolicy.decide(true, true, false)).is_equal(RECORD)

func test_a_new_region_announces() -> void:
	assert_int(RegionTitlePolicy.decide(true, false, false)).is_equal(ANNOUNCE)

func test_an_announced_region_does_nothing() -> void:
	assert_int(RegionTitlePolicy.decide(true, false, true)).is_equal(NONE)
	assert_int(RegionTitlePolicy.decide(true, true, true)).is_equal(NONE)

func test_a_test_bed_neither_announces_nor_records() -> void:
	assert_int(RegionTitlePolicy.decide(false, false, false)).is_equal(NONE)
	assert_int(RegionTitlePolicy.decide(false, true, false)).is_equal(NONE)

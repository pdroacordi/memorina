class_name DoorLinksTest extends GdUnitTestSuite

## A door link joins exactly two doors in two rooms of one region, each naming the other's room.


func _door(room: StringName, link: StringName, to_room: StringName, region: StringName = &"village") -> DoorLinks.Record:
	return DoorLinks.Record.new(room, region, link, to_room, "%s.room" % room)

func test_a_well_formed_pair_has_no_problems() -> void:
	var records: Array[DoorLinks.Record] = [
		_door(&"square", &"tavern_front", &"tavern"),
		_door(&"tavern", &"tavern_front", &"square"),
	]
	assert_array(Array(DoorLinks.problems(records))).is_empty()

func test_a_link_used_once_is_reported() -> void:
	var records: Array[DoorLinks.Record] = [_door(&"square", &"tavern_front", &"tavern")]
	assert_str("\n".join(DoorLinks.problems(records))).contains("used by 1 doors")

func test_a_link_used_three_times_is_reported() -> void:
	var records: Array[DoorLinks.Record] = [
		_door(&"square", &"front", &"tavern"),
		_door(&"tavern", &"front", &"square"),
		_door(&"bakery", &"front", &"square"),
	]
	assert_str("\n".join(DoorLinks.problems(records))).contains("used by 3 doors")

func test_a_door_naming_the_wrong_room_is_reported() -> void:
	var records: Array[DoorLinks.Record] = [
		_door(&"square", &"front", &"bakery"),
		_door(&"tavern", &"front", &"square"),
	]
	assert_str("\n".join(DoorLinks.problems(records))).contains("leads to bakery, but its partner is in tavern")

func test_both_doors_in_one_room_is_reported() -> void:
	var records: Array[DoorLinks.Record] = [
		_door(&"square", &"front", &"square"),
		_door(&"square", &"front", &"square"),
	]
	assert_str("\n".join(DoorLinks.problems(records))).contains("to itself")

func test_a_pair_across_regions_is_reported() -> void:
	var records: Array[DoorLinks.Record] = [
		_door(&"square", &"front", &"tavern", &"village"),
		_door(&"tavern", &"front", &"square", &"woods"),
	]
	assert_str("\n".join(DoorLinks.problems(records))).contains("crosses regions")

class_name FlashbackScheduleTest extends GdUnitTestSuite

## FlashbackSchedule names one flashback at a time, in order, each behind its gate.


func _data(memorina: bool, restored: int, seen: Array[int]) -> PlayerData:
	var data := PlayerData.new()
	data.owned_items[Enums.PlayerItem.MEMORINA] = memorina
	var guardians: Array = Enums.Guardian.values()
	for guardian: int in guardians.slice(0, restored):
		data.restored_guardians[guardian] = true
	for number: int in seen:
		data.scenes_seen.append(FlashbackSchedule.id(number))
	return data

func _prefix(count: int) -> Array[int]:
	var seen: Array[int] = []
	for number: int in range(1, count + 1):
		seen.append(number)
	return seen

func _gate(number: int, memorina: bool, restored: int) -> bool:
	return memorina if number == 1 else restored >= number - 1

func test_the_ids_follow_the_format() -> void:
	assert_str(String(FlashbackSchedule.id(1))).is_equal("flashback_1")
	assert_str(String(FlashbackSchedule.id(FlashbackSchedule.COUNT))).is_equal("flashback_5")

func test_every_seen_prefix_under_every_gate() -> void:
	for memorina: bool in [false, true]:
		for restored: int in range(0, Enums.Guardian.size() + 1):
			for count: int in range(0, FlashbackSchedule.COUNT + 1):
				var data := _data(memorina, restored, _prefix(count))
				var next := count + 1
				var expected := next if next <= FlashbackSchedule.COUNT and _gate(next, memorina, restored) else 0
				assert_int(FlashbackSchedule.due(data)) \
						.override_failure_message("memorina %s, restored %d, seen %d" % [memorina, restored, count]) \
						.is_equal(expected)
				assert_int(FlashbackSchedule.seen_count(data)).is_equal(count)

func test_the_order_never_breaks_for_any_seen_set() -> void:
	for memorina: bool in [false, true]:
		for restored: int in range(0, Enums.Guardian.size() + 1):
			for mask: int in range(0, 1 << FlashbackSchedule.COUNT):
				var seen: Array[int] = []
				for number: int in range(1, FlashbackSchedule.COUNT + 1):
					if mask & (1 << (number - 1)):
						seen.append(number)
				var due := FlashbackSchedule.due(_data(memorina, restored, seen))
				if due == 0:
					continue
				assert_bool(seen.has(due)).is_false()
				assert_bool(_gate(due, memorina, restored)).is_true()
				for earlier: int in range(1, due):
					assert_bool(seen.has(earlier)) \
							.override_failure_message("flashback %d due before %d, seen %s" % [due, earlier, seen]) \
							.is_true()

func test_an_unseen_earlier_flashback_comes_first() -> void:
	var seen_two: Array[int] = [2]
	assert_int(FlashbackSchedule.due(_data(true, 4, seen_two))).is_equal(1)
	var seen_one_three: Array[int] = [1, 3]
	assert_int(FlashbackSchedule.due(_data(true, 4, seen_one_three))).is_equal(2)
	assert_int(FlashbackSchedule.seen_count(_data(true, 4, seen_one_three))).is_equal(2)

func test_a_closed_gate_holds_back_every_later_one() -> void:
	var none: Array[int] = []
	assert_int(FlashbackSchedule.due(_data(false, 4, none))).is_equal(0)
	var seen_one: Array[int] = [1]
	assert_int(FlashbackSchedule.due(_data(true, 0, seen_one))).is_equal(0)

func test_other_scenes_seen_are_not_flashbacks() -> void:
	var data := _data(true, 0, [] as Array[int])
	data.scenes_seen.append(&"flashback_0")
	data.scenes_seen.append(&"opening_daughter_to_bed")
	assert_int(FlashbackSchedule.seen_count(data)).is_equal(0)
	assert_int(FlashbackSchedule.due(data)).is_equal(1)

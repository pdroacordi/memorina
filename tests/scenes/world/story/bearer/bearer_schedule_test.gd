class_name BearerScheduleTest extends GdUnitTestSuite

## A fragment is due once its guardian is restored and until its engraving is seen (architecture/story-04-bearer-fragments).

const B := preload("res://tests/resources/story/bearers/bearer_fixture.gd")


func test_the_id_names_the_guardian() -> void:
	assert_str(String(BearerSchedule.id(Enums.Guardian.FROST))).is_equal("bearer_frost")
	assert_str(String(BearerSchedule.id(Enums.Guardian.BLOOM))).is_equal("bearer_bloom")
	assert_str(String(BearerSchedule.id(Enums.Guardian.AUTUMN))).is_equal("bearer_autumn")
	assert_str(String(BearerSchedule.id(Enums.Guardian.SUMMER))).is_equal("bearer_summer")

func test_restored_times_seen_for_every_guardian() -> void:
	for guardian: int in Enums.Guardian.values():
		var fragment := B.fragment()
		fragment.guardian = guardian
		fragment.engraving.id = BearerSchedule.id(guardian)
		for restored: bool in [false, true]:
			for seen: bool in [false, true]:
				var data := PlayerData.new()
				data.restored_guardians[guardian] = restored
				if seen:
					data.scenes_seen.append(fragment.engraving.id)
				assert_bool(BearerSchedule.due(data, fragment)).override_failure_message(
						"guardian %d restored %s seen %s" % [guardian, restored, seen]).is_equal(restored and not seen)

func test_another_guardian_restored_does_not_make_it_due() -> void:
	var data := PlayerData.new()
	data.restored_guardians[Enums.Guardian.BLOOM] = true
	assert_bool(BearerSchedule.due(data, B.fragment())).is_false()

func test_nothing_is_due_without_a_fragment() -> void:
	assert_bool(BearerSchedule.due(PlayerData.new(), null)).is_false()

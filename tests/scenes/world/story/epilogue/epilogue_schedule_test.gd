class_name EpilogueScheduleTest extends GdUnitTestSuite

## EpilogueSchedule: the epilogue is due after the world, every flashback and the reunion, until it is seen.


func _data(restored: bool, seen: int, reunion: bool, epilogue: bool) -> PlayerData:
	var data := PlayerData.new()
	data.world_restored = restored
	for number: int in range(1, seen + 1):
		data.scenes_seen.append(FlashbackSchedule.id(number))
	if reunion:
		data.dialogues_heard.append(EpilogueSchedule.REUNION_ID)
	if epilogue:
		data.scenes_seen.append(EpilogueSchedule.EPILOGUE_ID)
	return data

func test_due_needs_every_part_and_no_epilogue_seen() -> void:
	for restored: bool in [false, true]:
		for seen: int in range(0, FlashbackSchedule.COUNT + 1):
			for reunion: bool in [false, true]:
				for epilogue: bool in [false, true]:
					var expected := restored and seen == FlashbackSchedule.COUNT and reunion and not epilogue
					assert_bool(EpilogueSchedule.due(_data(restored, seen, reunion, epilogue))) \
							.override_failure_message("restored %s, seen %d, reunion %s, epilogue %s" % [restored, seen, reunion, epilogue]) \
							.is_equal(expected)

func test_finished_follows_the_credits_alone() -> void:
	var data := _data(true, FlashbackSchedule.COUNT, true, true)
	assert_bool(EpilogueSchedule.finished(data)).is_false()
	data.scenes_seen.append(EpilogueSchedule.CREDITS_ID)
	assert_bool(EpilogueSchedule.finished(data)).is_true()
	assert_bool(EpilogueSchedule.due(data)).is_false()

func test_the_fact_resources_name_the_schedule_ids() -> void:
	var due := load("res://resources/save_facts/epilogue_due.tres") as SaveFact
	var reunion := load("res://resources/save_facts/heard_daughter_reunion.tres") as SaveFact
	var epilogue := load("res://resources/save_facts/seen_epilogue.tres") as SaveFact
	var credits := load("res://resources/save_facts/seen_credits.tres") as SaveFact
	var restored := load("res://resources/save_facts/world_restored.tres") as SaveFact
	assert_int(due.kind).is_equal(SaveFact.Kind.EPILOGUE_DUE)
	assert_int(reunion.kind).is_equal(SaveFact.Kind.DIALOGUE_HEARD)
	assert_str(String(reunion.id)).is_equal(String(EpilogueSchedule.REUNION_ID))
	assert_int(epilogue.kind).is_equal(SaveFact.Kind.SCENE_SEEN)
	assert_str(String(epilogue.id)).is_equal(String(EpilogueSchedule.EPILOGUE_ID))
	assert_int(credits.kind).is_equal(SaveFact.Kind.SCENE_SEEN)
	assert_str(String(credits.id)).is_equal(String(EpilogueSchedule.CREDITS_ID))
	assert_int(restored.kind).is_equal(SaveFact.Kind.WORLD_RESTORED)

class_name EpilogueSaveTest extends GdUnitTestSuite

## The post-credits rest (decision 1, "Pedra vira banco"): once the credits are seen the stone's gates open only the
## bench garden_stone, and a rest there commits the ending: the save a rebuilt world reads names that bench, the credits
## seen and the epilogue no longer due. The full reload is the step 11 playtest (story07_reload).

const GARDEN := preload("res://scenes/world/rooms/home_village/contents/village_garden_contents.tscn")



func before_test() -> void:
	SaveSystem.begin("", true)

func after_test() -> void:
	SaveSystem.begin("", true)

func _end_the_ending() -> void:
	var data := SaveSystem.player_data
	data.world_restored = true
	for number: int in range(1, FlashbackSchedule.COUNT + 1):
		data.scenes_seen.append(FlashbackSchedule.id(number))
	SaveSystem.mark_dialogue_heard(EpilogueSchedule.REUNION_ID)
	SaveSystem.mark_scene_seen(EpilogueSchedule.EPILOGUE_ID)
	SaveSystem.mark_scene_seen(EpilogueSchedule.CREDITS_ID)

func test_after_the_credits_the_stone_is_the_bench_and_the_rest_keeps_the_ending() -> void:
	var garden := auto_free(GARDEN.instantiate()) as Node
	var stone_gate := garden.get_node("Seats/StoneSeatGate") as SeatGate
	var bench_gate := garden.get_node("Seats/StoneBenchGate") as SeatGate
	var bench := garden.get_node("Seats/StoneBench") as Bench
	assert_str(String(bench.bench_id)).is_equal(String(EpilogueSchedule.BENCH_ID))
	assert_bool(SaveFact.gates_pass(stone_gate.when, stone_gate.unless, SaveSystem.player_data)).is_true()
	assert_bool(SaveFact.gates_pass(bench_gate.when, bench_gate.unless, SaveSystem.player_data)).is_false()
	_end_the_ending()
	assert_bool(SaveFact.gates_pass(stone_gate.when, stone_gate.unless, SaveSystem.player_data)).is_false()
	assert_bool(SaveFact.gates_pass(bench_gate.when, bench_gate.unless, SaveSystem.player_data)).is_true()
	SaveSystem.rest_at(bench.bench_id, "village_garden", "REGION_HOME_VILLAGE")
	# A death rewinds to the rest: the rebuilt world reads what it committed.
	SaveSystem.rewind()
	var data := SaveSystem.player_data
	assert_str(String(SaveSystem.bench_id())).is_equal(String(EpilogueSchedule.BENCH_ID))
	assert_bool(EpilogueSchedule.finished(data)).is_true()
	assert_bool(EpilogueSchedule.due(data)).is_false()
	assert_str(SaveSlots.bench_name_key(SaveSystem.bench_id())).is_equal("BENCH_GARDEN_STONE")

## Before the rest nothing of the ending is committed: a quit (a rewind) leaves the epilogue due again.
func test_before_the_rest_a_rewind_leaves_the_epilogue_due() -> void:
	var data := SaveSystem.player_data
	data.world_restored = true
	for number: int in range(1, FlashbackSchedule.COUNT + 1):
		data.scenes_seen.append(FlashbackSchedule.id(number))
	SaveSystem.mark_dialogue_heard(EpilogueSchedule.REUNION_ID)
	SaveSystem.commit()
	SaveSystem.mark_scene_seen(EpilogueSchedule.EPILOGUE_ID)
	SaveSystem.mark_scene_seen(EpilogueSchedule.CREDITS_ID)
	SaveSystem.rewind()
	assert_bool(EpilogueSchedule.due(SaveSystem.player_data)).is_true()
	assert_bool(EpilogueSchedule.finished(SaveSystem.player_data)).is_false()

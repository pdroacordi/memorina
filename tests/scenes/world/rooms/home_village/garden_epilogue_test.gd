class_name GardenEpilogueTest extends GdUnitTestSuite

## The present garden for the epilogue (architecture/story-07-epilogue): late afternoon while the epilogue is due and after
## it, and the flat stone's two seats, the scene's seat until the credits and the bench garden_stone after them.

const CONTENTS := preload("res://scenes/world/rooms/home_village/contents/village_garden_contents.tscn")
const AFTERNOON := "res://resources/world/backdrops/waterfall_garden_afternoon.tres"

var _garden: Node


func before_test() -> void:
	SaveSystem.begin("", true)
	_garden = auto_free(CONTENTS.instantiate()) as Node
	add_child(_garden)

func after_test() -> void:
	SaveSystem.begin("", true)

func _due() -> PlayerData:
	var data := PlayerData.new()
	data.world_restored = true
	for number: int in range(1, FlashbackSchedule.COUNT + 1):
		data.scenes_seen.append(FlashbackSchedule.id(number))
	data.dialogues_heard.append(EpilogueSchedule.REUNION_ID)
	return data

func _shown(staging: String, data: PlayerData) -> String:
	var node := _garden.get_node(staging) as FactStaging
	var index := FactStaging.pick(node.stages, data)
	return String(node.stages[index].show) if index >= 0 else ""

func test_the_garden_is_late_afternoon_while_due_and_after() -> void:
	var sky := _garden.get_node("Sky") as FactBackdrop
	var rest := (_garden.get_node("Backdrop") as Backdrop).backdrop_set
	var data := _due()
	data.scenes_seen.erase(FlashbackSchedule.id(5))
	assert_object(FactBackdrop.set_for(sky.sets, data, rest)).is_not_same(load(AFTERNOON))
	assert_str(_shown("Stagings/Light", data)).is_equal("")
	data = _due()
	for seen: bool in [false, true]:
		if seen:
			data.scenes_seen.append(EpilogueSchedule.EPILOGUE_ID)
		assert_object(FactBackdrop.set_for(sky.sets, data, rest)).is_same(load(AFTERNOON))
		assert_str(_shown("Stagings/Light", data)).is_equal("LateAfternoon")
		assert_str(_shown("Props/Lantern", data)).is_equal("LitDusk")

func test_the_stone_is_the_scenes_seat_until_the_credits_then_a_bench() -> void:
	var seat := _garden.get_node("Seats/StoneSeat") as GroundSeat
	var bench := _garden.get_node("Seats/StoneBench") as Bench
	assert_bool(seat.seat().ground).is_false()
	assert_object(seat.when[0]).is_same(load("res://resources/save_facts/epilogue_due.tres"))
	assert_str(String(bench.bench_id)).is_equal(String(EpilogueSchedule.BENCH_ID))
	assert_vector(bench.position).is_equal(seat.position)
	assert_bool((bench.get_node("Sprite2D") as CanvasItem).visible).is_false()
	assert_bool(seat.seat().open).is_true()
	assert_bool((bench.get_node("Seat") as Seat).open).is_false()
	SaveSystem.mark_scene_seen(EpilogueSchedule.CREDITS_ID)
	assert_bool(seat.seat().open).is_false()
	assert_bool((bench.get_node("Seat") as Seat).open).is_true()

func test_albas_mark_is_beside_the_stone() -> void:
	var mark := _garden.get_node("Marks/BesideStone") as CutsceneMark
	assert_str(String(mark.mark_id)).is_equal("beside_stone")
	assert_float(mark.position.y).is_equal((_garden.get_node("Marks/FlatStone") as Node2D).position.y)

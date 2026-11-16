class_name GardenMemoryTest extends GdUnitTestSuite

## The garden's memory is the village baseline plus GardenWell, whose FactWell levels are derived from seen flashbacks
## (architecture/story-05-playable-flashbacks): grey with none seen, still under 0.2 through three, moving from the
## fourth; at 1.0 the same targets until all five are seen, then whole (architecture/story-07-epilogue).

const REGION := "res://scenes/world/rooms/home_village.tscn"
const CONTENTS := "res://scenes/world/rooms/home_village/contents/village_garden_contents.tscn"
## Memory at the waterfall by flashbacks seen, the plan's targets.
const TARGETS: Array[float] = [0.0, 0.05, 0.1, 0.15, 0.4, 0.8]

var _region: Node2D


func before() -> void:
	_region = (load(REGION) as PackedScene).instantiate() as Node2D

func after() -> void:
	_region.free()

func _well() -> FactWell:
	return _region.get_node("GardenWell/FactWell") as FactWell

func _source() -> MemorySource:
	return _region.get_node("GardenWell") as MemorySource

## Flashback n is seen only with n - 1 guardians or more restored (FlashbackSchedule), so these are the reachable saves.
func _reachable(restored: int) -> Array[int]:
	var counts: Array[int] = [0]
	for seen: int in range(1, FlashbackSchedule.COUNT + 1):
		if restored >= seen - 1:
			counts.append(seen)
	return counts

func _data(restored: int, seen: int, world: bool = false) -> PlayerData:
	var data := PlayerData.new()
	data.owned_items[Enums.PlayerItem.MEMORINA] = true
	var guardians: Array = Enums.Guardian.values()
	for guardian: int in guardians.slice(0, restored):
		data.restored_guardians[guardian] = true
	for number: int in range(1, seen + 1):
		data.scenes_seen.append(FlashbackSchedule.id(number))
	data.world_restored = world
	return data

## The waterfall's foot, in the region's (world) space.
func _waterfall() -> Vector2:
	var contents := (load(CONTENTS) as PackedScene).instantiate() as Node2D
	var foot := (contents.get_node("Marks/WaterfallFoot") as Node2D).position
	contents.free()
	return (_region.get_node("VillageGarden") as Node2D).position + foot + Vector2(0, -16)

## Memory at the waterfall: the region's level for `restored` plus the well's influence there.
func _memory(data: PlayerData) -> float:
	var memory := _region.get_node("Memory") as RegionMemory
	var baseline := 1.0 if data.world_restored else \
			RegionMemory.level_for(memory.authored, memory.steps, data.restored_guardians.count(true))
	var source := _source()
	var dist := MemoryFieldMath.source_distance(_waterfall() - source.position, source.extent(), source.shape)
	var influence := MemoryFieldMath.disc_influence(dist, source.effective_feather(), FactWell.strength_for(_well().levels, data))
	return MemoryFieldMath.combine(baseline, PackedFloat32Array([influence]))

func test_the_well_sits_beside_memory_not_under_it() -> void:
	assert_object(_source().get_parent()).is_same(_region)
	assert_object(_well().source).is_same(_source())

func test_the_well_covers_the_gardens_air() -> void:
	var garden := _region.get_node("VillageGarden") as Node2D
	var air := Rect2(garden.position + Vector2(32, 0), Vector2(1216, 640))
	var half := _source().rect_size * 0.5
	var core := Rect2(_source().position - half, half * 2.0)
	assert_bool(core.encloses(air)).override_failure_message("%s does not enclose %s" % [core, air]).is_true()
	assert_bool(core.has_point(_waterfall())).is_true()
	# The fade stops at the room's sides, so the trail beside it keeps its own memory.
	assert_float(core.position.x - _source().feather).is_greater_equal(garden.position.x)
	assert_float(core.end.x + _source().feather).is_less_equal(garden.position.x + 1280.0)

func test_the_waterfall_meets_the_targets_at_every_reachable_restored_count() -> void:
	for restored: int in range(0, Enums.Guardian.size() + 1):
		for seen: int in _reachable(restored):
			assert_float(_memory(_data(restored, seen))).override_failure_message("restored %d, seen %d" % [restored, seen]) \
					.is_equal_approx(TARGETS[seen], 0.001)

## Below AmbientMath.STOP_THRESHOLD the waterfall and flowers hold still: through the third flashback, never from the fourth.
func test_the_waterfall_moves_only_from_the_fourth_flashback() -> void:
	for restored: int in range(0, Enums.Guardian.size() + 1):
		for seen: int in _reachable(restored):
			var memory := _memory(_data(restored, seen))
			var message := "restored %d, seen %d: %f" % [restored, seen, memory]
			if seen <= 3:
				assert_float(memory).override_failure_message(message).is_less(AmbientMath.STOP_THRESHOLD)
			else:
				assert_float(memory).override_failure_message(message).is_greater_equal(AmbientMath.STOP_THRESHOLD)

func test_every_flashback_seen_brings_it_back() -> void:
	for restored: int in range(0, Enums.Guardian.size() + 1):
		var last := -1.0
		for seen: int in _reachable(restored):
			var now := _memory(_data(restored, seen))
			assert_float(now).override_failure_message("restored %d, seen %d" % [restored, seen]).is_greater(last)
			last = now

## STORY-07 revises STORY-05: a world restored before every flashback is seen keeps the garden's targets at 1.0.
func test_the_restored_world_meets_the_targets_until_all_five_are_seen() -> void:
	var last := -1.0
	for seen: int in range(0, FlashbackSchedule.COUNT):
		var data := _data(Enums.Guardian.size(), seen, true)
		var memory := _memory(data)
		assert_float(memory).override_failure_message("world restored, seen %d" % seen).is_equal_approx(TARGETS[seen], 0.001)
		if seen <= 3:
			assert_float(memory).is_less(AmbientMath.STOP_THRESHOLD)
		assert_float(memory).is_greater(last)
		last = memory

func test_the_restored_world_with_all_five_seen_hides_the_well() -> void:
	var data := _data(Enums.Guardian.size(), FlashbackSchedule.COUNT, true)
	assert_float(FactWell.strength_for(_well().levels, data)).is_equal(0.0)
	assert_float(_memory(data)).is_equal(1.0)

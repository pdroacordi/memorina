class_name GardenMemoryTest extends GdUnitTestSuite

## The garden's memory is the village baseline plus GardenWell, whose FactWell levels are derived from seen flashbacks
## (architecture/story-05-playable-flashbacks): grey with none seen, rising with every one seen, whole once the world is.

const REGION := "res://scenes/world/rooms/home_village.tscn"

var _region: Node2D


func before() -> void:
	_region = (load(REGION) as PackedScene).instantiate() as Node2D

func after() -> void:
	_region.free()

func _well() -> FactWell:
	return _region.get_node("GardenWell/FactWell") as FactWell

func _source() -> MemorySource:
	return _region.get_node("GardenWell") as MemorySource

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

## Memory inside the well's core: the region's level for `restored` plus the well's strength.
func _memory(data: PlayerData) -> float:
	var memory := _region.get_node("Memory") as RegionMemory
	var baseline := 1.0 if data.world_restored else \
			RegionMemory.level_for(memory.authored, memory.steps, data.restored_guardians.count(true))
	return MemoryFieldMath.combine(baseline, PackedFloat32Array([FactWell.strength_for(_well().levels, data)]))

func test_the_well_sits_beside_memory_not_under_it() -> void:
	assert_object(_source().get_parent()).is_same(_region)
	assert_object(_well().source).is_same(_source())

func test_the_well_covers_the_gardens_air() -> void:
	var garden := _region.get_node("VillageGarden") as Node2D
	var air := Rect2(garden.position + Vector2(32, 0), Vector2(1216, 288))
	var half := _source().rect_size * 0.5
	var core := Rect2(_source().position - half, half * 2.0)
	assert_bool(core.encloses(air)).override_failure_message("%s does not enclose %s" % [core, air]).is_true()
	# The fade stops at the room's sides, so the trail beside it keeps its own memory.
	assert_float(core.position.x - _source().feather).is_greater_equal(garden.position.x)
	assert_float(core.end.x + _source().feather).is_less_equal(garden.position.x + 1280.0)

func test_grey_and_still_with_none_seen() -> void:
	for restored: int in range(0, Enums.Guardian.size() + 1):
		assert_float(_memory(_data(restored, 0))).is_less(AmbientMath.STOP_THRESHOLD)
	assert_float(_memory(_data(0, 0))).is_equal(0.0)

func test_every_flashback_seen_brings_it_back() -> void:
	for restored: int in range(0, Enums.Guardian.size() + 1):
		var last := -1.0
		for seen: int in range(0, FlashbackSchedule.COUNT + 1):
			var now := _memory(_data(restored, seen))
			assert_float(now).override_failure_message("restored %d, seen %d" % [restored, seen]).is_greater(last)
			last = now

func test_the_restored_world_hides_the_well() -> void:
	for seen: int in range(0, FlashbackSchedule.COUNT + 1):
		var data := _data(Enums.Guardian.size(), seen, true)
		assert_float(FactWell.strength_for(_well().levels, data)).is_equal(0.0)
		assert_float(_memory(data)).is_equal(1.0)

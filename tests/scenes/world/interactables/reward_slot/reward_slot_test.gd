class_name RewardSlotTest extends GdUnitTestSuite

## A COLLECTIBLE slot with catalog content holds one FoundPickup; a CACHE or an unlisted slot holds none.

const SLOT := preload("res://scenes/world/interactables/reward_slot/reward_slot.tscn")


func before_test() -> void:
	SaveSystem.begin("", true)

func after_test() -> void:
	SaveSystem.begin("", true)

func _make(slot_id: StringName, kind: RewardSlot.Kind) -> RewardSlot:
	var slot := auto_free(SLOT.instantiate()) as RewardSlot
	slot.slot_id = slot_id
	slot.kind = kind
	add_child(slot)
	return slot

func test_a_listed_collectible_holds_its_piece() -> void:
	var slot := _make(&"woods_hut_letter", RewardSlot.Kind.COLLECTIBLE)
	assert_object(slot.content()).is_not_null()
	assert_str(String(slot.content().piece.slot_id)).is_equal("woods_hut_letter")
	assert_int(slot.get_child_count()).is_equal(1)

func test_the_life_note_slot_stays_empty() -> void:
	assert_object(_make(&"caldera_temple_sanctum", RewardSlot.Kind.COLLECTIBLE).content()).is_null()

func test_a_cache_stays_empty() -> void:
	assert_object(_make(&"woods_hut_letter", RewardSlot.Kind.CACHE).content()).is_null()

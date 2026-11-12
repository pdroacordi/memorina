class_name FlashbackSchedule
extends RefCounted
## Which flashback is due: one at a time, in order, each behind its gate (architecture/story-05-playable-flashbacks).

const COUNT := 5
## The SCENE_SEEN id of flashback n, recorded by its leaving scene.
const ID_FORMAT := "flashback_%d"


## The lowest unseen flashback whose gate holds, or 0 when none is due.
static func due(data: PlayerData) -> int:
	for number: int in range(1, COUNT + 1):
		if data.scenes_seen.has(id(number)):
			continue
		return number if _gate_holds(number, data) else 0
	return 0

static func seen_count(data: PlayerData) -> int:
	var seen := 0
	for number: int in range(1, COUNT + 1):
		if data.scenes_seen.has(id(number)):
			seen += 1
	return seen

static func id(number: int) -> StringName:
	return StringName(ID_FORMAT % number)

## Flashback 1 needs the Memorina; flashback n >= 2 needs n - 1 guardians restored.
static func _gate_holds(number: int, data: PlayerData) -> bool:
	if number == 1:
		return data.owned_items[Enums.PlayerItem.MEMORINA]
	return data.restored_guardians.count(true) >= number - 1

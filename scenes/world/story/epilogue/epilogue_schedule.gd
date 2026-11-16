class_name EpilogueSchedule
extends RefCounted
## When the epilogue is due and when the ending is over (architecture/story-07-epilogue).

const EPILOGUE_ID := &"epilogue"
const CREDITS_ID := &"credits"
const REUNION_ID := &"daughter_reunion"
## The bench the flat stone becomes once the credits are seen.
const BENCH_ID := &"garden_stone"


## The world is restored, every flashback seen, the reunion heard, and the epilogue not yet seen.
static func due(data: PlayerData) -> bool:
	return data.world_restored \
			and FlashbackSchedule.seen_count(data) == FlashbackSchedule.COUNT \
			and data.dialogues_heard.has(REUNION_ID) \
			and not data.scenes_seen.has(EPILOGUE_ID)

static func finished(data: PlayerData) -> bool:
	return data.scenes_seen.has(CREDITS_ID)

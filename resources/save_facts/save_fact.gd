class_name SaveFact
extends Resource
## One fact read from the save: a door's lock, a notebook entry's presence, a dialogue's gate
## (architecture/doors-and-interiors, architecture/dialogue-is-data-and-choices-are-save-facts).

## Append only: NotebookEntry and the dialogue resources store these as ints.
enum Kind {
	SKILL,
	SONG,
	ITEM,
	GUARDIAN_MET,
	GUARDIAN_RESTORED,
	ALL_GUARDIANS_RESTORED,
	## `index` guardians or more restored; the village's 0.6 step is 2 (RegionMemory.steps).
	GUARDIANS_RESTORED_AT_LEAST,
	## The dialogue `id` was heard to its end.
	DIALOGUE_HEARD,
	## The choice `id` is the answer recorded to its question.
	RESPONSE_CHOSEN,
}

@export var kind: Kind = Kind.ITEM
## Index into the PlayerData flag array `kind` names (an Enums.PlayerSkill, Song, PlayerItem or Guardian), or the count
## GUARDIANS_RESTORED_AT_LEAST needs; the other kinds ignore it.
@export var index: int = 0
## A dialogue id (DIALOGUE_HEARD) or a choice id (RESPONSE_CHOSEN); the other kinds ignore it.
@export var id: StringName = &""


func holds(data: PlayerData) -> bool:
	return check(kind, index, data, id)

## Every fact in `when` holds and none in `unless` does.
static func gates_pass(when: Array[SaveFact], unless: Array[SaveFact], data: PlayerData) -> bool:
	for fact: SaveFact in when:
		if not fact.holds(data):
			return false
	for fact: SaveFact in unless:
		if fact.holds(data):
			return false
	return true

static func check(fact_kind: Kind, fact_index: int, data: PlayerData, fact_id: StringName = &"") -> bool:
	match fact_kind:
		Kind.SKILL:
			return data.unlocked_player_skills[fact_index]
		Kind.SONG:
			return data.learned_songs[fact_index]
		Kind.ITEM:
			return data.owned_items[fact_index]
		Kind.GUARDIAN_MET:
			return data.met_guardians[fact_index] or data.restored_guardians[fact_index]
		Kind.GUARDIAN_RESTORED:
			return data.restored_guardians[fact_index]
		Kind.ALL_GUARDIANS_RESTORED:
			for guardian: int in Enums.Guardian.values():
				if not data.restored_guardians[guardian]:
					return false
			return true
		Kind.GUARDIANS_RESTORED_AT_LEAST:
			return data.restored_guardians.count(true) >= fact_index
		Kind.DIALOGUE_HEARD:
			return data.dialogues_heard.has(fact_id)
		Kind.RESPONSE_CHOSEN:
			return data.responses.values().has(fact_id)
	return false

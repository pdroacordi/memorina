class_name SaveFact
extends Resource
## One fact read from the save: a door's lock, a notebook entry's presence (architecture/doors-and-interiors).

## Append only: NotebookEntry stores these as ints.
enum Kind { SKILL, SONG, ITEM, GUARDIAN_MET, GUARDIAN_RESTORED, ALL_GUARDIANS_RESTORED }

@export var kind: Kind = Kind.ITEM
## Index into the PlayerData flag array `kind` names (an Enums.PlayerSkill, Song, PlayerItem or Guardian); ALL_GUARDIANS_RESTORED ignores it.
@export var index: int = 0


func holds(data: PlayerData) -> bool:
	return check(kind, index, data)

static func check(fact_kind: Kind, fact_index: int, data: PlayerData) -> bool:
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
	return false

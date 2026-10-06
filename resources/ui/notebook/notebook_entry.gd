class_name NotebookEntry
extends Resource
## One notebook entry; whether it is present is derived from the save (architecture/notebook-entries-are-derived-from-the-save).

enum Section { LORE, SONGS, ITEMS, GUARDIANS }
## The save fact that makes the entry present; `index` names the flag.
enum Requirement { SKILL, SONG, ITEM, GUARDIAN_MET, GUARDIAN_RESTORED }

@export var id: StringName = &""
@export var section: Section = Section.LORE
@export var requirement: Requirement = Requirement.SKILL
## Index into the PlayerData flag array the requirement names (an Enums.PlayerSkill, Song, PlayerItem or Guardian).
@export var index: int = 0
@export var title_key: String = ""
## Translation key of the line under the title (a song's season and material); empty for none.
@export var detail_key: String = ""
@export var body_key: String = ""
## A guardian's portrait; null for none.
@export var art: Texture2D


func is_present(data: PlayerData) -> bool:
	match requirement:
		Requirement.SKILL:
			return data.unlocked_player_skills[index]
		Requirement.SONG:
			return data.learned_songs[index]
		Requirement.ITEM:
			return data.owned_items[index]
		Requirement.GUARDIAN_MET:
			return data.met_guardians[index] or data.restored_guardians[index]
		Requirement.GUARDIAN_RESTORED:
			return data.restored_guardians[index]
	return false

## Every translation key the entry names.
func keys() -> PackedStringArray:
	var found := PackedStringArray()
	for key: String in [title_key, detail_key, body_key]:
		if not key.is_empty():
			found.append(key)
	return found

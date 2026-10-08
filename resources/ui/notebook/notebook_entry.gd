class_name NotebookEntry
extends Resource
## One notebook entry; whether it is present is derived from the save (architecture/notebook-entries-are-derived-from-the-save).

enum Section { LORE, SONGS, ITEMS, GUARDIANS }

@export var id: StringName = &""
@export var section: Section = Section.LORE
## The save fact that makes the entry present; `index` names the flag.
@export var requirement: SaveFact.Kind = SaveFact.Kind.SKILL
## Index into the PlayerData flag array the requirement names (an Enums.PlayerSkill, Song, PlayerItem or Guardian).
@export var index: int = 0
@export var title_key: String = ""
## Translation key of the line under the title (a song's season and material); empty for none.
@export var detail_key: String = ""
@export var body_key: String = ""
## A guardian's portrait; null for none.
@export var art: Texture2D


func is_present(data: PlayerData) -> bool:
	return SaveFact.check(requirement, index, data)

## Every translation key the entry names.
func keys() -> PackedStringArray:
	var found := PackedStringArray()
	for key: String in [title_key, detail_key, body_key]:
		if not key.is_empty():
			found.append(key)
	return found

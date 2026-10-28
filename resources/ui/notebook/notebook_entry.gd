class_name NotebookEntry
extends Resource
## One notebook entry; whether it is present is derived from the save (architecture/notebook-entries-are-derived-from-the-save).

enum Section { LORE, SONGS, ITEMS, GUARDIANS }

## A half-known song's title and bodies, shared by the four songs learned in halves (architecture/half-songs).
const HALF_TITLE_KEY := "NOTEBOOK_SONG_HALF_TITLE"
const FIRST_HALF_BODY_KEY := "NOTEBOOK_SONG_FIRST_HALF_BODY"
const SECOND_HALF_BODY_KEY := "NOTEBOOK_SONG_SECOND_HALF_BODY"

@export var id: StringName = &""
@export var section: Section = Section.LORE
## The save fact that makes the entry present; `index` names the flag.
@export var requirement: SaveFact.Kind = SaveFact.Kind.SKILL
## Index into the PlayerData flag array the requirement names (an Enums.PlayerSkill, Song, PlayerItem or Guardian).
@export var index: int = 0
## The dialogue (DIALOGUE_HEARD) or choice (RESPONSE_CHOSEN) id the requirement reads; empty for the other kinds.
@export var fact_id: StringName = &""
@export var title_key: String = ""
## Translation key of the line under the title (a song's season and material); empty for none.
@export var detail_key: String = ""
@export var body_key: String = ""
## A guardian's portrait; null for none.
@export var art: Texture2D
## An item's icon, 16x16 art px; the item notice draws it (systems/notices). Null outside the Items section.
@export var icon: Texture2D
## A song learned by ear: the body in Ivo's voice, and the margin line once the guessed half is found. Empty on other entries.
@export var ear_body_key: String = ""
@export var ear_margin_key: String = ""


func is_present(data: PlayerData) -> bool:
	return SaveFact.check(requirement, index, data, fact_id)

## How far a song entry is known; LEARNED for every other entry.
func song_state(data: PlayerData) -> SongHalves.State:
	if requirement != SaveFact.Kind.SONG_PART_KNOWN:
		return SongHalves.State.LEARNED
	return SongHalves.state(data, index)

## The id read and announced: a song's page changes as it is completed, so each state reads as new.
func page_id(data: PlayerData) -> StringName:
	match song_state(data):
		SongHalves.State.FIRST_HALF:
			return StringName("%s@first" % id)
		SongHalves.State.SECOND_HALF:
			return StringName("%s@second" % id)
		SongHalves.State.BY_EAR:
			return StringName("%s@ear" % id)
		SongHalves.State.BY_EAR_CONFIRMED:
			return StringName("%s@confirmed" % id)
	return id

## The body as `data` knows the entry.
func body_key_for(data: PlayerData) -> String:
	match song_state(data):
		SongHalves.State.FIRST_HALF:
			return FIRST_HALF_BODY_KEY
		SongHalves.State.SECOND_HALF:
			return SECOND_HALF_BODY_KEY
		SongHalves.State.BY_EAR:
			return ear_body_key
	return body_key

## Every translation key the entry names.
func keys() -> PackedStringArray:
	var found := PackedStringArray()
	for key: String in [title_key, detail_key, body_key, ear_body_key, ear_margin_key]:
		if not key.is_empty():
			found.append(key)
	return found

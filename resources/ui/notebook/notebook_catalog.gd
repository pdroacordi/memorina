class_name NotebookCatalog
extends Resource
## Every notebook entry in display (story) order.

## The requirement every entry of a section must use; LORE takes any.
const SECTION_REQUIREMENT: Dictionary[NotebookEntry.Section, NotebookEntry.Requirement] = {
	NotebookEntry.Section.SONGS: NotebookEntry.Requirement.SONG,
	NotebookEntry.Section.ITEMS: NotebookEntry.Requirement.ITEM,
	NotebookEntry.Section.GUARDIANS: NotebookEntry.Requirement.GUARDIAN_MET,
}

@export var entries: Array[NotebookEntry] = []


func get_entry(id: StringName) -> NotebookEntry:
	for entry: NotebookEntry in entries:
		if entry.id == id:
			return entry
	return null

func in_section(section: NotebookEntry.Section) -> Array[NotebookEntry]:
	var found: Array[NotebookEntry] = []
	for entry: NotebookEntry in entries:
		if entry.section == section:
			found.append(entry)
	return found

## The problems found, one line each; empty when the catalog is sound.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	var ids: Dictionary[StringName, bool] = {}
	for entry: NotebookEntry in entries:
		if entry == null:
			problems.append("an empty slot")
			continue
		if entry.id == &"" or ids.has(entry.id):
			problems.append("id '%s' is empty or not unique" % entry.id)
		ids[entry.id] = true
		if SECTION_REQUIREMENT.has(entry.section) and SECTION_REQUIREMENT[entry.section] != entry.requirement:
			problems.append("%s: section %d needs requirement %d" % [entry.id, entry.section, SECTION_REQUIREMENT[entry.section]])
		if entry.title_key.is_empty() or entry.body_key.is_empty():
			problems.append("%s has no title or body key" % entry.id)
	problems.append_array(_one_per(NotebookEntry.Section.SONGS, Enums.Song.size()))
	problems.append_array(_one_per(NotebookEntry.Section.ITEMS, Enums.PlayerItem.size()))
	problems.append_array(_one_per(NotebookEntry.Section.GUARDIANS, Enums.Guardian.size()))
	return problems

func _one_per(section: NotebookEntry.Section, count: int) -> PackedStringArray:
	var problems := PackedStringArray()
	var indices: Array[int] = []
	for entry: NotebookEntry in in_section(section):
		indices.append(entry.index)
	for i: int in count:
		if indices.count(i) != 1:
			problems.append("section %d has %d entries for index %d, not 1" % [section, indices.count(i), i])
	if indices.size() != count:
		problems.append("section %d has %d entries for %d members" % [section, indices.size(), count])
	return problems

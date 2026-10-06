class_name NotebookIndex
extends RefCounted
## Pure queries over a NotebookCatalog and a save: which entries are present, unread and new.


## Ids of the present entries, in catalog order.
static func present(catalog: NotebookCatalog, data: PlayerData) -> Array[StringName]:
	var ids: Array[StringName] = []
	for entry: NotebookEntry in catalog.entries:
		if entry.is_present(data):
			ids.append(entry.id)
	return ids

## Present entries the player has not read, in catalog order.
static func unread(catalog: NotebookCatalog, data: PlayerData) -> Array[StringName]:
	var ids: Array[StringName] = []
	for id: StringName in present(catalog, data):
		if not data.notebook_read.has(id):
			ids.append(id)
	return ids

## Ids in `after` that were not in `before`, in the order of `after`.
static func added(before: Array[StringName], after: Array[StringName]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for id: StringName in after:
		if not before.has(id):
			ids.append(id)
	return ids

static func section_unread(catalog: NotebookCatalog, data: PlayerData, section: NotebookEntry.Section) -> bool:
	for id: StringName in unread(catalog, data):
		if catalog.get_entry(id).section == section:
			return true
	return false

## The unread entry found last this session (`recent`, oldest first), else the last unread in catalog order; empty when none.
static func newest_unread(catalog: NotebookCatalog, data: PlayerData, recent: Array[StringName]) -> StringName:
	var waiting := unread(catalog, data)
	for i: int in range(recent.size() - 1, -1, -1):
		if waiting.has(recent[i]):
			return recent[i]
	return waiting.back() if not waiting.is_empty() else &""

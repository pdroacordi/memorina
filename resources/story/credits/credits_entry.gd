class_name CreditsEntry
extends Resource
## A role and the names under it; names are proper nouns and never translated.

## A translation key; empty shows the names alone.
@export var role_key: StringName = &""
@export var names: PackedStringArray = PackedStringArray()


## The rows shown under the role, top to bottom, untranslated.
func lines() -> PackedStringArray:
	return names

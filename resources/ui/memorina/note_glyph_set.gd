class_name NoteGlyphSet extends Resource

## Normal and selected textures for each note and input glyph set.

## Textures indexed by Enums.Note.
@export var normal: Array[Texture2D] = []
## Selected textures indexed by Enums.Note.
@export var selected: Array[Texture2D] = []

func texture(note: Enums.Note, lit: bool) -> Texture2D:
	return selected[note] if lit else normal[note]

## Debug-only integrity check: every note must have both textures.
func validate() -> void:
	assert(normal.size() == Enums.Note.size(),
		"NoteGlyphSet '%s' has %d normal textures for %d notes." % [resource_path, normal.size(), Enums.Note.size()])
	assert(selected.size() == Enums.Note.size(),
		"NoteGlyphSet '%s' has %d selected textures for %d notes." % [resource_path, selected.size(), Enums.Note.size()])
	for i: int in Enums.Note.size():
		assert(normal[i] != null and selected[i] != null,
			"NoteGlyphSet '%s' is missing a texture for note %d." % [resource_path, i])

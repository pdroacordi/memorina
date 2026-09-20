class_name NoteGlyphSet extends Resource

## The icons one input device draws on the sheet: a normal and a lit texture
## per Enums.Note. One .tres per Enums.GlyphSet; MemorinaHud picks the set
## from the glyph the press arrived with and never looks at textures itself.

## Indexed by Enums.Note.
@export var normal: Array[Texture2D] = []
## Indexed by Enums.Note. Shown while a performance replays the note.
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

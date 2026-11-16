class_name CreditsLicence
extends CreditsEntry
## The engine's licence notice, read at runtime and never translated (architecture/story-07-epilogue, decision 12).


## One row per paragraph of the engine's licence text.
func lines() -> PackedStringArray:
	return paragraphs(Engine.get_license_text())

## `text`'s paragraphs, each hard-wrapped line joined to the one before by a space; a line opening with "Copyright"
## starts a row of its own.
static func paragraphs(text: String) -> PackedStringArray:
	var rows := PackedStringArray()
	for paragraph: String in text.strip_edges().replace("\r\n", "\n").split("\n\n", false):
		var row := ""
		for line: String in paragraph.split("\n", false):
			var piece := line.strip_edges()
			if row.is_empty():
				row = piece
			elif piece.begins_with("Copyright"):
				rows.append(row)
				row = piece
			else:
				row += " " + piece
		if not row.is_empty():
			rows.append(row)
	return rows

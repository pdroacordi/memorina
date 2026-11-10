extends SceneTree

## Builds resources/ui/memorina/note_glyphs.tres from assets/sprites/hud/memorina/; rerun after adding a note glyph.

const DIR := "res://assets/sprites/hud/memorina"
const OUT := "res://resources/ui/memorina/note_glyphs.tres"

const KEYS := {
	KEY_UP: "input_key_up", KEY_DOWN: "input_key_down", KEY_LEFT: "input_key_left", KEY_RIGHT: "input_key_right",
	KEY_W: "input_key_w", KEY_A: "input_key_a", KEY_S: "input_key_s", KEY_D: "input_key_d",
}
const XBOX_BUTTONS := {
	JOY_BUTTON_A: "input_xbox_a", JOY_BUTTON_B: "input_xbox_b", JOY_BUTTON_X: "input_xbox_x", JOY_BUTTON_Y: "input_xbox_y",
}
const PLAYSTATION_BUTTONS := {
	JOY_BUTTON_A: "input_ps_x", JOY_BUTTON_B: "input_ps_circle", JOY_BUTTON_X: "input_ps_square",
	JOY_BUTTON_Y: "input_ps_triangle",
}
const BLANK := "input_key_blank"

func _init() -> void:
	var glyphs := NoteGlyphs.new()
	glyphs.keys = _table(KEYS)
	glyphs.xbox_buttons = _table(XBOX_BUTTONS)
	glyphs.playstation_buttons = _table(PLAYSTATION_BUTTONS)
	glyphs.blank = _glyph(BLANK)
	var err := ResourceSaver.save(glyphs, OUT)
	if err != OK:
		push_error("Could not save %s: %s" % [OUT, error_string(err)])
	else:
		print("Wrote ", OUT)
	quit()

func _table(names: Dictionary) -> Dictionary[int, ButtonGlyph]:
	var table: Dictionary[int, ButtonGlyph] = {}
	for code: int in names:
		table[code] = _glyph(names[code])
	return table

## Note art has no pressed state; a note shows normal or selected (lit).
func _glyph(art: String) -> ButtonGlyph:
	var glyph := ButtonGlyph.new()
	glyph.normal = load("%s/%s_normal.png" % [DIR, art])
	glyph.selected = load("%s/%s_selected.png" % [DIR, art])
	assert(glyph.normal != null and glyph.selected != null, "missing note glyph art for %s" % art)
	return glyph

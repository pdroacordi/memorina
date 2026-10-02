extends SceneTree

## Builds resources/ui/input/input_glyphs.tres from assets/sprites/hud/input/; rerun after adding a glyph or binding.

const DIR := "res://assets/sprites/hud/input"
const OUT := "res://resources/ui/input/input_glyphs.tres"

const KEYS := {
	KEY_UP: "key_up", KEY_DOWN: "key_down", KEY_LEFT: "key_left", KEY_RIGHT: "key_right",
	KEY_W: "key_w", KEY_A: "key_a", KEY_S: "key_s", KEY_D: "key_d",
}
const PAD_BUTTONS := {
	JOY_BUTTON_DPAD_UP: "dpad_up", JOY_BUTTON_DPAD_DOWN: "dpad_down",
	JOY_BUTTON_DPAD_LEFT: "dpad_left", JOY_BUTTON_DPAD_RIGHT: "dpad_right",
}
const XBOX_BUTTONS := {
	JOY_BUTTON_A: "xbox_a", JOY_BUTTON_B: "xbox_b", JOY_BUTTON_X: "xbox_x", JOY_BUTTON_Y: "xbox_y",
	JOY_BUTTON_LEFT_SHOULDER: "xbox_lb", JOY_BUTTON_RIGHT_SHOULDER: "xbox_rb",
}
const PLAYSTATION_BUTTONS := {
	JOY_BUTTON_A: "ps_cross", JOY_BUTTON_B: "ps_circle", JOY_BUTTON_X: "ps_square", JOY_BUTTON_Y: "ps_triangle",
	JOY_BUTTON_LEFT_SHOULDER: "ps_l1", JOY_BUTTON_RIGHT_SHOULDER: "ps_r1",
}
const LEFT_STICK := {
	0: "stick_left_left", 1: "stick_left_right", 2: "stick_left_up", 3: "stick_left_down",
}

func _init() -> void:
	var glyphs := InputGlyphs.new()
	glyphs.keys = _table(KEYS)
	glyphs.pad_buttons = _table(PAD_BUTTONS)
	glyphs.xbox_buttons = _table(XBOX_BUTTONS)
	glyphs.playstation_buttons = _table(PLAYSTATION_BUTTONS)
	glyphs.left_stick = _table(LEFT_STICK)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	var err := ResourceSaver.save(glyphs, OUT)
	if err != OK:
		push_error("Could not save %s: %s" % [OUT, error_string(err)])
	else:
		print("Wrote ", OUT)
	quit()

func _table(names: Dictionary) -> Dictionary[int, ButtonGlyph]:
	var table: Dictionary[int, ButtonGlyph] = {}
	for code: int in names:
		var glyph := ButtonGlyph.new()
		glyph.normal = load("%s/%s_normal.png" % [DIR, names[code]])
		glyph.selected = load("%s/%s_selected.png" % [DIR, names[code]])
		glyph.pressed = load("%s/%s_pressed.png" % [DIR, names[code]])
		assert(glyph.normal != null and glyph.selected != null and glyph.pressed != null, "missing glyph art for %s" % names[code])
		table[code] = glyph
	return table

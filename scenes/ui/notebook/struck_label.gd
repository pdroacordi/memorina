class_name StruckLabel extends Label

## A one-line label crossed out by a 1 px line in its font colour: Ivo's name under a song's real one (architecture/half-songs).

# Clipped: a one-line label's minimum width is its whole string, which would widen the page's column.
func _ready() -> void:
	autowrap_mode = TextServer.AUTOWRAP_OFF
	clip_text = true

func _draw() -> void:
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	var width := minf(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x, size.x)
	var y := roundf(size.y / 2.0)
	draw_line(Vector2(0.0, y), Vector2(width, y), get_theme_color("font_color"), 1.0)

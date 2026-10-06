shader_type canvas_item;

// The title's woods are forgotten: every pixel in the print, none remembered.

#include "res://scenes/world/memory/greyhush_print.gdshaderinc"

void fragment() {
	COLOR.rgb = gh_print(COLOR.rgb);
}

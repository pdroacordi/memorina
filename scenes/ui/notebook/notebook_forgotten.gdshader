shader_type canvas_item;

// A corrupted guardian's portrait, in the forgotten print (systems/greyhush).

#include "res://scenes/world/memory/greyhush_print.gdshaderinc"

void fragment() {
	COLOR.rgb = gh_print(COLOR.rgb);
}

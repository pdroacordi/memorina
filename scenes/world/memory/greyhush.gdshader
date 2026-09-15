shader_type canvas_item;

// The WORLD pass. Drains everything the main viewport drew - background,
// tilemap, props - to whatever the memory field says. Creatures are culled out
// of this pass and composited back by greyhush_creatures.gdshader.
//
// All of the actual work lives in the include, so the two passes cannot drift.
#include "res://scenes/world/memory/greyhush_common.gdshaderinc"

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

void fragment() {
	vec2 px = UV * game_size;
	vec3 screen = texture(screen_texture, SCREEN_UV).rgb;

	vec3 tint_rgb;
	float tint_amount;
	float memory = gh_memory(px, tint_rgb, tint_amount);
	float lit_amount = gh_quantise(memory, px);

	vec3 col = gh_shade(screen, lit_amount, tint_rgb, tint_amount);
	col = gh_vignette(col, UV, lit_amount);

	COLOR = vec4(col, 1.0);
}

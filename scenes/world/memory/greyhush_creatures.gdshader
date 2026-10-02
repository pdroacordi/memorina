shader_type canvas_item;
// The transparent SubViewport output is premultiplied; keep this blend mode to avoid dark sprite edges.
render_mode blend_premul_alpha;

// Draws CreatureMask's isolated creature render over the drained world.

//
// Must match the world pass through the shared include; preserve alpha so transparent areas do not cover the world.
#include "res://scenes/world/memory/greyhush_common.gdshaderinc"

void fragment() {
	vec2 px = UV * game_size;
	vec4 src = texture(TEXTURE, UV);

	// Preserve empty pixels and premultiplied edges.
	if (src.a <= 0.001) {
		COLOR = vec4(0.0);
	} else {
		// Unpremultiply before shading so edge coverage does not darken the colour.
		vec3 straight = src.rgb / max(src.a, 0.0001);

		vec3 tint_rgb;
		float tint_amount;
		float ring;
		float smooth_memory;
		float memory = gh_memory(px, smooth_memory, tint_rgb, tint_amount, ring);
		float lit_amount = gh_quantise(memory, px);

		vec3 col = gh_shade(straight, lit_amount, smooth_memory, tint_rgb, tint_amount, ring, px);
		col = gh_vignette(col, UV, smooth_memory);

		// Match blend_premul_alpha.
		COLOR = vec4(col * src.a, src.a);
	}
}

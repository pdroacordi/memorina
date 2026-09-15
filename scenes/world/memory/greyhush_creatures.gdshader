shader_type canvas_item;
// A SubViewport with transparent_bg outputs PREMULTIPLIED alpha. Blending it as
// straight alpha multiplies the edge pixels by their coverage a second time,
// which draws a dark rim around every sprite - the "shadow" effect.
render_mode blend_premul_alpha;

// The CREATURE pass. Draws the isolated creature render - produced by
// CreatureMask, a SubViewport that shares the world but renders only the
// creature visibility layer - back over the drained world.

//
// Identical maths to the world pass, via the shared include, so a creature and
// the ground under its feet always agree on how forgotten this spot is. The one
// difference is alpha: this pass must preserve it, or the transparent space
// around the creatures would paint over the world.
#include "res://scenes/world/memory/greyhush_common.gdshaderinc"

void fragment() {
	vec2 px = UV * game_size;
	vec4 src = texture(TEXTURE, UV);

	// Nothing to shade where no creature was drawn. Returning early also keeps
	// the premultiplied edge pixels from being dragged toward the haze colour.
	if (src.a <= 0.001) {
		COLOR = vec4(0.0);
	} else {
		// Undo the premultiply before shading, or a half-covered edge pixel
		// would be desaturated as if it were a darker colour than it is.
		vec3 straight = src.rgb / max(src.a, 0.0001);

		vec3 tint_rgb;
		float tint_amount;
		float memory = gh_memory(px, tint_rgb, tint_amount);
		float lit_amount = gh_quantise(memory, px);

		vec3 col = gh_shade(straight, lit_amount, tint_rgb, tint_amount);
		col = gh_vignette(col, UV, lit_amount);

		// Re-premultiply to match blend_premul_alpha.
		COLOR = vec4(col * src.a, src.a);
	}
}

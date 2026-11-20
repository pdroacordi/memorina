shader_type canvas_item;
// The transparent SubViewport output is premultiplied; keep this blend mode to avoid dark sprite edges.
render_mode blend_premul_alpha;

// Draws a CanvasPass's isolated render (the creatures, or the foreground) over the drained world.

//
// Must match the world pass through the shared include; preserve alpha so transparent areas do not cover the world.
#include "res://scenes/world/memory/greyhush_common.gdshaderinc"
#include "res://scenes/world/memory/unshielded_mark.gdshaderinc"
#include "res://scenes/world/memory/self_lit_mark.gdshaderinc"

// A corrupted creature in the grey is drawn as ink, so it reads against the drained world (CORE-14): its
// luma 0..1 maps between these two values, by how forgotten its pixel is.
uniform vec3 creature_ink_dark : source_color = vec3(0.07, 0.07, 0.09);
uniform vec3 creature_ink_light : source_color = vec3(0.36, 0.36, 0.40);

void fragment() {
	vec2 px = UV * game_size;
	vec4 src = texture(TEXTURE, UV);

	// Preserve empty pixels and premultiplied edges.
	if (src.a <= 0.001) {
		COLOR = vec4(0.0);
	} else {
		// Unpremultiply before shading so edge coverage does not darken the colour.
		vec3 straight = src.rgb / max(src.a, 0.0001);
		// A corrupted creature's pixel: greyed by the field only, and fully opaque.
		bool unshielded = gh_is_unshielded(src.a);
		// A guardian's spawned attack: never greyed, and fully opaque.
		bool self_lit = gh_is_self_lit(src.a);
		float cover = unshielded || self_lit ? 1.0 : src.a;

		vec3 tint_rgb;
		float tint_amount;
		float ring;
		float smooth_memory;
		float memory = gh_memory_weighted(px, unshielded ? 0.0 : 1.0, smooth_memory, tint_rgb, tint_amount, ring);
		if (self_lit) {
			memory = 1.0;
			smooth_memory = 1.0;
		}
		float lit_amount = gh_quantise(memory, px);

		vec3 col = gh_shade(straight, lit_amount, smooth_memory, tint_rgb, tint_amount, ring, px);
		if (unshielded) {
			// Quantised like the colour edge, so a pulse over a creature dithers ink into colour.
			float luma = dot(straight, vec3(0.299, 0.587, 0.114));
			col = mix(mix(creature_ink_dark, creature_ink_light, luma), col, lit_amount);
		}
		col = gh_vignette(col, UV, smooth_memory);

		// Match blend_premul_alpha.
		COLOR = vec4(col * cover, cover);
	}
}

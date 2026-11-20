shader_type canvas_item;
// Written as-is: blend_mix would accumulate alpha where the spawn draws over its own pixels and lose the mark
// (gotchas/canvas-blend-mix-accumulates-alpha-so-an-overdrawn-alpha-mark-is-lost).
render_mode blend_disabled;

// A guardian's spawned attack keeps its guardian's colour: every pixel it draws carries the self-lit mark.

#include "res://scenes/world/memory/self_lit_mark.gdshaderinc"

void fragment() {
	// COLOR arrives as the vertex colour times the texture.
	if (COLOR.a < 0.5) {
		discard;
	}
	// Premultiplied, as blend_mix leaves the transparent pass and the creature composite reads it.
	COLOR = vec4(COLOR.rgb * GH_SELF_LIT_ALPHA, GH_SELF_LIT_ALPHA);
}

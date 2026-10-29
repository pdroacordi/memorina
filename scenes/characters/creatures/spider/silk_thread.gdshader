shader_type canvas_item;

// A spider's silk thread: gaps open along it in art pixels of its own local space (tied to the anchor), re-rolled on
// greyhush_time like the corruption edge (docs/knowledge/systems/creatures.md).

#include "res://scenes/world/memory/dither_common.gdshaderinc"
#include "res://scenes/world/memory/unshielded_mark.gdshaderinc"

global uniform float greyhush_time;

// Share of the thread's art pixels missing at any time, 0..1.
uniform float fray : hint_range(0.0, 1.0) = 0.2;
// Seconds of greyhush_time between re-rolls; matches corruption_edge.gdshaderinc.
uniform float reroll_period = 0.25;
// Game px per art pixel.
uniform float art_scale = 2.0;

varying vec2 v_local;

void vertex() {
	v_local = VERTEX;
}

void fragment() {
	float art_y = floor(v_local.y / art_scale);
	float epoch = floor(greyhush_time / reroll_period);
	vec4 shaded = COLOR;
	if (wd_hash11(art_y * 13.7 + epoch * 3.1) < fray) {
		shaded.a = 0.0;
	} else if (shaded.a >= 0.5) {
		// No GreyhushShield lights a corrupted creature's thread either.
		shaded.a = GH_UNSHIELDED_ALPHA;
	}
	COLOR = shaded;
}

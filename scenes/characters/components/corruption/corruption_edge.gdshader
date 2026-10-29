shader_type canvas_item;

// A corrupted creature's sprite; CorruptionEdge writes the uniforms.

#include "res://scenes/characters/components/corruption/corruption_edge.gdshaderinc"
#include "res://scenes/world/memory/unshielded_mark.gdshaderinc"

// The vertex colour carries the node's modulate (Character.flash).
varying vec4 v_modulate;

void vertex() {
	v_modulate = COLOR;
}

void fragment() {
	vec2 texel = floor(UV / TEXTURE_PIXEL_SIZE);
	vec2 origin = ce_frame_origin(texel);
	vec2 art = floor((texel - origin) / art_scale);
	float epoch = ce_epoch();
	vec4 base = texture(TEXTURE, UV);
	vec4 shaded = vec4(0.0);
	if (base.a >= 0.5) {
		if (!ce_deserts(CE_EDGE(origin, art), ce_threshold(art, epoch))) {
			shaded = base * v_modulate;
		}
	} else {
		// A transparent pixel may carry an edge pixel 1..3 art px behind it along the drift.
		vec2 stride = round(drift);
		for (int k = 1; k <= 3; k++) {
			vec2 source = art - stride * float(k);
			if (CE_EDGE(origin, source) > 0.0 && ce_strays(source, k, epoch)) {
				shaded = CE_COLOUR(origin, source) * v_modulate;
				break;
			}
		}
	}
	// No GreyhushShield lights a corrupted creature: the creature composite reads this alpha.
	if (shaded.a >= 0.5) {
		shaded.a = GH_UNSHIELDED_ALPHA;
	}
	COLOR = shaded;
}

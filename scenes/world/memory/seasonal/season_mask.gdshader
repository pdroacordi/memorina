shader_type canvas_item;

// R is (season + 1) / 255 or 0 for none; G is smooth memory for seasonal_common.gdshaderinc.
#include "res://scenes/world/memory/greyhush_common.gdshaderinc"

void fragment() {
	vec2 px = UV * game_size;

	float best = 0.0;
	float season = -1.0;
	for (int i = 0; i < source_count; i++) {
		if (source_seasons[i] < 0.0) {
			continue;
		}
		float dist;
		float influence = gh_source_influence(i, px, true, dist);
		if (influence > best) {
			best = influence;
			season = source_seasons[i];
		}
	}

	// Must use strict greater, matching gh_quantise() because BAYER[0] is zero.
	bool swapped = season >= 0.0 && best > BAYER[gh_bayer_index(px)];

	COLOR = vec4(swapped ? (season + 1.0) / 255.0 : 0.0, gh_smooth_memory(px), 0.0, 1.0);
}

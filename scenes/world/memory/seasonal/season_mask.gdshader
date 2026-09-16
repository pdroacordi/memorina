shader_type canvas_item;

// The SEASON MASK pass. Rendered by SeasonMask (a 640x360 SubViewport) into a
// texture every world material can read as a global uniform, so the field is
// evaluated ONCE per frame for the art swap instead of once per sprite.
//
// Each pixel answers one question: which pulse's season owns this pixel? The
// pulse with the strongest influence here wins, and the same 4x4 Bayer that
// dithers the colour decides whether a pixel in its feather rounds to "swapped"
// or "not" - so the snow's ragged edge is the greyhush's ragged edge.
//
// Encoding: R = (Enums.Season + 1) / 255, or 0 for "no pulse season here";
// G = the memory, SMOOTH (the clean disc, no sector bite), so a world material can react to how forgotten its
// pixel is (distance dissolving into the haze) without evaluating the field
// itself. Deliberately not quantised: the colour pass dithers the same pixels
// with the same Bayer cell, and dithering twice compounds - every pixel that
// rounds up gets less haze from both passes and pops out as a bright square.
// Read back with gh_season_at() and gh_forgotten_at() in
// seasonal_common.gdshaderinc.
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

	// STRICTLY greater, for the same reason as gh_quantise(): BAYER[0] is 0.
	bool swapped = season >= 0.0 && best > BAYER[gh_bayer_index(px)];

	COLOR = vec4(swapped ? (season + 1.0) / 255.0 : 0.0, gh_smooth_memory(px), 0.0, 1.0);
}

shader_type canvas_item;

// R is (season + 1) / 255 or 0 for none; G is smooth memory for seasonal_common.gdshaderinc.
#include "res://scenes/world/memory/greyhush_common.gdshaderinc"

// A region's year (RegionYear, from GreyhushRenderer): pixels no pulse swapped take the next season where the turn
// passes their Bayer cell (architecture/story-07-epilogue).
global uniform int greyhush_region_season_next;
global uniform float greyhush_season_turn;
// The canvas origin in game pixels, rounded, so the turn's cells follow the world as the camera moves.
uniform vec2 turn_origin = vec2(0.0);

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
	bool turned = !swapped && greyhush_season_turn > BAYER[gh_bayer_index(floor(px - turn_origin))];
	float code = swapped ? season + 1.0 : (turned ? float(greyhush_region_season_next) + 1.0 : 0.0);

	COLOR = vec4(code / 255.0, gh_smooth_memory(px), 0.0, 1.0);
}

shader_type canvas_item;

// Pulse particles appear inside their season mask; ambient weather appears outside masks and inside same-season masks.
#include "res://scenes/world/memory/seasonal/seasonal_common.gdshaderinc"

// Enums.Season these particles belong to.
uniform int season = 0;
// True for a region's weather rather than a pulse's particles.
uniform bool ambient = false;

void fragment() {
	// COLOR already carries the texel times the particle's colour; only the
	// clip is ours.
	int here = gh_season_at(SCREEN_UV);
	bool inside = ambient ? (here < 0 || here == season) : (here == season);
	if (!inside) {
		discard;
	}
}

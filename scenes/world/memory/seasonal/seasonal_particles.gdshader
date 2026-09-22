shader_type canvas_item;

// Particles that belong to one season. A pulse's particles survive only where
// the season mask says that season has swapped the art, so snow falls exactly
// where the snow tiles are - inside the pulse, out to its ragged edge, and
// retreating with it - and never inside another season's pulse. A region's
// own weather (ambient) is the reverse: it lives wherever NO pulse has swapped
// the art, and inside pulses of its own season, and is cut only by a pulse of
// another season.
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

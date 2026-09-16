shader_type canvas_item;

// Particles that belong to one season's pulse. A fragment survives only where
// the season mask says that season has swapped the art, so snow falls exactly
// where the snow tiles are - inside the pulse, out to its ragged edge, and
// retreating with it - and never inside another season's pulse.
#include "res://scenes/world/memory/seasonal/seasonal_common.gdshaderinc"

// Enums.Season these particles belong to.
uniform int season = 0;

void fragment() {
	// COLOR already carries the texel times the particle's colour; only the
	// clip is ours.
	if (gh_season_at(SCREEN_UV) != season) {
		discard;
	}
}

shader_type canvas_item;

// Seasonal sheets use vertically stacked bands; band order is configured per material.
// fract(UV.y) keeps repeated textures inside one band; each band must span whole tile rows.
#include "res://scenes/world/memory/seasonal/seasonal_common.gdshaderinc"

// How many equal bands the sheet is stacked into.
uniform int band_count : hint_range(1, 8) = 1;
// Band index for each Enums.Season, in enum order: WINTER, SUMMER, AUTUMN,
// SPRING. A season without its own art points at the band that stands in for
// it (summer -> spring's band, by design decision).
uniform ivec4 band_of_season = ivec4(0);
// How far away this drawable is, 0 (the ground under Ivo's feet) to 1 (the
// sky). Where the world is forgotten, distance dissolves into the haze in
// proportion, so a dead place loses its horizon before it loses its floor.
uniform float distance : hint_range(0.0, 1.0) = 0.0;

// Preserve vertex modulate separately because fragment COLOR already includes the band-0 texture.
varying vec4 modulate;

void vertex() {
	modulate = COLOR;
}

// Keep explicit components because runtime vector indexing varies across shader backends.
int band_for(int season) {
	if (season == 0) { return band_of_season.x; }
	if (season == 1) { return band_of_season.y; }
	if (season == 2) { return band_of_season.z; }
	return band_of_season.w;
}

void fragment() {
	int season = gh_season_at(SCREEN_UV);
	if (season < 0) {
		season = greyhush_region_season;
	}
	int band = band_for(season);

	float bands = float(band_count);
	float band_height = 1.0 / bands;
	// Half a texel keeps a nearest-filtered sample from ever straddling into
	// the band above or below at a seam.
	float half_texel = 0.5 / float(textureSize(TEXTURE, 0).y);
	float local = fract(UV.y * bands) * band_height;
	float y = clamp(local, half_texel, band_height - half_texel) + float(band) * band_height;

	COLOR = texture(TEXTURE, vec2(UV.x, y)) * modulate;

	if (distance > 0.0) {
		float dissolve = greyhush_distance_fade * distance * gh_forgotten_at(SCREEN_UV);
		COLOR.rgb = mix(COLOR.rgb, greyhush_haze_color, clamp(dissolve, 0.0, 1.0));
	}
}

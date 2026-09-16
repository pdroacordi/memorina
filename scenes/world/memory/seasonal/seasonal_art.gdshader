shader_type canvas_item;

// Seasonal art, generically. Put this material on any Sprite2D or TileMapLayer
// whose texture is a STACKED SHEET - the same drawing repeated in equal
// vertical bands, one per season - and it shows the region's native season,
// or the season of whatever pulse is lighting each pixel, by sliding its UV
// into the matching band.
//
// The scene always references BAND 0: tile atlas coordinates in the top rows,
// a sprite's region_rect inside the top band. Which band is which season is
// declared here per sheet, so the existing tile sheet (spring, autumn, winter)
// and any future sheet in a different order both work unchanged.
//
// Works with texture_repeat: fract() folds a UV.y that tiles past the band
// back into it, and UV.x is left alone. With TileSet texture padding: a band
// is a whole number of tile rows, so the FRACTION is the same padded or not.
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

// The node's modulate, carried over from the vertex stage. In a canvas_item
// fragment COLOR already holds texture(TEXTURE, UV) * modulate, so using it
// as the tint would multiply the seasonal texel by the band-0 texel.
varying vec4 modulate;

void vertex() {
	modulate = COLOR;
}

// Explicit components rather than band_of_season[season]: a vector indexed by
// a runtime value is not reliable across Godot's shader backends.
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

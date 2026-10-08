// Shared water coordinates and ramp sampling for water_surface, water_lake, and water_veil.
// Use floored world texels so waterlines and stipple align across passes at every camera zoom.

#include "res://scenes/world/memory/dither_common.gdshaderinc"

// Per-column data from WaterSurfaceTexture: r height above rest line (px), g foam (0..1), b floor depth (px), a unused (ice is its own sheet, ice_sheet.gdshader).
uniform sampler2D surface_data : filter_nearest, repeat_disable;
// Rest waterline y and body left-edge x in world pixels.
uniform float rest_y = 0.0;
uniform float body_left = 0.0;
uniform int column_width = 2;
// Depth per ramp band in world pixels.
uniform float depth_band_px = 6.0;
uniform sampler2D transmit_ramp : filter_nearest, repeat_disable, hint_default_white;

// Dry discs in world px (xy center, z radius); must match `WaterBody._refresh_dry()`.
uniform vec4 held_discs[4];
uniform int held_count = 0;

varying vec2 world_pos;

int wc_column(float world_x) {
	int count = textureSize(surface_data, 0).x;
	return clamp(int(floor((world_x - body_left) / float(column_width))), 0, count - 1);
}

vec4 wc_data(int column) {
	return texelFetch(surface_data, ivec2(column, 0), 0);
}

// The first water row; round heights here so the surface moves in whole pixels.
float wc_surface(vec4 data) {
	return rest_y - round(data.r);
}

// The first row below the column's water; pixels below the floor are bank.
float wc_floor(vec4 data) {
	return rest_y + data.b;
}

// Selects a ramp band, dithering between neighboring entries on the texel grid.
int wc_band(float depth, int entries, vec2 texel) {
	if (entries <= 1) {
		return 0;
	}
	float t = clamp(depth / (depth_band_px * float(entries - 1)), 0.0, 1.0);
	return int(round(wd_quantise(t, entries, texel) * float(entries - 1)));
}

vec4 wc_ramp(sampler2D ramp, float depth, vec2 texel) {
	int entries = textureSize(ramp, 0).x;
	return texelFetch(ramp, ivec2(wc_band(depth, entries, texel), 0), 0);
}

// Samples flat, undithered bands for the lake reflection.
vec4 wc_ramp_flat(sampler2D ramp, float depth) {
	int entries = textureSize(ramp, 0).x;
	return texelFetch(ramp, ivec2(clamp(int(depth / depth_band_px), 0, entries - 1), 0), 0);
}

// Signed distance to the nearest held disc in px; positive is inside. Must match HeldDiscs.contains() (held_discs.gd).
float wc_held(vec2 point) {
	float inside = -1e6;
	for (int i = 0; i < held_count; i++) {
		inside = max(inside, held_discs[i].z - distance(point, held_discs[i].xy));
	}
	return inside;
}

// Returns the transmit-ramp color at this depth.
vec3 wc_transmit(float depth, vec2 texel) {
	return wc_ramp(transmit_ramp, depth, texel).rgb;
}

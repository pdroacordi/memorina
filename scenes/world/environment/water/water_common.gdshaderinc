// What every water pass must agree on, pixel for pixel: where the surface is,
// how deep a pixel lies below it, and which band of a ramp that depth falls in.
//
// Three shaders include this: water_surface (the pool) and water_lake (the
// lake) draw the water in the world, and water_veil tints the creatures
// standing in a pool from inside the creature pass. Sharing the source is what
// makes the waterline cross Ivo on exactly the pixel row where it crosses the
// ground behind him.
//
// Everything here is measured in WORLD TEXELS (floor of the world position), so
// the waterline, the bands and every stipple move with the art under any camera
// zoom. Never FRAGCOORD, never SCREEN_UV: those are window pixels.

#include "res://scenes/world/memory/dither_common.gdshaderinc"

// One texel per column (FORMAT_RGBAF, written by WaterSurfaceTexture):
// r = height above the rest line in world pixels (0 for a lake: it is flat),
// g = foam 0..1 (a lake has none and keeps the column's own clock there),
// b = the floor, world pixels below the rest line,
// a = ice solidity 0..1 (1 = solid and walkable).
uniform sampler2D surface_data : filter_nearest, repeat_disable;
// World y of the rest waterline, and world x of the body's left edge.
uniform float rest_y = 0.0;
uniform float body_left = 0.0;
uniform int column_width = 2;
// World pixels per depth band.
uniform float depth_band_px = 6.0;
uniform sampler2D transmit_ramp : filter_nearest, repeat_disable, hint_default_white;

varying vec2 world_pos;

int wc_column(float world_x) {
	int count = textureSize(surface_data, 0).x;
	return clamp(int(floor((world_x - body_left) / float(column_width))), 0, count - 1);
}

vec4 wc_data(int column) {
	return texelFetch(surface_data, ivec2(column, 0), 0);
}

// The first water row of a column. Heights are rounded here and only here, so
// the waterline steps a whole pixel at a time - it never slides.
float wc_surface(vec4 data) {
	return rest_y - round(data.r);
}

// The first row below a column's water: a painted basin may be stepped, and
// under its floor is the bank, never water.
float wc_floor(vec4 data) {
	return rest_y + data.b;
}

// Which entry of an N-entry ramp a depth falls in: the depth gradient
// posterised into the ramp's bands, dithered between neighbours on the texel
// grid so it reads as hand-picked palette steps.
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

// The same ramp in FLAT steps, depth_band_px deep each, never dithered: rows of
// one colour, as the lake's reference is drawn. The pool dithers between its
// steps; a lake's dither made its whole reflection a checkerboard.
vec4 wc_ramp_flat(sampler2D ramp, float depth) {
	int entries = textureSize(ramp, 0).x;
	return texelFetch(ramp, ivec2(clamp(int(depth / depth_band_px), 0, entries - 1), 0), 0);
}

// What the water does to whatever shows through it at this depth.
vec3 wc_transmit(float depth, vec2 texel) {
	return wc_ramp(transmit_ramp, depth, texel).rgb;
}

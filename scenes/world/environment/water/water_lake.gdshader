shader_type canvas_item;

// The lake is a top-down plane; unlike water_surface's cross-section, its far shore stays straight and opaque.
// Reflection bands and glints use whole-pixel movement; body and reflection ramps must use wc_ramp_flat to avoid dithering.
// Discrete glint and shore-line choices use each column's memory clock; sliding bands and glints use shared water_time to avoid permanent shear.
// Grey water hides reflection and glints but keeps the still shore line. Art uses world texels; memory uses game pixels.

#include "res://scenes/world/environment/water/water_common.gdshaderinc"
#include "res://scenes/world/environment/water/water_reflection.gdshaderinc"
#include "res://scenes/world/memory/seasonal/seasonal_common.gdshaderinc"

uniform sampler2D body_ramp : filter_nearest, repeat_disable, hint_default_black;
uniform sampler2D reflection_ramp : filter_nearest, repeat_disable, hint_default_black;
uniform vec4 top_line_color : source_color = vec4(0.78, 0.88, 0.9, 1.0);

// World pixels from the far shore to the mirror axis; negative values are above it.
uniform float mirror_axis_offset = 0.0;
uniform int band_height = 2;
uniform int band_height_near = 6;
uniform float band_shift_near = 3.0;
uniform float band_speed = 1.3;
uniform float perspective_px = 48.0;
uniform float reflection_stretch = 0.0;

uniform float glint_density = 0.12;
uniform int glint_length = 10;
uniform float glint_rate = 0.8;
uniform vec4 glint_color : source_color = vec4(0.85, 0.92, 0.98, 0.7);

// WaterBody's shared clock for sliding bands; do not use TIME.
uniform float water_time = 0.0;

// Share of the far shore's light line broken at any moment, and how often a
// dash re-rolls, per second of its column's clock.
const float LINE_GAPS = 0.12;
const float LINE_REROLL = 0.25;
// Fastest sideways drift of a lane of glints, world pixels per second.
const float GLINT_DRIFT = 3.0;

// Integrates inverse band height so bands grow from band_height to band_height_near over perspective_px.
float band_of(float depth) {
	float h0 = float(band_height);
	float h1 = float(band_height_near);
	if (abs(h1 - h0) < 0.001) {
		return floor(depth / h0);
	}
	float near = max(perspective_px, 1.0);
	float d = min(depth, near);
	float grown = near / (h1 - h0) * log((h0 + (h1 - h0) * d / near) / h0);
	return floor(grown + max(depth - near, 0.0) / h1);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// Derivatives must be evaluated before any discard.
	vec2 uv_per_world = vec2(dFdx(SCREEN_UV.x) / dFdx(world_pos.x), dFdy(SCREEN_UV.y) / dFdy(world_pos.y));

	vec2 texel = floor(world_pos);
	vec2 centre = texel + 0.5;
	int column = wc_column(centre.x);
	vec4 data = wc_data(column);
	if (texel.y < rest_y || texel.y >= wc_floor(data)) {
		discard;
	}
	// Per-column memory clock stops when that column is forgotten.
	float here_time = data.g;
	float depth = texel.y - rest_y;
	// 0 at the far shore and 1 at perspective_px and beyond.
	float near = clamp(depth / max(perspective_px, 1.0), 0.0, 1.0);

	vec2 game_px = floor(SCREEN_UV * wr_game_size());
	float awake = wr_awake(1.0 - gh_forgotten_at(SCREEN_UV));

	vec3 colour = wc_ramp_flat(body_ramp, depth).rgb;

	// Reflection bands shift and dip by whole pixels, increasingly with depth.
	float band = band_of(depth);
	float phase = band * 1.7 + wd_hash11(band * 3.1) * 6.2832 + water_time * band_speed;
	float shift = round(band_shift_near * near * sin(phase));
	float dip = round(near * sin(band * 2.9 + water_time * band_speed * 0.8));
	float axis = rest_y + mirror_axis_offset;
	float reach = (centre.y - axis) + reflection_stretch * depth * depth;
	vec2 mirrored = vec2(centre.x + shift, axis - reach + dip);
	vec2 uv_m = wr_clamp_x(wr_screen_uv(SCREEN_UV, world_pos, uv_per_world, mirrored), SCREEN_PIXEL_SIZE);
	vec4 tint = wc_ramp_flat(reflection_ramp, depth);
	float gate = wr_gate(tint.a, awake, wr_edge(uv_m), game_px);
	colour = mix(colour, wr_sample(uv_m, SCREEN_PIXEL_SIZE) * tint.rgb, gate);

	// Memory gates each dash, so fading reduces dash count without breaking dashes into dots.
	if (depth >= 2.0) {
		float lane = depth;
		float drift = floor(water_time * (wd_hash11(lane * 5.3) * 2.0 - 1.0) * GLINT_DRIFT);
		float x = texel.x + drift;
		float length_px = float(glint_length);
		float cell = floor(x / length_px);
		float roll = floor(here_time * glint_rate + wd_hash11(cell * 1.3 + lane * 7.1) * 8.0);
		float seed = cell * 7.13 + lane * 3.71 + roll * 17.31;
		bool lit = wd_hash11(seed) < glint_density * (1.0 - 0.7 * near);
		float dash = 2.0 + floor(wd_hash11(seed + 0.5) * (length_px - 1.0));
		if (lit && x - cell * length_px < dash && awake > wd_hash11(seed + 0.7)) {
			colour = mix(colour, glint_color.rgb, glint_color.a);
		}
	}

	// The far shore line remains visible in dead water; each column's gaps use its own clock.
	if (depth < 1.0) {
		float dash = float(column);
		float roll = floor(here_time * LINE_REROLL + wd_hash11(dash * 2.3) * 4.0);
		if (wd_hash11(dash * 5.1 + roll * 13.7) >= LINE_GAPS) {
			colour = top_line_color.rgb;
		}
	}

	COLOR = vec4(colour, 1.0);
}

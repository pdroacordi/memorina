shader_type canvas_item;

// A lake in front of the land, seen FROM ABOVE. The pool (water_surface) is a
// cross-section: its waterline is a profile, and what lies behind the water
// shows through it. A lake is a plane: its top edge is the far shore and stays
// straight, it is opaque - it IS the surface, and hides the bank under it - and
// its waves are not an outline but the reflection tearing:
//
// - PERSPECTIVE ROWS. The reflection is cut into bands of rows that slide
//   sideways by whole pixels. Near the far shore the bands are thin and still,
//   so what stands at the bank is mirrored almost whole; toward the viewer
//   they grow taller and slide further, and the mirror breaks into slats.
// - GLINTS. Short 1 px dashes of sky caught on the ripples, thick near the
//   shore and thinning toward the viewer.
// - DEPTH. The reflection is strongest at the far shore and gives way to dark
//   water toward the viewer (the ramps, far to near).
//
// Everything moves on the body's clock (water_time), which crawls where the
// lake is forgotten and stops where it is dead; the glints wake with the
// reflection, so grey water is a flat sheet with its light line on top. Same
// two grids as the pool: art in WORLD texels, memory in GAME pixels.

#include "res://scenes/world/environment/water/water_common.gdshaderinc"
#include "res://scenes/world/environment/water/water_reflection.gdshaderinc"
#include "res://scenes/world/memory/seasonal/seasonal_common.gdshaderinc"

uniform sampler2D body_ramp : filter_nearest, repeat_disable, hint_default_black;
uniform sampler2D reflection_ramp : filter_nearest, repeat_disable, hint_default_black;
uniform vec4 top_line_color : source_color = vec4(0.78, 0.88, 0.9, 1.0);

// World pixels from the far shore to the mirror axis; negative is ABOVE it.
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

// The water's own clock (WaterBody). Never TIME.
uniform float water_time = 0.0;

// Share of the far shore's light line broken at any moment.
const float LINE_GAPS = 0.12;
// World pixels per dash of the light line.
const float LINE_DASH = 12.0;

float hash11(float n) {
	float p = fract(n * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

// Which band of rows a depth falls in, when a band's height grows linearly from
// band_height at the shore to band_height_near at perspective_px and stays
// there: the integral of 1 / height, so every band is as tall as the rows it
// sits on say it should be.
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
	// Derivatives first: nothing below may discard before they are taken.
	vec2 uv_per_world = vec2(dFdx(SCREEN_UV.x) / dFdx(world_pos.x), dFdy(SCREEN_UV.y) / dFdy(world_pos.y));

	vec2 texel = floor(world_pos);
	vec2 centre = texel + 0.5;
	if (texel.y < rest_y) {
		discard;
	}
	float depth = texel.y - rest_y;
	// 0 at the far shore, 1 from perspective_px toward the viewer.
	float near = clamp(depth / max(perspective_px, 1.0), 0.0, 1.0);

	vec2 game_px = floor(SCREEN_UV * wr_game_size());
	float awake = wr_awake(1.0 - gh_forgotten_at(SCREEN_UV));

	vec3 colour = wc_ramp(body_ramp, depth, texel).rgb;

	// The reflection, torn into bands. Each slides sideways and dips a row by
	// whole pixels, by more the nearer it is.
	float band = band_of(depth);
	float phase = band * 1.7 + hash11(band * 3.1) * 6.2832 + water_time * band_speed;
	float shift = round(band_shift_near * near * sin(phase));
	float dip = round(near * sin(band * 2.9 + water_time * band_speed * 0.8));
	float axis = rest_y + mirror_axis_offset;
	float reach = (centre.y - axis) + reflection_stretch * depth * depth;
	vec2 mirrored = vec2(centre.x + shift, axis - reach + dip);
	vec2 uv_m = wr_clamp_x(wr_screen_uv(SCREEN_UV, world_pos, uv_per_world, mirrored), SCREEN_PIXEL_SIZE);
	vec4 tint = wc_ramp(reflection_ramp, depth, texel);
	float gate = wr_gate(tint.a, awake, wr_edge(uv_m), game_px);
	colour = mix(colour, wr_sample(uv_m, SCREEN_PIXEL_SIZE) * tint.rgb, gate);

	// Glints: along each row, segments glint_length wide drift slowly and are
	// re-rolled on the clock; a lit one shows a dash of 2..glint_length pixels.
	if (depth >= 2.0) {
		float lane = depth;
		float drift = floor(water_time * (hash11(lane * 5.3) - 0.5) * 6.0);
		float x = texel.x + drift;
		float length_px = float(glint_length);
		float cell = floor(x / length_px);
		float roll = floor(water_time * glint_rate + hash11(cell * 1.3 + lane * 7.1) * 8.0);
		float seed = cell * 7.13 + lane * 3.71 + roll * 17.31;
		bool lit = hash11(seed) < glint_density * (1.0 - 0.7 * near);
		float dash = 2.0 + floor(hash11(seed + 0.5) * (length_px - 1.0));
		if (lit && x - cell * length_px < dash && awake > BAYER[wd_bayer_index(game_px)]) {
			colour = mix(colour, glint_color.rgb, glint_color.a);
		}
	}

	// The far shore's light line: always drawn, dead water keeps it; a few
	// dashes open and close on the clock, which stops with the water.
	if (depth < 1.0) {
		float dash = floor(texel.x / LINE_DASH);
		float roll = floor(water_time * 0.25 + hash11(dash * 2.3) * 4.0);
		if (hash11(dash * 5.1 + roll * 13.7) >= LINE_GAPS) {
			colour = top_line_color.rgb;
		}
	}

	COLOR = vec4(colour, 1.0);
}

shader_type canvas_item;

// A body of water, computed: its colour by depth, what shows through it, the
// world and the creatures mirrored in it, coarse caustics, the lighter line on
// top, and ice. Drawn in the WORLD canvas at WaterQuad.Z, so the greyhush pass
// greys it afterwards like any other world pixel.
//
// TWO GRIDS. Everything that belongs to the art (waterline, depth bands, the
// reflection's row bands, caustics, ice crystals) is decided in WORLD TEXELS,
// so it moves with the scenery under any zoom. Everything that follows the
// memory field (the reflection gate, the edge stipple) is decided in GAME
// PIXELS, on the same Bayer grid as the greyhush. Never FRAGCOORD.
//
// The mirror itself (no camera, two sources) is water_reflection.gdshaderinc.

#include "res://scenes/world/environment/water/water_common.gdshaderinc"
#include "res://scenes/world/environment/water/water_reflection.gdshaderinc"
#include "res://scenes/world/memory/seasonal/seasonal_common.gdshaderinc"

uniform sampler2D body_ramp : filter_nearest, repeat_disable, hint_default_transparent;
uniform sampler2D reflection_ramp : filter_nearest, repeat_disable, hint_default_black;
uniform sampler2D ice_ramp : filter_nearest, repeat_disable, hint_default_white;
uniform vec4 top_line_color : source_color = vec4(0.78, 0.88, 0.9, 1.0);
uniform vec4 foam_color : source_color = vec4(0.94, 0.97, 0.98, 1.0);

// World pixels from the rest line to the mirror axis; negative is ABOVE the
// water: water below a bank mirrors about the bank's top, not its own.
uniform float mirror_axis_offset = 0.0;
uniform int band_height = 2;
uniform float band_shift_max = 1.0;
uniform float band_speed = 1.3;

uniform float caustic_depth = 10.0;
uniform int caustic_band_px = 3;
uniform float caustic_rate = 1.5;
uniform float caustic_density = 0.3;
uniform float caustic_strength = 0.35;

uniform float ice_thickness = 6.0;
// The water's own clock (WaterBody): stops with the world under a pause and
// crawls where the water is forgotten. Never TIME.
uniform float water_time = 0.0;

float hash11(float n) {
	float p = fract(n * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// Derivatives first: nothing below may discard before they are taken.
	vec2 uv_per_world = vec2(dFdx(SCREEN_UV.x) / dFdx(world_pos.x), dFdy(SCREEN_UV.y) / dFdy(world_pos.y));

	vec2 texel = floor(world_pos);
	vec2 centre = texel + 0.5;
	int column = wc_column(centre.x);
	vec4 data = wc_data(column);
	float surface = wc_surface(data);
	if (texel.y < surface || texel.y >= wc_floor(data)) {
		discard;
	}
	float depth = texel.y - surface;

	vec2 game_px = floor(SCREEN_UV * wr_game_size());
	float remembered = 1.0 - gh_forgotten_at(SCREEN_UV);

	// What lies behind the water, seen through it.
	vec2 here = wr_screen_uv(SCREEN_UV, world_pos, uv_per_world, centre);
	vec3 behind = texture(screen_texture, wr_output_centre(here, SCREEN_PIXEL_SIZE)).rgb;
	vec4 body = wc_ramp(body_ramp, depth, texel);
	vec3 colour = mix(behind * wc_transmit(depth, texel), body.rgb, body.a);

	// The reflection. The axis rides the local surface, so a crest lifts the
	// mirrored world with it; each band of rows slides sideways by whole pixels.
	float axis = rest_y + mirror_axis_offset - round(data.r);
	float row = floor(depth / float(band_height));
	float shift = round(band_shift_max * sin(row * 1.7 + water_time * band_speed));
	vec2 mirrored = vec2(centre.x + shift, 2.0 * axis - centre.y);
	vec2 uv_m = wr_clamp_x(wr_screen_uv(SCREEN_UV, world_pos, uv_per_world, mirrored), SCREEN_PIXEL_SIZE);
	vec3 reflected = wr_sample(uv_m, SCREEN_PIXEL_SIZE);
	vec4 tint = wc_ramp(reflection_ramp, depth, texel);
	float awake = wr_awake(remembered);
	float gate = wr_gate(tint.a, awake, wr_edge(uv_m), game_px);
	colour = mix(colour, reflected * tint.rgb, gate);

	// Caustics: coarse vertical bands re-rolled on the water's clock. They wake
	// with the reflection (the same memory ramp), so grey water is empty rather
	// than speckled. The band's own falloff is art (texel grid); the waking is
	// memory (game-pixel grid).
	if (depth < caustic_depth) {
		float band = floor(texel.x / float(caustic_band_px));
		float roll = floor(water_time * caustic_rate + hash11(band * 3.7) * 8.0);
		float lit = hash11(band * 7.13 + roll * 17.31) < caustic_density ? 1.0 : 0.0;
		bool shown = lit * (1.0 - depth / caustic_depth) > BAYER[wd_bayer_index(texel)]
			&& awake > BAYER[wd_bayer_index(game_px)];
		if (shown) {
			colour = mix(colour, top_line_color.rgb, caustic_strength);
		}
	}

	// The lighter line on top, including the exposed side of a step between
	// columns. Always drawn: dead water keeps it.
	float in_column = centre.x - body_left - float(column * column_width);
	bool exposed_left = in_column < 1.0 && column > 0 && texel.y < wc_surface(wc_data(column - 1));
	bool exposed_right = in_column > float(column_width) - 1.0
		&& column + 1 < textureSize(surface_data, 0).x
		&& texel.y < wc_surface(wc_data(column + 1));
	if (depth < 1.0 || exposed_left || exposed_right) {
		bool foam = data.g > BAYER[wd_bayer_index(texel)];
		colour = foam ? foam_color.rgb : top_line_color.rgb;
	}

	// Ice: crystals stippling in as the column sets, then a solid band with its
	// own top line. It replaces the reflection where it stands.
	float solidity = data.a;
	if (solidity > 0.0 && depth < ice_thickness) {
		int entries = textureSize(ice_ramp, 0).x;
		int index = int(round(clamp(depth / ice_thickness, 0.0, 1.0) * float(entries - 1)));
		vec3 ice = texelFetch(ice_ramp, ivec2(depth < 1.0 ? 0 : index, 0), 0).rgb;
		if (solidity >= 1.0 || solidity > BAYER[wd_bayer_index(texel)]) {
			colour = ice;
		}
	}

	COLOR = vec4(colour, 1.0);
}

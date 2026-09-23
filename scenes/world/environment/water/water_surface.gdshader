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
// THE MIRROR NEEDS NO CAMERA. The mirrored point is found in world space and
// carried to the screen by the local scale between world and SCREEN_UV, taken
// from derivatives. Zoom, shake, stretch and a camera moving under a pause all
// cancel out; nothing is uploaded per frame (a pausable uploader would go stale
// exactly when the lesson pushes in). Measured against the exact projection:
// docs/knowledge/gotchas/screen-texture-copy-scope.md.
//
// TWO SOURCES. The world comes from the automatic screen copy. Ivo and the
// guardians are culled out of the world canvas, so they come from the creature
// pass, published as a global by CreatureMask; its texture is 640x360, which is
// also where this shader learns the game resolution from.

#include "res://scenes/world/environment/water/water_common.gdshaderinc"
#include "res://scenes/world/memory/seasonal/seasonal_common.gdshaderinc"

global uniform sampler2D greyhush_creature_pass : filter_nearest, repeat_disable;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;

uniform sampler2D body_ramp : filter_nearest, repeat_disable, hint_default_transparent;
uniform sampler2D reflection_ramp : filter_nearest, repeat_disable, hint_default_black;
uniform sampler2D ice_ramp : filter_nearest, repeat_disable, hint_default_white;
uniform vec4 top_line_color : source_color = vec4(0.78, 0.88, 0.9, 1.0);
uniform vec4 foam_color : source_color = vec4(0.94, 0.97, 0.98, 1.0);

// World pixels from the rest line to the mirror axis; negative is ABOVE the
// water. A strip in front of a bank mirrors about the bank's top, not its own.
uniform float mirror_axis_offset = 0.0;
uniform float reflection_strength = 0.85;
uniform int reflect_levels = 4;
// Memory at which the reflection starts to appear, and at which it is whole.
uniform float reflect_memory_low = 0.15;
uniform float reflect_memory_high = 0.6;
uniform int band_height = 2;
uniform float band_shift_max = 1.0;
uniform float band_speed = 1.3;
uniform float edge_fade_px = 12.0;

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

// A screen UV fetched at the centre of the output pixel it lands in, so the
// sample never straddles two texels of the window-resolution copy.
vec2 output_centre(vec2 uv, vec2 screen_pixel) {
	return (floor(uv / screen_pixel) + 0.5) * screen_pixel;
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
	if (texel.y < surface) {
		discard;
	}
	float depth = texel.y - surface;

	vec2 game_size = vec2(textureSize(greyhush_creature_pass, 0));
	vec2 game_px = floor(SCREEN_UV * game_size);
	float remembered = 1.0 - gh_forgotten_at(SCREEN_UV);

	// What lies behind the water, seen through it.
	vec2 here = SCREEN_UV + (centre - world_pos) * uv_per_world;
	vec3 behind = texture(screen_texture, output_centre(here, SCREEN_PIXEL_SIZE)).rgb;
	vec4 body = wc_ramp(body_ramp, depth, texel);
	vec3 colour = mix(behind * wc_transmit(depth, texel), body.rgb, body.a);

	// The reflection. The axis rides the local surface, so a crest lifts the
	// mirrored world with it; each band of rows slides sideways by whole pixels.
	float axis = rest_y + mirror_axis_offset - round(data.r);
	float row = floor(depth / float(band_height));
	float shift = round(band_shift_max * sin(row * 1.7 + water_time * band_speed));
	vec2 mirrored = vec2(centre.x + shift, 2.0 * axis - centre.y);
	vec2 uv_m = SCREEN_UV + (mirrored - world_pos) * uv_per_world;
	vec2 inside = min(uv_m, 1.0 - uv_m) * game_size;
	float edge = clamp(min(inside.x, inside.y) / edge_fade_px, 0.0, 1.0);
	vec3 world_m = texture(screen_texture, output_centre(uv_m, SCREEN_PIXEL_SIZE)).rgb;
	vec4 creature = texture(greyhush_creature_pass, (floor(uv_m * game_size) + 0.5) / game_size);
	vec3 reflected = creature.rgb + world_m * (1.0 - creature.a);
	vec4 tint = wc_ramp(reflection_ramp, depth, texel);
	// The authored strength is posterised, never dithered: a band's interior is
	// one flat level. The stipple is spent only where the reflection FADES -
	// with memory, and at the screen's edge - so it reads as the water
	// forgetting, not as a checkerboard laid over everything. Memory is read at
	// the WATER's pixel: it is the water that remembers what is above it, and
	// forgotten water shows nothing at all.
	float steps = float(reflect_levels - 1);
	float authored = round(tint.a * reflection_strength * steps) / steps;
	float fade = clamp((remembered - reflect_memory_low) / (reflect_memory_high - reflect_memory_low), 0.0, 1.0) * edge;
	float gate = fade > BAYER[wd_bayer_index(game_px)] ? authored : 0.0;
	colour = mix(colour, reflected * tint.rgb, gate);

	// Caustics: coarse vertical bands re-rolled on the water's clock, gone
	// where the water is forgotten.
	if (depth < caustic_depth) {
		float band = floor(texel.x / float(caustic_band_px));
		float roll = floor(water_time * caustic_rate + hash11(band * 3.7) * 8.0);
		float lit = hash11(band * 7.13 + roll * 17.31) < caustic_density ? 1.0 : 0.0;
		float amount = lit * (1.0 - depth / caustic_depth) * remembered;
		if (amount > BAYER[wd_bayer_index(texel)]) {
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

// Shared by water_surface.gdshader and water_lake.gdshader; water_common is included by the veil, which must not declare a screen texture.
//
// World-to-screen projection uses derivatives, so camera motion and transforms need no per-frame upload; see docs/knowledge/gotchas/screen-texture-copy-scope.md.
//
// World pixels come from the screen copy; Ivo and guardians come from CreatureMask because they are culled from the world canvas. The pass is 640x360.

#include "res://scenes/world/memory/dither_common.gdshaderinc"

global uniform sampler2D greyhush_creature_pass : filter_nearest, repeat_disable;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;

uniform float reflection_strength = 0.85;
uniform int reflect_levels = 4;
// Memory at which the reflection starts to appear, and at which it is whole.
uniform float reflect_memory_low = 0.15;
uniform float reflect_memory_high = 0.6;
uniform float edge_fade_px = 12.0;

vec2 wr_game_size() {
	return vec2(textureSize(greyhush_creature_pass, 0));
}

// Must sample the output pixel centre to avoid blending adjacent screen-copy texels.
vec2 wr_output_centre(vec2 uv, vec2 screen_pixel) {
	return (floor(uv / screen_pixel) + 0.5) * screen_pixel;
}

// Maps a world point to SCREEN_UV using this fragment's derivatives.
vec2 wr_screen_uv(vec2 screen_uv, vec2 frag_world, vec2 uv_per_world, vec2 point) {
	return screen_uv + (point - frag_world) * uv_per_world;
}

// Clamp x because a vertical mirror exits only at the top; sideways bands use the edge column.
vec2 wr_clamp_x(vec2 uv, vec2 screen_pixel) {
	uv.x = clamp(uv.x, 0.5 * screen_pixel.x, 1.0 - 0.5 * screen_pixel.x);
	return uv;
}

// Vertical screen-edge fade from 0 offscreen to 1 at edge_fade_px inside.
float wr_edge(vec2 uv) {
	return clamp(min(uv.y, 1.0 - uv.y) * wr_game_size().y / edge_fade_px, 0.0, 1.0);
}

// Samples world and premultiplied creatures at a mirrored screen UV.
vec3 wr_sample(vec2 uv, vec2 screen_pixel) {
	vec2 game_size = wr_game_size();
	vec3 world = texture(screen_texture, wr_output_centre(uv, screen_pixel)).rgb;
	vec4 creature = texture(greyhush_creature_pass, (floor(uv * game_size) + 0.5) / game_size);
	return creature.rgb + world * (1.0 - creature.a);
}

// Reflection visibility on the memory ramp (0..1).
float wr_awake(float remembered) {
	return clamp((remembered - reflect_memory_low) / (reflect_memory_high - reflect_memory_low), 0.0, 1.0);
}

// Posterises authored opacity and dithers only the memory and screen-edge fades; memory is sampled at the water pixel.
float wr_gate(float ramp_alpha, float awake, float edge, vec2 game_px) {
	float steps = float(reflect_levels - 1);
	float authored = round(ramp_alpha * reflection_strength * steps) / steps;
	return awake * edge > BAYER[wd_bayer_index(game_px)] ? authored : 0.0;
}

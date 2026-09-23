// The mirror both world water shaders draw with: the pool seen edge-on
// (water_surface.gdshader) and the lake seen from above (water_lake.gdshader).
// Kept out of water_common because the veil includes that one, and the veil
// must never declare a screen texture.
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
// also where the water learns the game resolution from.

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

// A screen UV fetched at the centre of the output pixel it lands in, so the
// sample never straddles two texels of the window-resolution copy.
vec2 wr_output_centre(vec2 uv, vec2 screen_pixel) {
	return (floor(uv / screen_pixel) + 0.5) * screen_pixel;
}

// Where a world point lands in SCREEN_UV, from this fragment's own position.
vec2 wr_screen_uv(vec2 screen_uv, vec2 frag_world, vec2 uv_per_world, vec2 point) {
	return screen_uv + (point - frag_world) * uv_per_world;
}

// A vertical mirror only ever leaves the screen at the TOP: clamp x so a band's
// sideways slide at the side reads the edge column.
vec2 wr_clamp_x(vec2 uv, vec2 screen_pixel) {
	uv.x = clamp(uv.x, 0.5 * screen_pixel.x, 1.0 - 0.5 * screen_pixel.x);
	return uv;
}

// 0 where the mirrored point is off screen, 1 once it is edge_fade_px inside;
// the fade is on y alone (see wr_clamp_x).
float wr_edge(vec2 uv) {
	return clamp(min(uv.y, 1.0 - uv.y) * wr_game_size().y / edge_fade_px, 0.0, 1.0);
}

// The world and the creatures at a mirrored screen UV, creatures premultiplied
// over the world.
vec3 wr_sample(vec2 uv, vec2 screen_pixel) {
	vec2 game_size = wr_game_size();
	vec3 world = texture(screen_texture, wr_output_centre(uv, screen_pixel)).rgb;
	vec4 creature = texture(greyhush_creature_pass, (floor(uv * game_size) + 0.5) / game_size);
	return creature.rgb + world * (1.0 - creature.a);
}

// How much remembered water shows its reflection, 0..1 on the memory ramp.
float wr_awake(float remembered) {
	return clamp((remembered - reflect_memory_low) / (reflect_memory_high - reflect_memory_low), 0.0, 1.0);
}

// The reflection's opacity at a pixel. The authored strength is posterised,
// never dithered: a band's interior is one flat level. The stipple is spent
// only where the reflection FADES - with memory, and at the screen's edge - so
// it reads as the water forgetting, not as a checkerboard laid over everything.
// Memory is read at the WATER's pixel: it is the water that remembers what is
// above it, and forgotten water shows nothing at all.
float wr_gate(float ramp_alpha, float awake, float edge, vec2 game_px) {
	float steps = float(reflect_levels - 1);
	float authored = round(ramp_alpha * reflection_strength * steps) / steps;
	return awake * edge > BAYER[wd_bayer_index(game_px)] ? authored : 0.0;
}

shader_type canvas_item;
render_mode blend_mul;

// Chuva's sky closing over its pulse: a dithered MULTIPLY on the world, drawn
// in the world canvas above the water (so the greyhush greys it afterwards,
// and the creatures, composited later, stay lit). A storm ceiling hangs
// `cloud_base` px above where the song was played, its belly billowing and
// drifting on the effect's own clock, lowering from the top of the disc as
// `cover` rises; under it the air is only a little darker, more so the higher
// it is. Clipped to the clean disc AND to the pixels the pulse's season owns,
// so it ends on the same ragged edge as the colour.
//
// Art decisions on the WORLD texel grid, never FRAGCOORD; never TIME.

#include "res://scenes/world/memory/dither_common.gdshaderinc"
#include "res://scenes/world/memory/seasonal/seasonal_common.gdshaderinc"

uniform int season = 3;
// The pulse's centre (world px) and its clean disc.
uniform vec2 centre = vec2(0.0);
uniform float radius = 0.0;
// How far the sky has closed, 0..1.
uniform float cover = 0.0;
// The effect's clock, seconds (pausable).
uniform float clock = 0.0;
uniform float cloud_base = 128.0;
// How far the belly billows up and down, px.
uniform float billow_px = 18.0;
uniform float drift = 6.0;
uniform vec4 storm : source_color = vec4(0.42, 0.47, 0.58, 1.0);
// Darkness under the ceiling at the pulse's centre and at its top, and of
// the cloud itself.
uniform float air_low = 0.1;
uniform float air_high = 0.3;
uniform float cloud = 0.62;
uniform int levels = 6;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

// Smooth value noise along x, 0..1: two octaves, whole-texel input.
float billow(float x) {
	float a = x / 28.0;
	float ia = floor(a);
	float big = mix(wd_hash11(ia * 1.37), wd_hash11((ia + 1.0) * 1.37), smoothstep(0.0, 1.0, fract(a)));
	float b = x / 9.0;
	float ib = floor(b);
	float small = mix(wd_hash11(ib * 2.71 + 5.0), wd_hash11((ib + 1.0) * 2.71 + 5.0), smoothstep(0.0, 1.0, fract(b)));
	return big * 0.7 + small * 0.3;
}

void fragment() {
	vec2 texel = floor(world_pos);
	vec2 offset = texel + 0.5 - centre;
	if (cover <= 0.0 || length(offset) > radius || gh_season_at(SCREEN_UV) != season) {
		COLOR = vec4(1.0);
	} else {
		float height = clamp(-offset.y / max(radius, 1.0), 0.0, 1.0);
		float shade = mix(air_low, air_high, height);
		// The belly: lowered from the disc's top toward cloud_base as the sky
		// closes; above it, cloud, with a darker lip right at the belly.
		float belly = -mix(radius, cloud_base, cover) - floor(billow(texel.x + floor(clock * drift)) * billow_px);
		float into = belly - offset.y;
		if (into > 0.0) {
			shade = max(shade, into < 3.0 ? cloud + 0.12 : cloud);
		} else if (into > -6.0) {
			shade = max(shade, mix(shade, cloud, (into + 6.0) / 6.0));
		}
		float q = wd_quantise(clamp(shade * cover, 0.0, 1.0), levels, texel);
		COLOR = mix(vec4(1.0), storm, q);
	}
}

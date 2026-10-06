shader_type canvas_item;

// The title's flute glow: a dithered ellipse whose reach breathes, coloured winter to summer from left to right.
// Pixels are pack pixels from UV and the rect size, never FRAGCOORD; the breath comes from FlutePulse, never TIME.

#include "res://scenes/world/memory/dither_common.gdshaderinc"

// The rect's size in pack pixels; FlutePulse sets it.
uniform vec2 size_px = vec2(96.0, 36.0);
// Winter, autumn, spring, summer, left to right.
uniform vec4 season_colors[4];
// 0..1, set each frame by FlutePulse.
uniform float breath : hint_range(0.0, 1.0) = 0.0;
// Alpha at the centre at the top of a breath.
uniform float peak_alpha : hint_range(0.0, 1.0) = 0.45;
// The reach at the bottom of a breath, as a fraction of the top's.
uniform float rest_reach : hint_range(0.0, 1.0) = 0.35;

// Constant indices only: runtime array indexing differs across shader backends.
vec3 season_at(float x) {
	float t = clamp(x, 0.0, 1.0) * 3.0;
	if (t < 1.0) {
		return mix(season_colors[0].rgb, season_colors[1].rgb, t);
	}
	if (t < 2.0) {
		return mix(season_colors[1].rgb, season_colors[2].rgb, t - 1.0);
	}
	return mix(season_colors[2].rgb, season_colors[3].rgb, t - 2.0);
}

void fragment() {
	vec2 px = floor(UV * size_px);
	vec2 centred = (px + 0.5) / size_px * 2.0 - 1.0;
	float falloff = clamp(1.0 - length(centred), 0.0, 1.0);
	float glow = wd_quantise(falloff * mix(rest_reach, 1.0, breath), 4, px);
	COLOR = vec4(season_at((px.x + 0.5) / size_px.x), glow * peak_alpha);
}

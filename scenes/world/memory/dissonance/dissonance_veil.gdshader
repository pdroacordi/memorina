shader_type canvas_item;

// The final battle's dissonance over the world (design 02 sections 5.2-5.3; architecture/grd-06-final-battle): at the
// revelation, bands of rows slide by whole game pixels and the dissonance colour is dithered in; under mixed notes, an
// unstable grey with static. Game px from UV * game_size, never FRAGCOORD; animated from greyhush_time, never TIME, so
// the freeze frame freezes it too.

#include "res://scenes/world/memory/dither_common.gdshaderinc"

global uniform float greyhush_time;
global uniform float dissonance_veil;
global uniform float dissonance_revelation;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform vec2 game_size = vec2(640.0, 360.0);
uniform vec4 tint : source_color = vec4(0.62, 0.46, 0.78, 1.0);
// Game px per band of rows that slides together.
uniform float band_px = 4.0;
// Game px the bands slide at the revelation's peak.
uniform float max_slide_px = 6.0;
// Seconds of greyhush_time between re-rolls.
uniform float reroll_period = 0.12;

void fragment() {
	vec2 px = floor(UV * game_size);
	float epoch = floor(greyhush_time / reroll_period);
	float band = floor(px.y / band_px);
	float side = mod(band, 2.0) < 1.0 ? 1.0 : -1.0;
	float slide = side * floor(wd_hash11(band * 3.1 + epoch) * max_slide_px * dissonance_revelation + 0.5);
	vec3 colour = texture(screen_texture, (px + vec2(slide, 0.0) + 0.5) / game_size).rgb;
	float luma = dot(colour, vec3(0.299, 0.587, 0.114));
	float glitch = wd_quantise(dissonance_revelation * 0.6, 4, px + vec2(floor(wd_hash11(band + epoch) * 4.0), 0.0));
	colour = mix(colour, tint.rgb * (0.4 + luma), glitch);
	float noise = wd_hash11(px.x * 12.9 + px.y * 78.2 + epoch * 3.3) - 0.5;
	colour = mix(colour, vec3(clamp(luma + noise * 0.3, 0.0, 1.0)), clamp(dissonance_veil, 0.0, 1.0));
	COLOR = vec4(colour, 1.0);
}

shader_type canvas_item;

// One unit of Ivo's life forgetting the way the world does: not tinted grey but
// drained of colour pixel by pixel on the greyhush's own 4x4 Bayer cell, into
// the same faded print (the black lift the renderer pushes as globals). The
// cell is measured in the sprite's TEXELS, never FRAGCOORD, so the stipple is
// part of the art and does not change size with the window.

#include "res://scenes/world/memory/dither_common.gdshaderinc"

// 1 remembered, 0 forgotten. LifeNote eases it, so the colour leaves in a
// dithered sweep rather than a cut.
uniform float memory : hint_range(0.0, 1.0) = 1.0;
// 0..1, the bright moment a note regains its colour at a rest: its pixels
// mixed toward white, then fading back.
uniform float flash : hint_range(0.0, 1.0) = 0.0;

global uniform float greyhush_black_lift;
global uniform vec3 greyhush_black_lift_color;

void fragment() {
	vec2 texel = floor(UV / TEXTURE_PIXEL_SIZE);
	float lit = wd_quantise(memory, 2, texel);
	vec3 grey = vec3(dot(COLOR.rgb, vec3(0.299, 0.587, 0.114)));
	vec3 lifted = greyhush_black_lift_color + grey * (vec3(1.0) - greyhush_black_lift_color);
	grey = mix(grey, lifted, greyhush_black_lift);
	COLOR.rgb = mix(grey, COLOR.rgb, lit);
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), flash);
}

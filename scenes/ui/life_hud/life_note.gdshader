shader_type canvas_item;

// Dithering uses sprite texels so the 4x4 Bayer pattern does not scale with the window.

#include "res://scenes/world/memory/dither_common.gdshaderinc"
#include "res://scenes/world/memory/greyhush_print.gdshaderinc"

// 1 remembered, 0 forgotten. LifeNote eases it, so the colour leaves in a
// dithered sweep rather than a cut.
uniform float memory : hint_range(0.0, 1.0) = 1.0;
// 0..1, the bright moment a note regains its colour at a rest: its pixels
// mixed toward white, then fading back.
uniform float flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 texel = floor(UV / TEXTURE_PIXEL_SIZE);
	float lit = wd_quantise(memory, 2, texel);
	COLOR.rgb = mix(gh_print(COLOR.rgb), COLOR.rgb, lit);
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), flash);
}

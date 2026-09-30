shader_type canvas_item;

// Sombra's burned shadow (CastShadow): Ivo's frame as a hole of shade, its
// rim burning in the summer tint and shimmering like air over hot stone. The
// shimmer shifts whole texels, row by row, so it stays pixel art; the fade is
// an ordered dither on the texel grid, never alpha.

#include "res://scenes/world/memory/dither_common.gdshaderinc"

uniform vec4 shadow_color : source_color = vec4(0.08, 0.06, 0.07, 1.0);
uniform vec4 rim_color : source_color = vec4(1.0, 0.8, 0.45, 1.0);
// The effect's own clock (pausable world time), never TIME.
uniform float clock = 0.0;
uniform float fade : hint_range(0.0, 1.0) = 1.0;
// How far a row of the shimmer may wander, in texels.
uniform float shimmer_texels = 1.0;

// A macro, not a function: TEXTURE only exists inside fragment(), and the
// compiler will not pass it to a helper.
#define SOLID(uv) step(0.5, texture(TEXTURE, (uv)).a)

void fragment() {
	vec2 texel = TEXTURE_PIXEL_SIZE;
	vec2 cell = floor(UV / texel);
	float shift = round(sin(cell.y * 0.9 + clock * 6.0) * shimmer_texels);
	vec2 uv = (cell + vec2(shift, 0.0) + 0.5) * texel;
	if (SOLID(uv) < 0.5 || fade <= BAYER[wd_bayer_index(cell)]) {
		COLOR = vec4(0.0);
	} else {
		float inner = SOLID(uv + vec2(texel.x, 0.0)) * SOLID(uv - vec2(texel.x, 0.0))
			* SOLID(uv + vec2(0.0, texel.y)) * SOLID(uv - vec2(0.0, texel.y));
		float flicker = 0.6 + 0.4 * sin(clock * 5.0 + cell.y * 0.5);
		vec3 rim = mix(shadow_color.rgb, rim_color.rgb, flicker);
		COLOR = vec4(inner > 0.5 ? shadow_color.rgb : rim, 1.0);
	}
}

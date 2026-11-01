shader_type canvas_item;

// Ivo at the revelation: a flat silhouette in the dissonance colour, its edge fraying in art pixels re-rolled on
// greyhush_time (design 02 section 5.2; architecture/grd-06-final-battle).

#include "res://scenes/world/memory/dither_common.gdshaderinc"

global uniform float greyhush_time;

uniform vec4 colour : source_color = vec4(0.62, 0.46, 0.78, 1.0);
// Share of the silhouette's art pixels missing, 0..1.
uniform float fray : hint_range(0.0, 1.0) = 0.15;
uniform float reroll_period = 0.12;

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	vec2 art_px = floor(UV / TEXTURE_PIXEL_SIZE);
	float epoch = floor(greyhush_time / reroll_period);
	float gone = wd_hash11(art_px.x * 7.1 + art_px.y * 31.7 + epoch) < fray ? 0.0 : 1.0;
	COLOR = vec4(colour.rgb, texel.a < 0.5 ? 0.0 : gone);
}

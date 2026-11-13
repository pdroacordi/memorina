shader_type canvas_item;

// An engraved still: grey texels in the forgotten print, key texels (#FF00FF) in the song's ink, dithered in and out
// in the texture's art pixels. Every value comes from EngravingView (architecture/story-04-bearer-fragments).

#include "res://scenes/world/memory/greyhush_print.gdshaderinc"

uniform vec4 ink_colour : source_color = vec4(1.0);
// Luma the ink is darkened to at most, so a light season tint still reads on the grey paper (#b8b8b8).
uniform float ink_max_luma : hint_range(0.0, 1.0) = 0.42;
// 0..1 of the layer dithered in.
uniform float shown : hint_range(0.0, 1.0) = 1.0;
uniform bool ink_only = false;
// Art px the ink has scrolled inside its cell (whole px).
uniform vec2 scroll = vec2(0.0);
uniform int cell = 0;
uniform int hframes = 1;

const float BAYER[16] = float[16](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0
);

vec3 ink() {
	float luma = dot(ink_colour.rgb, vec3(0.299, 0.587, 0.114));
	return luma > ink_max_luma ? ink_colour.rgb * (ink_max_luma / luma) : ink_colour.rgb;
}

void fragment() {
	vec2 texture_px = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 texel = floor(UV * texture_px);
	vec2 cell_px = vec2(texture_px.x / float(max(hframes, 1)), texture_px.y);
	vec2 origin = vec2(float(cell) * cell_px.x, 0.0);
	vec2 local = mod(texel - origin - scroll, cell_px);
	vec4 c = texture(TEXTURE, (origin + local + 0.5) * TEXTURE_PIXEL_SIZE);
	bool keyed = c.a > 0.5 && distance(c.rgb, vec3(1.0, 0.0, 1.0)) < 0.1;
	if (keyed) {
		c.rgb = ink();
	} else if (ink_only) {
		c.a = 0.0;
	} else {
		c.rgb = gh_print(c.rgb);
	}
	ivec2 b = ivec2(mod(texel - origin, 4.0));
	float threshold = (BAYER[b.y * 4 + b.x] + 0.5) / 16.0;
	if (shown < threshold) {
		c.a = 0.0;
	}
	COLOR = c;
}

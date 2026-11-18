shader_type canvas_item;

// An engraved still: grey texels in the forgotten print, key texels in their inks, dithered in and out in the texture's
// art pixels. Key #FF00FF takes ink_colour, #00FFFF ink_b_colour, and #FFFF00 is the mixed ink: each art texel picks ink
// A, ink B or a printed grey from tremble_step. Every value comes from EngravingView (architecture/story-04-bearer-fragments;
// architecture/story42-the-final-fragment, "The look").

#include "res://scenes/world/memory/greyhush_print.gdshaderinc"

uniform vec4 ink_colour : source_color = vec4(1.0);
uniform vec4 ink_b_colour : source_color = vec4(1.0);
// Luma the inks are darkened to at most, so a light season tint still reads on the grey paper (#b8b8b8).
uniform float ink_max_luma : hint_range(0.0, 1.0) = 0.42;
// 0..1 of the layer dithered in.
uniform float shown : hint_range(0.0, 1.0) = 1.0;
uniform bool ink_only = false;
// Art px the ink has scrolled inside its cell (whole px).
uniform vec2 scroll = vec2(0.0);
uniform int cell = 0;
uniform int hframes = 1;
// Art px an ink-only layer's 2 px row bands shift by at most; 0 holds them.
uniform float tremble = 0.0;
// EngravingMath.tremble_step: the mixed ink's and the bands' pick; never TIME.
uniform int tremble_step = 0;

const float BAYER[16] = float[16](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0
);
// Must match GREYS in tools/art/cut_engraving.py.
const float GREYS[4] = float[4](60.0, 96.0, 140.0, 184.0);
const float BAND_PX = 2.0;

uint pick(uvec3 v) {
	uint h = v.x * 73856093u ^ v.y * 19349663u ^ v.z * 83492791u;
	h ^= h >> 13u;
	h *= 1540483477u;
	h ^= h >> 15u;
	return h;
}

vec3 darkened(vec3 colour) {
	float luma = dot(colour, vec3(0.299, 0.587, 0.114));
	return luma > ink_max_luma ? colour * (ink_max_luma / luma) : colour;
}

bool is_key(vec4 c, vec3 key) {
	return c.a > 0.5 && distance(c.rgb, key) < 0.1;
}

void fragment() {
	vec2 texture_px = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 texel = floor(UV * texture_px);
	vec2 cell_px = vec2(texture_px.x / float(max(hframes, 1)), texture_px.y);
	vec2 origin = vec2(float(cell) * cell_px.x, 0.0);
	vec2 local = mod(texel - origin - scroll, cell_px);
	uint beat = uint(max(tremble_step, 0));
	if (ink_only && tremble > 0.0) {
		uint band = uint(floor(local.y / BAND_PX));
		float unit = float(pick(uvec3(band, beat, 7u)) % 1024u) / 1023.0;
		local.x = mod(local.x + floor((unit * 2.0 - 1.0) * tremble + 0.5), cell_px.x);
	}
	vec4 c = texture(TEXTURE, (origin + local + 0.5) * TEXTURE_PIXEL_SIZE);
	if (is_key(c, vec3(1.0, 0.0, 1.0))) {
		c.rgb = darkened(ink_colour.rgb);
	} else if (is_key(c, vec3(0.0, 1.0, 1.0))) {
		c.rgb = darkened(ink_b_colour.rgb);
	} else if (is_key(c, vec3(1.0, 1.0, 0.0))) {
		uint choice = pick(uvec3(uvec2(origin + local), beat)) % 6u;
		if (choice == 0u) {
			c.rgb = darkened(ink_colour.rgb);
		} else if (choice == 1u) {
			c.rgb = darkened(ink_b_colour.rgb);
		} else {
			c.rgb = gh_print(vec3(GREYS[int(choice) - 2] / 255.0));
		}
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

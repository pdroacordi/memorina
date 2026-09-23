shader_type canvas_item;
render_mode blend_mul;

// The water, as seen by a creature standing in it. Ivo and the guardians are
// drawn by the creature pass and composited over the finished world, so the
// surface quad can never cover them; this quad lives on the creature layer
// instead, after them, and MULTIPLIES what is already there.
//
// Multiply is what makes it safe inside a transparent pass: a transparent pixel
// stays 0 however it is tinted, and a premultiplied creature pixel just
// scales, so the veil never paints a rectangle of water where no body is. It
// never reads a screen texture. Measured: docs/knowledge/gotchas/screen-texture-copy-scope.md.
//
// It shares water_common with the surface shader, so the waterline crosses a
// body on exactly the row where it crosses the ground behind it.

#include "res://scenes/world/environment/water/water_common.gdshaderinc"

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 texel = floor(world_pos);
	vec4 data = wc_data(wc_column(texel.x + 0.5));
	float surface = wc_surface(data);
	if (texel.y < surface || texel.y >= wc_floor(data)) {
		COLOR = vec4(1.0);
	} else {
		COLOR = vec4(wc_transmit(texel.y - surface, texel), 1.0);
	}
}

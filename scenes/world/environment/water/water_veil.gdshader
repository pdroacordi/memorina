shader_type canvas_item;
render_mode blend_mul;

// Multiply preserves transparent creature-pass pixels; shared water_common keeps the veil aligned with the surface.
// Screen texture scope: docs/knowledge/gotchas/screen-texture-copy-scope.md.

#include "res://scenes/world/environment/water/water_common.gdshaderinc"

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 texel = floor(world_pos);
	vec4 data = wc_data(wc_column(texel.x + 0.5));
	float surface = wc_surface(data);
	if (texel.y < surface || texel.y >= wc_floor(data) || wc_held(texel + 0.5) > 0.0) {
		COLOR = vec4(1.0);
	} else {
		COLOR = vec4(wc_transmit(texel.y - surface, texel), 1.0);
	}
}

shader_type canvas_item;

// Draws ice as its own band per column, from sheet_data (r top, g bottom: world y; b solidity 0..1).
// Ice is world art in world texels; never TIME or FRAGCOORD.

#include "res://scenes/world/memory/dither_common.gdshaderinc"

uniform sampler2D sheet_data : filter_nearest, repeat_disable;
uniform sampler2D ice_ramp : filter_nearest, repeat_disable, hint_default_white;
// World x of the first column's left edge, and a column's width in world px.
uniform float sheet_left = 0.0;
uniform float column_width = 2.0;
// Depth in world px over which ice_ramp runs from its top line to its body.
uniform float ice_thickness = 6.0;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 texel = floor(world_pos);
	int column = int(floor((texel.x + 0.5 - sheet_left) / column_width));
	if (column < 0 || column >= textureSize(sheet_data, 0).x) {
		discard;
	}
	vec4 data = texelFetch(sheet_data, ivec2(column, 0), 0);
	float depth = texel.y - floor(data.r);
	if (data.b <= 0.0 || depth < 0.0 || texel.y >= floor(data.g)) {
		discard;
	}
	// Crystals stipple in as the column sets, on the texel grid.
	if (data.b < 1.0 && data.b <= BAYER[wd_bayer_index(texel)]) {
		discard;
	}
	int entries = textureSize(ice_ramp, 0).x;
	int index = int(round(clamp(depth / ice_thickness, 0.0, 1.0) * float(entries - 1)));
	COLOR = vec4(texelFetch(ice_ramp, ivec2(depth < 1.0 ? 0 : index, 0), 0).rgb, 1.0);
}

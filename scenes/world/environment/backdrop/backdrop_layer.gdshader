shader_type canvas_item;

// One backdrop layer drawn on a quad: each pixel picks its art texel from its layer-local
// position, so fills past the strip are row arithmetic, not texture wrap
// (architecture/vertical-backdrops). Must match BackdropMath.art_row and art_col.
#include "res://scenes/world/memory/seasonal/seasonal_common.gdshaderinc"

uniform sampler2D sheet : filter_nearest, repeat_disable;
uniform int band_count = 3;
// Band per Enums.Season: WINTER, SUMMER, AUTUMN, SPRING.
uniform ivec4 band_of_season = ivec4(0);
// Band-local art row on the anchor's horizon.
uniform int horizon_row = 0;
// BackdropLayer.Fill: 0 NONE, 1 EDGE, 2 REPEAT.
uniform int fill_above = 0;
uniform int fill_below = 1;
uniform bool repeat_x = true;
uniform float distance : hint_range(0.0, 1.0) = 0.0;
// Layer-local position of the quad's centre (MeshInstance2D.position).
uniform vec2 quad_position = vec2(0.0);
// The room's bounds in world px (x, y, width, height): a running neighbour's layers never draw into this room's view.
uniform vec4 room_rect = vec4(-1e9, -1e9, 2e9, 2e9);

varying vec2 layer_pos;
varying vec2 world_pos;
varying vec4 modulate;

void vertex() {
	layer_pos = VERTEX + quad_position;
	// MODEL_MATRIX carries the Parallax2D's scroll, so this is where the pixel is drawn in the world.
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	modulate = COLOR;
}

// Floored modulo: GLSL % is not defined for negative operands everywhere, and float division
// may land one off at exact multiples (gotchas/glsl-floor-division-modulo-can-return-the-divisor).
int wrap(int value, int size) {
	int r = value - size * int(floor(float(value) / float(size)));
	if (r >= size) {
		r -= size;
	}
	if (r < 0) {
		r += size;
	}
	return r;
}

int art_row(int row, int strip_h) {
	if (row >= 0 && row < strip_h) {
		return row;
	}
	int fill = row < 0 ? fill_above : fill_below;
	if (fill == 1) {
		return row < 0 ? 0 : strip_h - 1;
	}
	if (fill == 2) {
		return wrap(row, strip_h);
	}
	return -1;
}

int art_col(int col, int strip_w) {
	if (repeat_x) {
		return wrap(col, strip_w);
	}
	return (col >= 0 && col < strip_w) ? col : -1;
}

void fragment() {
	if (world_pos.x < room_rect.x || world_pos.y < room_rect.y
			|| world_pos.x >= room_rect.x + room_rect.z || world_pos.y >= room_rect.y + room_rect.w) {
		discard;
	}
	ivec2 size = textureSize(sheet, 0);
	int strip_h = size.y / band_count;
	int col = art_col(int(floor(layer_pos.x)), size.x);
	int row = art_row(int(floor(layer_pos.y)) + horizon_row, strip_h);
	if (col < 0 || row < 0) {
		discard;
	}
	int season = gh_season_at(SCREEN_UV);
	if (season < 0) {
		season = greyhush_region_season;
	}
	int band = gh_band_for(season, band_of_season);
	COLOR = texelFetch(sheet, ivec2(col, band * strip_h + row), 0) * modulate;
	if (distance > 0.0) {
		float dissolve = greyhush_distance_fade * distance * gh_forgotten_at(SCREEN_UV);
		COLOR.rgb = mix(COLOR.rgb, greyhush_haze_color, clamp(dissolve, 0.0, 1.0));
	}
}

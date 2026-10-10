shader_type canvas_item;

// One backdrop layer drawn on a quad: each pixel picks its art texel from its layer-local
// position, so fills past the strip are row arithmetic, not texture wrap
// (architecture/vertical-backdrops). Near a seam a pixel is drawn by exactly one room (architecture/backdrop-seams).
// Must match BackdropMath.art_row, art_col, seam_jitter and keeps.
#include "res://scenes/world/memory/seasonal/seasonal_common.gdshaderinc"
#include "res://scenes/world/memory/dither_common.gdshaderinc"

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
// The room's bounds in world px (x, y, width, height), and its touching rooms': a pixel near a seam is drawn by the room
// holding it moved by the seam jitter, so the two backdrops meet in a dithered band, never a line.
uniform vec4 room_rect = vec4(-1e9, -1e9, 2e9, 2e9);
uniform vec4 neighbour_rects[8];
uniform int neighbour_count = 0;
// World px across the seam band; 0 clips to room_rect.
uniform float seam_band = 0.0;
// Must match BackdropMath.SEAM_EPSILON.
const float SEAM_EPSILON = 0.01;

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

bool inside(vec2 p, vec4 rect, float grow) {
	return p.x >= rect.x - grow && p.y >= rect.y - grow && p.x < rect.x + rect.z + grow && p.y < rect.y + rect.w + grow;
}

// Game-pixel Bayer jitter, y on the transposed cell.
vec2 seam_jitter(vec2 game_px) {
	float x = BAYER[wd_bayer_index(game_px)] + 1.0 / 32.0 - 0.5;
	float y = BAYER[wd_bayer_index(game_px.yx)] + 1.0 / 32.0 - 0.5;
	return vec2(x, y) * seam_band;
}

bool keeps(vec2 p, vec2 jitter) {
	vec2 moved = p + jitter;
	if (inside(moved, room_rect, SEAM_EPSILON)) {
		return true;
	}
	for (int i = 0; i < neighbour_count; i++) {
		if (inside(moved, neighbour_rects[i], -SEAM_EPSILON)) {
			return false;
		}
	}
	return inside(p, room_rect, SEAM_EPSILON);
}

void fragment() {
	vec2 game_px = floor(SCREEN_UV * vec2(textureSize(greyhush_season_mask, 0)));
	if (!keeps(world_pos, seam_jitter(game_px))) {
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

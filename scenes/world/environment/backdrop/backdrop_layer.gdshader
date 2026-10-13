shader_type canvas_item;

// One backdrop layer drawn on a quad: each pixel picks its art texel from its layer-local
// position, so fills past the strip are row arithmetic, not texture wrap
// (architecture/vertical-backdrops). A pixel is drawn by exactly one room: a seam is a hard cut (architecture/backdrop-seams).
// Must match BackdropMath.art_row, art_col, pixel_centre, keeps, void_owner, over_top and rect_distance.
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
// The room's bounds in world px (x, y, width, height), and its touching rooms': a pixel in a room is that room's, a
// pixel in the void the void owner's.
uniform vec4 room_rect = vec4(-1e9, -1e9, 2e9, 2e9);
uniform vec4 neighbour_rects[8];
uniform int neighbour_count = 0;
// World px of void around the rooms the nearest room draws (RoomRing.WIDTH); 0 clips to room_rect.
uniform float ring = 0.0;
// Backdrop.Part: 0 every pixel the room owns, 1 all but the void over its top, 2 only that void.
uniform int part = 0;
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

float rect_distance(vec4 rect, vec2 p) {
	vec2 d = max(rect.xy - p, p - (rect.xy + rect.zw));
	return max(max(d.x, d.y), 0.0);
}

bool before(vec4 a, vec4 b) {
	return a.x < b.x || (a.x == b.x && a.y < b.y);
}

// The gap from p to rect for the void owner and how the rect holds p: z 3 over its top and 1 under its floor (its columns,
// gap in y), 2 beside it (its rows, gap in x), 0 past a corner (rect_distance). Must match BackdropMath.ABOVE, BESIDE,
// BELOW and CORNER.
vec2 owner_gap(vec4 rect, vec2 p) {
	if (p.x >= rect.x && p.x < rect.x + rect.z) {
		float hold = p.y >= rect.y + rect.w ? 1.0 : 3.0;
		return vec2(max(max(rect.y - p.y, p.y - (rect.y + rect.w)), 0.0), hold);
	}
	if (p.y >= rect.y && p.y < rect.y + rect.w) {
		return vec2(max(max(rect.x - p.x, p.x - (rect.x + rect.z)), 0.0), 2.0);
	}
	return vec2(rect_distance(rect, p), 0.0);
}

// Whether room_rect owns the void pixel at p: void_owner in BackdropMath. Rooms past the ring never own it; a higher
// hold beats a nearer one, so every boundary is straight.
bool owns_void(vec2 p) {
	vec2 mine = owner_gap(room_rect, p);
	for (int i = 0; i < neighbour_count; i++) {
		if (rect_distance(neighbour_rects[i], p) > ring) {
			continue;
		}
		vec2 theirs = owner_gap(neighbour_rects[i], p);
		if (theirs.y > mine.y) {
			return false;
		}
		if (theirs.y == mine.y && (theirs.x < mine.x || (theirs.x == mine.x && before(neighbour_rects[i], room_rect)))) {
			return false;
		}
	}
	return true;
}

bool keeps(vec2 p) {
	if (inside(p, room_rect, SEAM_EPSILON)) {
		return true;
	}
	for (int i = 0; i < neighbour_count; i++) {
		if (inside(p, neighbour_rects[i], -SEAM_EPSILON)) {
			return false;
		}
	}
	if (rect_distance(room_rect, p) > ring) {
		return false;
	}
	return owns_void(p);
}

void fragment() {
	// Pixel centres: two quads never disagree on a pixel (gotchas/two-quads-disagree-on-a-pixels-world-position).
	vec2 p = floor(world_pos) + 0.5;
	if (!keeps(p)) {
		discard;
	}
	// BackdropMath.over_top.
	bool over = p.y < room_rect.y;
	if ((part == 1 && over) || (part == 2 && !over)) {
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

shader_type canvas_item;

// One grass run's blades: one art pixel wide, rooted on the walk line, bent by the run's springs and swayed by its
// cells' clocks (architecture/generated-grass). Never TIME or FRAGCOORD: the clocks arrive in `blade_data`, and the
// grid is anchored to the world in art pixels.
#include "res://scenes/world/memory/seasonal/seasonal_common.gdshaderinc"

// Must match GrassLook.MAX_BLADE_ART.
const int MAX_BLADE_ART = 8;

// Per segment: r bend (-1..1), g and b the cell's two sway phases (0..1).
uniform sampler2D blade_data : filter_nearest, repeat_disable;
uniform sampler2D palette : filter_nearest, repeat_disable;
// World px of the run's left edge and of its walk line.
uniform float run_left = 0.0;
uniform float walk_y = 0.0;
uniform int segments = 1;
uniform int segment_px = 4;
// Game px per art px.
uniform int art_scale = 2;
// Per band (spring, autumn, winter).
uniform vec3 density = vec3(0.7, 0.45, 0.0);
uniform ivec3 height_min = ivec3(3, 2, 0);
uniform ivec3 height_max = ivec3(7, 5, 0);
uniform ivec4 band_of_season = ivec4(2, 0, 1, 0);
uniform float front_share = 0.25;
uniform float front_height = 0.6;
// The front row draws the blades the back row leaves out, in ForegroundPass.
uniform bool front = false;
uniform float lean = 0.9;
uniform float shorten = 0.35;
uniform float sway_amplitude = 0.12;
// Art px kept bare at each end (0 at a closed end).
uniform int free_left = 0;
uniform int free_right = 0;
// The room's bounds in world px, widened sideways by a blade's lean so a tip may cross a room seam.
uniform vec4 clip_rect = vec4(-1e9, -1e9, 2e9, 2e9);

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

// 0..1 from an art column and a salt; the same on every platform (integer hash).
float blade_hash(int column, int salt) {
	uint h = uint(column) * 2654435761u ^ uint(salt) * 2246822519u;
	h ^= h >> 15u;
	h *= 2246822519u;
	h ^= h >> 13u;
	return float(h & 65535u) / 65536.0;
}

// Explicit components: runtime vector indexing varies across shader backends (seasonal_common.gdshaderinc).
float pick(vec3 values, int band) {
	return band == 0 ? values.x : band == 1 ? values.y : values.z;
}

int pick_int(ivec3 values, int band) {
	return band == 0 ? values.x : band == 1 ? values.y : values.z;
}

int offset_at(float bend, float height, int row) {
	float t = float(row) / max(height, 1.0);
	return int(round(bend * lean * height * t * t));
}

void fragment() {
	if (world_pos.x < clip_rect.x || world_pos.y < clip_rect.y
			|| world_pos.x >= clip_rect.x + clip_rect.z || world_pos.y >= clip_rect.y + clip_rect.w) {
		discard;
	}
	int season = gh_season_at(SCREEN_UV);
	if (season < 0) {
		season = greyhush_region_season;
	}
	int band = gh_band_for(season, band_of_season);
	float share = pick(density, band);
	if (share <= 0.0) {
		discard;
	}
	float art = float(art_scale);
	ivec2 ap = ivec2(floor(world_pos / art));
	int row = int(floor(walk_y / art)) - 1 - ap.y;
	if (row < 0 || row >= MAX_BLADE_ART) {
		discard;
	}
	int left = int(floor(run_left / art)) + free_left;
	int right = int(floor(run_left / art)) + segments * segment_px / art_scale - free_right;
	float shade = -1.0;
	for (int dx = -MAX_BLADE_ART; dx <= MAX_BLADE_ART; dx++) {
		int root = ap.x - dx;
		if (root < left || root >= right || blade_hash(root, 1) >= share) {
			continue;
		}
		if ((blade_hash(root, 2) < front_share) != front) {
			continue;
		}
		int low = pick_int(height_min, band);
		float height = float(low) + floor(blade_hash(root, 3) * float(pick_int(height_max, band) - low + 1));
		if (front) {
			height = max(1.0, round(height * front_height));
		}
		int segment = clamp(int((float(root) + 0.5) * art - run_left) / segment_px, 0, segments - 1);
		vec4 data = texelFetch(blade_data, ivec2(segment, 0), 0);
		float sway = sway_amplitude * (0.6 * sin(TAU * (data.g + blade_hash(root, 5))) + 0.4 * sin(TAU * (data.b + blade_hash(root, 6))));
		float bend = clamp((data.r + sway) * (0.6 + 0.4 * blade_hash(root, 4)), -1.0, 1.0);
		height *= 1.0 - shorten * bend * bend;
		if (float(row) >= height) {
			continue;
		}
		// From the column after the last row's to this row's offset: one 8-connected line, never a doubled corner
		// (bugs/a-bent-grass-blade-draws-doubled-corners).
		int here = offset_at(bend, height, row);
		int below = row > 0 ? offset_at(bend, height, row - 1) : here;
		int start = here == below ? here : below + (here > below ? 1 : -1);
		if (dx >= min(start, here) && dx <= max(start, here)) {
			shade = float(row + 1) / height;
			break;
		}
	}
	if (shade < 0.0) {
		discard;
	}
	int shades = textureSize(palette, 0).x;
	vec4 colour = texelFetch(palette, ivec2(clamp(int(ceil(shade * float(shades))) - 1, 0, shades - 1), band), 0);
	if (colour.a < 0.5) {
		discard;
	}
	COLOR = vec4(colour.rgb, 1.0) * COLOR;
}

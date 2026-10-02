// Shared by the world, creature and season-mask memory passes.
// Must match MemoryFieldMath.source_distance() and disc_influence() in GDScript.
// Dither between adjacent quantised memory levels to avoid checkerboard interiors.

#include "res://scenes/world/memory/dither_common.gdshaderinc"

// Seconds of scaled game time, wrapped; GreyhushRenderer advances it. Stops under a menu hold, unlike TIME.
global uniform float greyhush_time;

const int MAX_SOURCES = 32;
// Must match MemoryField.MAX_SHIELDS and MAX_SOURCES.
const int MAX_SHIELDS = 8;
// Must match GreyhushRenderer.FALLOFF_SAMPLES.
const int FALLOFF_SAMPLES = 64;
const float TAU_F = 6.28318530718;

const int SHAPE_CIRCLE = 0;
const int SHAPE_RECT = 1;
const int SHAPE_CAPSULE = 2;

// xy = centre in game pixels, zw = extent of the solid core (radius in both
// components for a circle; half-width and half-height for a rect; cap radius
// and straight half-height for a capsule).
uniform vec4 sources[MAX_SOURCES];
// x = strength, y = feather in game pixels, z = shape, w = edge seed.
uniform vec4 source_params[MAX_SOURCES];
// rgb = tint, a = leading-ring brightness (1 while a pulse is opening, 0 for
// an authored patch).
uniform vec4 tints[MAX_SOURCES];
// Enums.Season of the pulse that lit this source, or -1 for a source that
// carries no season (an authored grey patch, a death mark). Read by the season
// mask pass only; the colour passes never look at it.
uniform float source_seasons[MAX_SOURCES];
uniform int source_count = 0;

// Creatures push the grey back around themselves. xy = centre, zw = extent.
uniform vec4 shields[MAX_SHIELDS];
// x = amount, y = feather in game pixels, z = shape, w = 1 when the shield is
// clipped to its creature's silhouette.
uniform vec4 shield_params[MAX_SHIELDS];
// Which pass this is. A clipped shield must light ONLY the creature pass, or
// its shape would also brighten the scenery behind the body - which is the
// whole thing clipping was meant to stop. An unclipped shield is the reverse:
// its creature lives in the world pass, so that is where it belongs.
uniform bool clipped_pass = false;
uniform int shield_count = 0;
// One row per shield, 64 samples across, holding that shield's authored
// falloff curve. Baked on the CPU from a Curve resource, so what you draw in
// the inspector is exactly what the GPU reads.
// Clamp sampling to a row; repeating blends the first sample with the last at t = 0.
uniform sampler2D shield_falloff : hint_default_white, filter_linear, repeat_disable;

uniform float baseline : hint_range(0.0, 1.0) = 1.0;

// Use pass pixels so integer window scaling does not change the dither pattern.
uniform vec2 game_size = vec2(640.0, 360.0);

uniform float edge_jaggedness = 0.12;
uniform float edge_sectors = 12.0;
// Seconds between sector updates; 0 keeps the seeded edge fixed.
uniform float edge_reroll_period = 0.0;

uniform int memory_levels : hint_range(2, 16) = 6;
uniform float tint_weight : hint_range(0.0, 1.0) = 0.35;
// The region's own season, worn by whatever is remembered and no pulse tints:
// its palette colour, at tint_weight scaled by the region's baseline, so a
// restored region carries its season in full and a forgotten one barely at
// all. A source's tint always wins where it reaches.
uniform vec3 region_tint : source_color = vec3(1.0);
uniform float region_tint_amount : hint_range(0.0, 1.0) = 0.0;

uniform float haze_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec3 haze_color : source_color = vec3(0.34, 0.37, 0.43);
uniform float contrast_loss : hint_range(0.0, 1.0) = 0.0;
uniform float black_lift : hint_range(0.0, 1.0) = 0.0;
uniform vec3 black_lift_color : source_color = vec3(0.24, 0.26, 0.32);

// The brighter front that runs outward while a pulse opens, so the player can
// read how far it will reach. A band `ring_width` pixels wide hugging the
// inside of each source's core edge, scaled by that source's tints[i].a.
uniform float ring_width = 0.0;
uniform float ring_strength : hint_range(0.0, 1.0) = 0.0;

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.0;
uniform float vignette_start : hint_range(0.0, 1.0) = 0.45;
uniform float vignette_grey_boost : hint_range(0.0, 2.0) = 0.6;

float gh_hash11(float n) {
	return wd_hash11(n);
}

int gh_bayer_index(vec2 px) {
	return wd_bayer_index(px);
}

// Must match MemoryFieldMath.source_distance(). Distance is in game pixels.
float gh_shape_distance(vec2 offset, vec2 extent, int shape) {
	if (shape == SHAPE_RECT) {
		vec2 d = abs(offset) - extent;
		return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0);
	}
	if (shape == SHAPE_CAPSULE) {
		// Collapse the straight section, then it is a circle problem.
		vec2 p = vec2(offset.x, offset.y - clamp(offset.y, -extent.y, extent.y));
		return length(p) - extent.x;
	}
	return length(offset) - extent.x;
}

// Must match MemoryFieldMath.disc_influence().
float gh_influence(float dist, float feather, float strength) {
	if (dist <= 0.0) { return strength; }
	if (feather <= 0.0 || dist >= feather) { return 0.0; }
	return strength * (1.0 - dist / feather);
}

// Rendering only: gameplay uses the clean CPU field, independent of edge noise.
float gh_sector_wobble(vec2 offset, float seed) {
	float angle = atan(offset.y, offset.x);
	float sector = floor((angle + TAU_F * 0.5) / TAU_F * edge_sectors);
	float roll = 0.0;
	if (edge_reroll_period > 0.0) {
		// Each sector's clock is offset by its own hash, so neighbours never
		// re-roll on the same frame.
		float phase = gh_hash11(sector * 7.31 + seed) * edge_reroll_period;
		roll = floor((greyhush_time + phase) / edge_reroll_period);
	}
	return gh_hash11(sector + seed + roll * 61.7) * 2.0 - 1.0;
}

float gh_source_influence(int i, vec2 px, bool ragged, out float dist) {
	vec2 offset = px - sources[i].xy;
	float strength = source_params[i].x;
	float feather = source_params[i].y;
	int shape = int(source_params[i].z);
	float seed = source_params[i].w;

	dist = gh_shape_distance(offset, sources[i].zw, shape);
	if (ragged) {
		// Push the boundary in or out per sector, scaled by the feather so a
		// deliberately hard-edged zone stays hard-edged.
		dist -= feather * edge_jaggedness * gh_sector_wobble(offset, seed);
	}
	return gh_influence(dist, feather, strength);
}

// Rendering only; creature shields do not affect gameplay memory.
float gh_shield_cover(vec2 px) {
	float shield = 0.0;
	for (int i = 0; i < shield_count; i++) {
		bool clipped = shield_params[i].w > 0.5;
		if (clipped != clipped_pass) {
			continue;
		}
		float amount = shield_params[i].x;
		float feather = shield_params[i].y;
		int shape = int(shield_params[i].z);

		float d = gh_shape_distance(px - shields[i].xy, shields[i].zw, shape);
		float coverage;
		if (d <= 0.0) {
			coverage = 1.0;
		} else if (feather <= 0.0 || d >= feather) {
			coverage = 0.0;
		} else {
			// The authored curve decides the gradient across the fade.
			float t = clamp(d / feather, 0.0, 1.0);
			// Land on texel CENTRES. The CPU bakes sample x at t = x/(N-1), so
			// sampling at u = t is half a texel off at both ends.
			float u = (0.5 + t * float(FALLOFF_SAMPLES - 1)) / float(FALLOFF_SAMPLES);
			float row = (float(i) + 0.5) / float(MAX_SHIELDS);
			coverage = texture(shield_falloff, vec2(u, row)).r;
		}
		// max, not a sum: two creatures standing together must not stack.
		shield = max(shield, amount * coverage);
	}
	return clamp(shield, 0.0, 1.0);
}

float gh_smooth_memory(vec2 px) {
	float memory = baseline;
	for (int i = 0; i < source_count; i++) {
		float dist;
		memory += gh_source_influence(i, px, false, dist);
	}
	return mix(clamp(memory, 0.0, 1.0), 1.0, gh_shield_cover(px));
}

float gh_memory(vec2 px, out float smooth_memory, out vec3 tint_rgb, out float tint_amount, out float ring) {
	float memory = baseline;
	vec3 tint_sum = vec3(0.0);
	float tint_total = 0.0;
	ring = 0.0;

	for (int i = 0; i < source_count; i++) {
		float dist;
		float influence = gh_source_influence(i, px, true, dist);
		memory += influence;
		if (influence > 0.0) {
			tint_sum += tints[i].rgb * influence;
			tint_total += influence;
		}
		if (ring_width > 0.0 && tints[i].a > 0.0) {
			// A band just inside the core edge: brightest at half a width
			// in, gone at the edge itself and at a full width in.
			float half_width = ring_width * 0.5;
			float band = 1.0 - abs(dist + half_width) / half_width;
			ring = max(ring, tints[i].a * clamp(band, 0.0, 1.0));
		}
	}

	memory = mix(clamp(memory, 0.0, 1.0), 1.0, gh_shield_cover(px));
	smooth_memory = gh_smooth_memory(px);

	tint_rgb = tint_total > 0.0 ? tint_sum / tint_total : vec3(1.0);
	tint_amount = tint_total;
	return memory;
}

float gh_quantise(float memory, vec2 px) {
	return wd_quantise(memory, memory_levels, px);
}

vec3 gh_shade(vec3 base, float lit_amount, float memory, vec3 tint_rgb, float tint_amount, float ring, vec2 px) {
	float luma = dot(base, vec3(0.299, 0.587, 0.114));
	vec3 grey = vec3(luma);

	vec3 lit = base;
	if (tint_amount > 0.0) {
		lit = mix(base, base * tint_rgb, tint_weight);
	} else if (region_tint_amount > 0.0) {
		lit = mix(base, base * region_tint, tint_weight * region_tint_amount);
	}

	vec3 col = mix(grey, lit, lit_amount);

	float forgotten = 1.0 - memory;
	col = mix(col, vec3(dot(col, vec3(0.3333))), contrast_loss * forgotten);
	col = mix(col, haze_color, haze_strength * forgotten);
	// Lift the floor: a remap that sends black to the lift colour and leaves
	// white alone, applied by how forgotten the pixel is.
	vec3 lifted = black_lift_color + col * (vec3(1.0) - black_lift_color);
	col = mix(col, lifted, black_lift * forgotten);

	if (ring_strength > 0.0 && ring > 0.0) {
		// Quantised through the same dither as the memory, so the ring is a
		// stippled pixel-art highlight and not a soft glow.
		float glow = gh_quantise(ring * ring_strength, px);
		col = mix(col, vec3(1.0), glow);
	}
	return col;
}

vec3 gh_vignette(vec3 col, vec2 uv, float lit_amount) {
	if (vignette_strength <= 0.0) {
		return col;
	}
	vec2 centred = (uv - 0.5) * vec2(game_size.x / game_size.y, 1.0);
	float falloff = smoothstep(vignette_start, 0.78, length(centred) * 0.62);
	float amount = vignette_strength * (1.0 + vignette_grey_boost * (1.0 - lit_amount));
	return col * (1.0 - clamp(falloff * amount, 0.0, 1.0));
}

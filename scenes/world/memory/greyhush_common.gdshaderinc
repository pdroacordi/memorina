// The greyhush, shared by both passes.
//
// Two shaders include this file: greyhush.gdshader drains the WORLD, and
// greyhush_creatures.gdshader drains the CREATURES that were culled out of the
// world pass and composited back on top. They must agree exactly on what a
// given point's memory is, or a creature would read at a different depth of
// grey than the ground it is standing on. Sharing the source is the only way
// to guarantee that.
//
// IMPORTANT: gh_shape_distance() and gh_influence() are mirrored by
// source_distance() and disc_influence() in memory_field_math.gd, because
// GDScript and GLSL cannot share code. Change one and you must change the
// other. Every tunable arrives as a uniform - never re-type a number here.
//
// HOW THE DITHER WORKS, AND WHY IT IS NOT A SIMPLE THRESHOLD.
// The naive version - `remembered = memory > bayer` - picks between FULL COLOUR
// and FULL GREY. That is right only at a boundary. Across a flat interior it
// renders the same handful of pixels per 4x4 cell as colour and the rest as
// grey, everywhere, which reads as a countable checkerboard rather than as a
// place that has lost its memory.
//
// Real pixel-art dithering picks between two ADJACENT steps of a palette. So
// memory is quantised into `memory_levels` bands, and the Bayer matrix decides
// only whether a pixel rounds to the band below or the band above.

const int MAX_SOURCES = 32;
// Mirrored by MemoryField.MAX_SHIELDS / MAX_SOURCES. These are array sizes, so
// they cannot be uniforms - the one pair of numbers in this file that lives in
// two places. Raise one and you must raise the other.
const int MAX_SHIELDS = 8;
// Width of one row of the shield_falloff atlas; mirrors
// GreyhushRenderer.FALLOFF_SAMPLES.
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
uniform vec4 tints[MAX_SOURCES];
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
// repeat_disable matters: with repeat on, a lookup at t = 0 blends 50/50 with
// the LAST texel of the row, so the inner edge of every feather reads the
// average of the curve's two ends instead of curve(0).
uniform sampler2D shield_falloff : hint_default_white, filter_linear, repeat_disable;

uniform float baseline : hint_range(0.0, 1.0) = 1.0;

// The pass's own size, i.e. the 640x360 game resolution. Used instead of
// FRAGCOORD because the project stretches with integer scaling: FRAGCOORD is in
// WINDOW pixels, so dithering off it would give a 4x-finer speckle at 4x zoom
// instead of a stable pixel-art pattern.
uniform vec2 game_size = vec2(640.0, 360.0);

uniform float edge_jaggedness = 0.12;
uniform float edge_sectors = 12.0;

uniform int memory_levels : hint_range(2, 16) = 6;
uniform float tint_weight : hint_range(0.0, 1.0) = 0.35;

uniform float haze_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec3 haze_color : source_color = vec3(0.34, 0.37, 0.43);
uniform float contrast_loss : hint_range(0.0, 1.0) = 0.0;

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.0;
uniform float vignette_start : hint_range(0.0, 1.0) = 0.45;
uniform float vignette_grey_boost : hint_range(0.0, 2.0) = 0.6;

const float BAYER[16] = {
	 0.0 / 16.0,  8.0 / 16.0,  2.0 / 16.0, 10.0 / 16.0,
	12.0 / 16.0,  4.0 / 16.0, 14.0 / 16.0,  6.0 / 16.0,
	 3.0 / 16.0, 11.0 / 16.0,  1.0 / 16.0,  9.0 / 16.0,
	15.0 / 16.0,  7.0 / 16.0, 13.0 / 16.0,  5.0 / 16.0
};

float gh_hash11(float n) {
	float p = fract(n * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

// Distance from a shape's solid core, in game pixels. Zero or negative inside
// the core, growing outward. Mirrors MemoryFieldMath.source_distance().
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

// Mirrors MemoryFieldMath.disc_influence().
float gh_influence(float dist, float feather, float strength) {
	if (dist <= 0.0) { return strength; }
	if (feather <= 0.0 || dist >= feather) { return 0.0; }
	return strength * (1.0 - dist / feather);
}

// The grey does not retreat in a clean arc - it advances and recedes in
// sectors, "como algo que morde de volta". Stable per source and per direction,
// so it reads as a shape rather than as television snow. GPU only: the CPU
// field keeps a clean edge, and nothing in gameplay may depend on this.
float gh_sector_wobble(vec2 offset, float seed) {
	float angle = atan(offset.y, offset.x);
	float sector = floor((angle + TAU_F * 0.5) / TAU_F * edge_sectors);
	return gh_hash11(sector + seed) * 2.0 - 1.0;
}

// The field at one point, plus the accumulated tint of whatever lit it.
float gh_memory(vec2 px, out vec3 tint_rgb, out float tint_amount) {
	float memory = baseline;
	vec3 tint_sum = vec3(0.0);
	float tint_total = 0.0;

	for (int i = 0; i < source_count; i++) {
		vec2 offset = px - sources[i].xy;
		float strength = source_params[i].x;
		float feather = source_params[i].y;
		int shape = int(source_params[i].z);
		float seed = source_params[i].w;

		float dist = gh_shape_distance(offset, sources[i].zw, shape);
		// Push the boundary in or out per sector, scaled by the feather so a
		// deliberately hard-edged zone stays hard-edged.
		dist -= feather * edge_jaggedness * gh_sector_wobble(offset, seed);

		float influence = gh_influence(dist, feather, strength);
		memory += influence;
		if (influence > 0.0) {
			tint_sum += tints[i].rgb * influence;
			tint_total += influence;
		}
	}

	// Creatures carry a little of their own memory. RENDERING ONLY: this never
	// enters MemoryField, so standing somewhere does not thaw the world or make
	// its water freezable.
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

	memory = clamp(memory, 0.0, 1.0);
	memory = mix(memory, 1.0, clamp(shield, 0.0, 1.0));

	tint_rgb = tint_total > 0.0 ? tint_sum / tint_total : vec3(1.0);
	tint_amount = tint_total;
	return memory;
}

// Ordered dither between ADJACENT quantisation steps - see the header. The
// result takes only `memory_levels` distinct values; there is no interpolation.
float gh_quantise(float memory, vec2 px) {
	int index = int(mod(floor(px.y), 4.0)) * 4 + int(mod(floor(px.x), 4.0));
	float steps = float(memory_levels - 1);
	float scaled = memory * steps;
	float lower = floor(scaled);
	float frac = scaled - lower;
	// STRICTLY greater, not step(). GLSL's step(edge, x) is x >= edge, and
	// BAYER[0] is exactly 0.0 - so a value sitting precisely ON a band (a flat
	// sky at baseline 0.8, say) would still round one pixel in every 4x4 cell
	// upward, printing a regular dot grid across an area that should be
	// perfectly uniform.
	float rise = frac > BAYER[index] ? 1.0 : 0.0;
	return clamp((lower + rise) / steps, 0.0, 1.0);
}

// Drains a colour to the given quantised memory, then applies aerial
// perspective. Shared so a creature and the ground it stands on agree.
vec3 gh_shade(vec3 base, float lit_amount, vec3 tint_rgb, float tint_amount) {
	float luma = dot(base, vec3(0.299, 0.587, 0.114));
	vec3 grey = vec3(luma);

	vec3 lit = base;
	if (tint_amount > 0.0) {
		lit = mix(base, base * tint_rgb, tint_weight);
	}

	vec3 col = mix(grey, lit, lit_amount);

	float forgotten = 1.0 - lit_amount;
	col = mix(col, vec3(dot(col, vec3(0.3333))), contrast_loss * forgotten);
	col = mix(col, haze_color, haze_strength * forgotten);
	return col;
}

// A soft darkening toward the edges of the screen. Deliberately smooth rather
// than dithered: it reads as light, not as memory, and the two should not share
// a visual language. Applied in BOTH passes so a creature standing in a dark
// corner does not glow against the world behind it.
vec3 gh_vignette(vec3 col, vec2 uv, float lit_amount) {
	if (vignette_strength <= 0.0) {
		return col;
	}
	vec2 centred = (uv - 0.5) * vec2(game_size.x / game_size.y, 1.0);
	float falloff = smoothstep(vignette_start, 0.78, length(centred) * 0.62);
	float amount = vignette_strength * (1.0 + vignette_grey_boost * (1.0 - lit_amount));
	return col * (1.0 - clamp(falloff * amount, 0.0, 1.0));
}

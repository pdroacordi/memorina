// The corruption edge: a creature's silhouette frays in its own art-pixel grid, re-rolled on greyhush_time
// (docs/knowledge/systems/creatures.md). The grid travels with the sprite: texel space, never screen pixels.
// Custom functions cannot read TEXTURE, so the samplers are macros, expanded in the fragment stage.

#ifndef CORRUPTION_EDGE_INCLUDED
#define CORRUPTION_EDGE_INCLUDED

#include "res://scenes/world/memory/dither_common.gdshaderinc"

global uniform float greyhush_time;

// Written by CorruptionEdge, 0..1.
uniform float fray : hint_range(0.0, 1.0) = 0.15;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform float agitation : hint_range(0.0, 1.0) = 0.0;
uniform float seed = 0.0;
// One frame of the species' strips, texels; constant across its clips.
uniform vec2 frame_size = vec2(96.0, 64.0);
// Art px a stray steps per k, texture space.
uniform vec2 drift = vec2(0.0, -1.0);
// Seconds of greyhush_time between re-rolls.
uniform float reroll_period = 0.25;
// Texels per art pixel: the strips are drawn at 2x.
uniform float art_scale = 2.0;

// Alpha of art pixel CE_P of the frame whose top-left texel is CE_O; outside the frame reads transparent.
#define CE_ALPHA(CE_O, CE_P) (ce_inside(CE_P) ? texture(TEXTURE, ce_art_uv(CE_O, CE_P, TEXTURE_PIXEL_SIZE)).a : 0.0)
// Colour of art pixel CE_P of the frame at CE_O.
#define CE_COLOUR(CE_O, CE_P) texture(TEXTURE, ce_art_uv(CE_O, CE_P, TEXTURE_PIXEL_SIZE))
// Edge weight of art pixel CE_P of the frame at CE_O (ce_edge_weight).
#define CE_EDGE(CE_O, CE_P) ce_edge_weight(CE_ALPHA(CE_O, CE_P), CE_ALPHA(CE_O, CE_P + vec2(1.0, 0.0)), CE_ALPHA(CE_O, CE_P - vec2(1.0, 0.0)), CE_ALPHA(CE_O, CE_P + vec2(0.0, 1.0)), CE_ALPHA(CE_O, CE_P - vec2(0.0, 1.0)), CE_ALPHA(CE_O, CE_P + vec2(2.0, 0.0)), CE_ALPHA(CE_O, CE_P - vec2(2.0, 0.0)), CE_ALPHA(CE_O, CE_P + vec2(0.0, 2.0)), CE_ALPHA(CE_O, CE_P - vec2(0.0, 2.0)))

bool ce_inside(vec2 art) {
	vec2 art_size = floor(frame_size / art_scale);
	return art.x >= 0.0 && art.y >= 0.0 && art.x < art_size.x && art.y < art_size.y;
}

// UV of the centre of art pixel `art` of the frame at `origin` (texels).
vec2 ce_art_uv(vec2 origin, vec2 art, vec2 texel_size) {
	return (origin + (art + 0.5) * art_scale) * texel_size;
}

// The top-left texel of the frame holding `texel`.
vec2 ce_frame_origin(vec2 texel) {
	// From the texel centre: a non-power-of-two width can round a frame's first column down (gotchas/glsl-floor-division-modulo-can-return-the-divisor).
	return floor((texel + 0.5) / frame_size) * frame_size;
}

// 1 with a transparent 4-neighbour 1 art px away (`*1`), 0.5 at 2 art px (`*2`), 0 deeper or when transparent itself.
float ce_edge_weight(float centre, float r1, float l1, float d1, float u1, float r2, float l2, float d2, float u2) {
	if (centre < 0.5) {
		return 0.0;
	}
	if (min(min(r1, l1), min(d1, u1)) < 0.5) {
		return 1.0;
	}
	if (min(min(r2, l2), min(d2, u2)) < 0.5) {
		return 0.5;
	}
	return 0.0;
}

// The re-roll count: the pattern changes every reroll_period of greyhush_time.
float ce_epoch() {
	return floor(greyhush_time / reroll_period + seed);
}

// This art pixel's Bayer threshold, the matrix shifted each epoch.
float ce_threshold(vec2 art, float epoch) {
	vec2 shift = floor(vec2(wd_hash11(epoch + 0.5), wd_hash11(epoch + 17.5)) * 4.0);
	return BAYER[wd_bayer_index(art + shift)];
}

float ce_strength() {
	return clamp(fray + agitation, 0.0, 1.0);
}

// An opaque pixel deserts the silhouette: frayed at the edge, or eaten from the edge inward by the dissolve
// (at 1 the threshold, at most 0.97, is always passed).
bool ce_deserts(float edge, float threshold) {
	return edge * ce_strength() > threshold || dissolve > 0.5 * (1.0 - edge) + 0.5 * threshold;
}

// Whether the edge pixel at `source` throws a stray `k` art px along the drift this epoch.
bool ce_strays(vec2 source, int k, float epoch) {
	float pick = wd_hash11(dot(source, vec2(7.13, 157.31)) + epoch * 3.7 + seed);
	float chance = ce_strength() * 0.5 * (1.0 - dissolve);
	return int(floor(pick * 3.0)) + 1 == k && wd_hash11(pick * 97.0 + epoch) < chance;
}

#endif

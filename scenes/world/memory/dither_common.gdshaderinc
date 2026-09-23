// The ordered dither every pixel-art decision in the game goes through.
//
// Shared by the greyhush (which wraps it with its own `memory_levels`) and by
// the water, which dithers its depth bands, reflection gate and ice with the
// same 4x4 Bayer cell so no two effects ever disagree on the pattern.
//
// The caller chooses the grid `px` is measured in - game pixels for anything
// that follows the memory field, world texels for anything that belongs to the
// art - and must never pass FRAGCOORD: under integer stretching that is WINDOW
// pixels, and the speckle would change size with the window.

#ifndef DITHER_COMMON_INCLUDED
#define DITHER_COMMON_INCLUDED

const float BAYER[16] = {
	 0.0 / 16.0,  8.0 / 16.0,  2.0 / 16.0, 10.0 / 16.0,
	12.0 / 16.0,  4.0 / 16.0, 14.0 / 16.0,  6.0 / 16.0,
	 3.0 / 16.0, 11.0 / 16.0,  1.0 / 16.0,  9.0 / 16.0,
	15.0 / 16.0,  7.0 / 16.0, 13.0 / 16.0,  5.0 / 16.0
};

// The 4x4 Bayer cell a pixel falls in.
int wd_bayer_index(vec2 px) {
	return int(mod(floor(px.y), 4.0)) * 4 + int(mod(floor(px.x), 4.0));
}

// Ordered dither between ADJACENT steps of `levels` evenly spaced values in
// 0..1. The result takes only `levels` distinct values; there is no
// interpolation, so a gradient reads as hand-picked palette bands.
float wd_quantise(float value, int levels, vec2 px) {
	int index = wd_bayer_index(px);
	float steps = float(levels - 1);
	float scaled = value * steps;
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

#endif

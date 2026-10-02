// Shared Bayer dithering; callers choose game pixels or world texels and must match their intended grid.

#ifndef DITHER_COMMON_INCLUDED
#define DITHER_COMMON_INCLUDED

const float BAYER[16] = {
	 0.0 / 16.0,  8.0 / 16.0,  2.0 / 16.0, 10.0 / 16.0,
	12.0 / 16.0,  4.0 / 16.0, 14.0 / 16.0,  6.0 / 16.0,
	 3.0 / 16.0, 11.0 / 16.0,  1.0 / 16.0,  9.0 / 16.0,
	15.0 / 16.0,  7.0 / 16.0, 13.0 / 16.0,  5.0 / 16.0
};

// Returns the 4x4 Bayer cell index.
int wd_bayer_index(vec2 px) {
	return int(mod(floor(px.y), 4.0)) * 4 + int(mod(floor(px.x), 4.0));
}

// Ordered dither between adjacent levels in 0..1.
float wd_quantise(float value, int levels, vec2 px) {
	int index = wd_bayer_index(px);
	float steps = float(levels - 1);
	float scaled = value * steps;
	float lower = floor(scaled);
	float frac = scaled - lower;
	// Must use strict greater: BAYER[0] is zero, and equality would dither exact band values.
	float rise = frac > BAYER[index] ? 1.0 : 0.0;
	return clamp((lower + rise) / steps, 0.0, 1.0);
}

// Shared 1D hash in 0..1.
float wd_hash11(float n) {
	float p = fract(n * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

#endif

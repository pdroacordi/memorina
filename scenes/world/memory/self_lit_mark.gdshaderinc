// A creature-pass pixel the field never greys: a guardian's spawned attacks write this exact alpha on every pixel
// they draw, and the creature composite shades it at full memory (systems/greyhush, "Self-lit pixels").

#ifndef SELF_LIT_MARK_INCLUDED
#define SELF_LIT_MARK_INCLUDED

// 254 of 255, beside the unshielded mark's 253: survives an 8-bit or half-float pass; an opaque sprite over it clears it.
const float GH_SELF_LIT_ALPHA = 254.0 / 255.0;

bool gh_is_self_lit(float alpha) {
	return abs(alpha * 255.0 - 254.0) < 0.5;
}

#endif

// A creature-pass pixel no GreyhushShield may light: the corruption edge writes this exact alpha on every
// pixel it draws, and the creature composite reads it (systems/greyhush, "Unshielded pixels").

#ifndef UNSHIELDED_MARK_INCLUDED
#define UNSHIELDED_MARK_INCLUDED

// 253 of 255: survives an 8-bit or half-float pass; an opaque sprite over it (alpha 1) clears it.
const float GH_UNSHIELDED_ALPHA = 253.0 / 255.0;

bool gh_is_unshielded(float alpha) {
	return abs(alpha * 255.0 - 253.0) < 0.5;
}

#endif

// Shared by every material that reads the season mask: the seasonal art swap
// and the pulse particles. Both need the same one-byte decode, and both must
// sample the mask at the same place, or a snowflake could fall over green.
//
// The mask is a global uniform so a Sprite2D or TileMapLayer anywhere in the
// world can read it without being wired to the renderer. SCREEN_UV, not UV:
// the mask is screen-space, and it must be sampled where THIS fragment lands on
// screen regardless of parallax or camera position.

// filter_nearest is load-bearing: the season is a one-byte code, and a
// bilinear blend of two codes at a boundary decodes as a third season.
global uniform sampler2D greyhush_season_mask : filter_nearest, repeat_disable;
// The region's own season (Enums.Season), pushed by GreyhushRenderer from
// MemoryField.season. What the art shows wherever no pulse overrides it.
global uniform int greyhush_region_season;

// The haze the greyhush pass fogs the forgotten world toward, and how hard
// distance dissolves into it. Both pushed by GreyhushRenderer so one knob on
// the renderer rules every layer.
global uniform vec3 greyhush_haze_color;
global uniform float greyhush_distance_fade;

// The Enums.Season a pulse has painted at this screen position, or -1.
int gh_season_at(vec2 screen_uv) {
	return int(round(texture(greyhush_season_mask, screen_uv).r * 255.0)) - 1;
}

// How forgotten this screen position is, 0..1, smooth. The colour pass owns
// the dither; anything read here must stay a gradient or the two stack.
float gh_forgotten_at(vec2 screen_uv) {
	return 1.0 - texture(greyhush_season_mask, screen_uv).g;
}

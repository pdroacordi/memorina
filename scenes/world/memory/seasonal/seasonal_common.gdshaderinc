// Seasonal art and pulse particles must share the same mask decode and sample location.
//
// Must sample the screen-space mask with SCREEN_UV so parallax and camera position do not shift it.

// Must use filter_nearest: interpolating one-byte season codes creates invalid values.
global uniform sampler2D greyhush_season_mask : filter_nearest, repeat_disable;
// Region season from GreyhushRenderer, used where no pulse overrides it.
global uniform int greyhush_region_season;

// Haze color and distance fade supplied by GreyhushRenderer.
global uniform vec3 greyhush_haze_color;
global uniform float greyhush_distance_fade;

// The Enums.Season a pulse has painted at this screen position, or -1.
int gh_season_at(vec2 screen_uv) {
	return int(round(texture(greyhush_season_mask, screen_uv).r * 255.0)) - 1;
}

// Smooth forgotten amount (0..1); consumers must leave dithering to the colour pass.
float gh_forgotten_at(vec2 screen_uv) {
	return 1.0 - texture(greyhush_season_mask, screen_uv).g;
}

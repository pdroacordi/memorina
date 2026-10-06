// The forgotten print: luma with the blacks lifted toward the cold lift colour.
// One formula for every forgotten thing drawn outside the greyhush pass (life notes, the title).
// GreyhushRenderer pushes both globals; project.godot holds their defaults.

global uniform float greyhush_black_lift;
global uniform vec3 greyhush_black_lift_color;

vec3 gh_print(vec3 rgb) {
	vec3 grey = vec3(dot(rgb, vec3(0.299, 0.587, 0.114)));
	vec3 lifted = greyhush_black_lift_color + grey * (vec3(1.0) - greyhush_black_lift_color);
	return mix(grey, lifted, greyhush_black_lift);
}

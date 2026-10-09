shader_type canvas_item;

// The lesson's dim spares the creatures wherever no foreground covers them: it sits above both
// passes, so it cuts its own hole (architecture/foreground-layer). Exact for binary alpha.

global uniform sampler2D greyhush_creature_pass : filter_nearest, repeat_disable;
global uniform sampler2D greyhush_foreground_pass : filter_nearest, repeat_disable;

void fragment() {
	float creature = texture(greyhush_creature_pass, SCREEN_UV).a;
	float front = texture(greyhush_foreground_pass, SCREEN_UV).a;
	COLOR.a *= 1.0 - creature * (1.0 - front);
}

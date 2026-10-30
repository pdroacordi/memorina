shader_type canvas_item;

// A veil of stopped grey: art pixels of a forgotten-print fill drawn by chance, thinning to its sides, re-rolled on
// greyhush_time like the corruption edge (docs/knowledge/systems/greyhush.md). Game px from UV * size_px, never FRAGCOORD.

#include "res://scenes/world/memory/dither_common.gdshaderinc"
#include "res://scenes/world/memory/greyhush_print.gdshaderinc"

global uniform float greyhush_time;

// The curtain's size in game px; set by FightWall.
uniform vec2 size_px = vec2(32.0, 128.0);
// The fill before the forgotten print.
uniform vec4 fill : source_color = vec4(0.78, 0.8, 0.84, 1.0);
// Share of art pixels drawn down the curtain's middle, 0..1; the world shows through the rest.
uniform float core_density : hint_range(0.0, 1.0) = 0.7;
// Game px from each side over which the curtain thins to nothing.
uniform float fray_px = 10.0;
// Seconds of greyhush_time between re-rolls; matches corruption_edge.gdshaderinc.
uniform float reroll_period = 0.25;
// Game px per art pixel.
uniform float art_scale = 2.0;

void fragment() {
	vec2 px = floor(UV * size_px / art_scale);
	float epoch = floor(greyhush_time / reroll_period);
	float side = min(UV.x, 1.0 - UV.x) * size_px.x;
	float density = core_density * clamp(side / fray_px, 0.0, 1.0);
	float roll = wd_hash11(px.x * 17.3 + px.y * 113.9 + epoch * 7.7);
	float shade = 0.8 + 0.2 * wd_hash11(px.y * 5.1 + epoch * 3.3);
	COLOR = vec4(gh_print(fill.rgb * shade), roll < density ? fill.a : 0.0);
}

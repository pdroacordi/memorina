extends SceneTree

## Draws the few pixels wind is made of, so they stay reproducible and in the
## world palette:
##   assets/sprites/world/wind/wind_streak.png  a 12x1 streak, bright at its
##       head and fading behind it (particles align it to their velocity)
##   assets/sprites/world/wind/wind_streak_radial.png  the same streak standing
##       up (1x12, bright at the bottom), for emitters that align a particle's
##       Y axis to its velocity (the gale racing outward)
##   assets/sprites/world/wind/wind_leaf.png    three 5x5 leaf frames (flat,
##       turned, edge-on) - tumbling is picking a frame, not rotating pixels
## Rerun after changing them:
##   "<godot>" --headless --path . -s res://tools/art/draw_wind_sprites.gd

const DIR := "res://assets/sprites/world/wind"
const LEAF := Color("#b3702d")
const LEAF_DARK := Color("#6e3f1c")
const LEAF_FRAMES := [
	["..##.", ".###d", "####d", ".##d.", "d...."],
	["..#..", ".##d.", ".##d.", "..#d.", ".d..."],
	["....#", "...#.", "..#d.", ".#d..", "d...."],
]

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var streak := Image.create(12, 1, false, Image.FORMAT_RGBA8)
	for x: int in 12:
		streak.set_pixel(x, 0, Color(1, 1, 1, pow((x + 1) / 12.0, 1.6)))
	streak.save_png(ProjectSettings.globalize_path(DIR.path_join("wind_streak.png")))
	var radial := Image.create(1, 12, false, Image.FORMAT_RGBA8)
	for y: int in 12:
		radial.set_pixel(0, y, Color(1, 1, 1, pow((y + 1) / 12.0, 1.6)))
	radial.save_png(ProjectSettings.globalize_path(DIR.path_join("wind_streak_radial.png")))
	var leaves := Image.create(15, 5, false, Image.FORMAT_RGBA8)
	for i: int in LEAF_FRAMES.size():
		var rows: Array = LEAF_FRAMES[i]
		for y: int in rows.size():
			var row: String = rows[y]
			for x: int in row.length():
				if row[x] == "#":
					leaves.set_pixel(i * 5 + x, y, LEAF)
				elif row[x] == "d":
					leaves.set_pixel(i * 5 + x, y, LEAF_DARK)
	leaves.save_png(ProjectSettings.globalize_path(DIR.path_join("wind_leaf.png")))
	print("Wrote wind_streak.png and wind_leaf.png in %s" % DIR)
	quit()

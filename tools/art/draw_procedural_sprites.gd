extends SceneTree

## Draws the few sprites that are simpler to compute than to paint, so they
## stay reproducible and in the world palette:
##   assets/sprites/world/wind/wind_streak.png  a 12x1 streak, bright at its
##       head and fading behind it (particles align it to their velocity)
##   assets/sprites/world/wind/wind_streak_radial.png  the same streak standing
##       up (1x12, bright at the bottom), for emitters that align a particle's
##       Y axis to its velocity (the gale racing outward)
##   assets/sprites/world/wind/wind_leaf.png    three 5x5 leaf frames (flat,
##       turned, edge-on) - tumbling is picking a frame, not rotating pixels
##   assets/sprites/world/props/leaf_wall/leaf_wall.png  a 32x32 tile of those
##       same leaves over dark twigs, wrapping at its edges so it tiles - the
##       curtain Soltar drops is made of the leaves that fall from it
## Rerun after changing them:
##   "<godot>" --headless --path . -s res://tools/art/draw_procedural_sprites.gd

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
	_draw_leaf_wall()
	print("Wrote wind_streak.png, wind_streak_radial.png, wind_leaf.png and leaf_wall.png")
	quit()

const WALL := "res://assets/sprites/world/props/leaf_wall/leaf_wall.png"
const WALL_SIZE := 32
const TWIG := Color("#2b1f16")
const LEAF_COLORS := [Color("#b3702d"), Color("#8f4f22"), Color("#c98a3a"), Color("#6e3f1c")]

func _draw_leaf_wall() -> void:
	var wall := Image.create(WALL_SIZE, WALL_SIZE, false, Image.FORMAT_RGBA8)
	wall.fill(TWIG)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i: int in 70:
		var frame: Array = LEAF_FRAMES[rng.randi_range(0, LEAF_FRAMES.size() - 1)]
		var color: Color = LEAF_COLORS[rng.randi_range(0, LEAF_COLORS.size() - 1)]
		var at := Vector2i(rng.randi_range(0, WALL_SIZE - 1), rng.randi_range(0, WALL_SIZE - 1))
		for y: int in frame.size():
			var row: String = frame[y]
			for x: int in row.length():
				if row[x] == ".":
					continue
				var pixel := color if row[x] == "#" else color.darkened(0.35)
				wall.set_pixel(posmod(at.x + x, WALL_SIZE), posmod(at.y + y, WALL_SIZE), pixel)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(WALL.get_base_dir()))
	wall.save_png(ProjectSettings.globalize_path(WALL))

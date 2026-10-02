extends SceneTree

## Generates reproducible procedural sprites in the world palette:
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
##   assets/sprites/world/wind/wind_gust.png   eight 32x12 frames of a gust line
##       sweeping across its frame and curling up at its head (Vendaval)
##   assets/sprites/world/wind/wind_dash.png   a 9x1 dash in two steps of
##       brightness, head at the right, never a smooth fade
##   assets/sprites/world/rain/rain_splash.png  three 7x4 frames of a drop
##       bursting on the ground, anchored bottom-centre
##   assets/sprites/world/rain/rain_water_splash.png  four 7x5 frames of a drop
##       throwing a crown up out of the water
##   assets/sprites/hud/life/life_note.png  six 12x16 frames of a gold eighth
##       note bobbing and flicking its flag - one unit of Ivo's life. It is
##       drawn in COLOUR, in the world palette: the HUD's shader takes the
##       colour away pixel by pixel when the unit is lost.
## The rest are white, in two tones: whoever draws them tints them.
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
	_draw_gust()
	_save_frames(DIR.path_join("wind_dash.png"), [DASH])
	_save_frames(RAIN_DIR.path_join("rain_splash.png"), SPLASH_FRAMES)
	_save_frames(RAIN_DIR.path_join("rain_water_splash.png"), WATER_SPLASH_FRAMES)
	_draw_life_note()
	print("Wrote the wind, leaf, leaf wall, gust, dash, splash and life note sprites")
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

const RAIN_DIR := "res://assets/sprites/world/rain"
const BRIGHT := Color(1, 1, 1, 1)
const DIM := Color(1, 1, 1, 0.55)
const FAINT := Color(1, 1, 1, 0.3)
## "#" bright, "d" dim, "f" faint.
const DASH := ["dd.######"]
const SPLASH_FRAMES := [
	[".......", ".......", "...#...", "..#.#.."],
	[".......", ".#...#.", "..d.d..", "......."],
	["d.....d", ".......", ".......", "......."],
]
const WATER_SPLASH_FRAMES := [
	[".......", ".......", ".......", "...#...", "..#.#.."],
	[".......", "...#...", "..#.#..", ".d...d.", "......."],
	["...d...", ".d...d.", ".......", ".......", "......."],
	[".......", ".......", "f.....f", ".......", "......."],
]
const GUST_SIZE := Vector2i(32, 12)
const GUST_FRAMES := 8
## Arc length of the visible stroke, and of its bright head.
const GUST_STROKE := 22.0
const GUST_HEAD := 5.0

## Frames given as rows of characters, side by side in one strip.
func _save_frames(path: String, frames: Array) -> void:
	var first: Array = frames[0]
	var size := Vector2i((first[0] as String).length(), first.size())
	var image := Image.create(size.x * frames.size(), size.y, false, Image.FORMAT_RGBA8)
	for i: int in frames.size():
		var rows: Array = frames[i]
		for y: int in rows.size():
			var row: String = rows[y]
			for x: int in row.length():
				var pixel := _tone(row[x])
				if pixel.a > 0.0:
					image.set_pixel(i * size.x + x, y, pixel)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	image.save_png(ProjectSettings.globalize_path(path))

func _tone(symbol: String) -> Color:
	match symbol:
		"#":
			return BRIGHT
		"d":
			return DIM
		"f":
			return FAINT
	return Color(0, 0, 0, 0)

## A line along the bottom of the frame that curls up and back at its head:
## each frame shows a stroke GUST_STROKE long further along it, so the strip
## sweeps across and winds into the curl, bright at the head, dim behind.
func _draw_gust() -> void:
	var path := _gust_path()
	var total := path[path.size() - 1].z
	var image := Image.create(GUST_SIZE.x * GUST_FRAMES, GUST_SIZE.y, false, Image.FORMAT_RGBA8)
	for frame: int in GUST_FRAMES:
		var head := lerpf(GUST_STROKE * 0.5, total, float(frame) / float(GUST_FRAMES - 1))
		# The last frames let the tail catch up with the head: the gust winds out.
		var tail := maxf(head - GUST_STROKE, 0.0) + maxf(float(frame - GUST_FRAMES + 3), 0.0) * 4.0
		for point: Vector3 in path:
			if point.z < tail or point.z > head:
				continue
			var pixel := Vector2i(roundi(point.x), roundi(point.y))
			if pixel.x < 0 or pixel.y < 0 or pixel.x >= GUST_SIZE.x or pixel.y >= GUST_SIZE.y:
				continue
			var tone := BRIGHT if head - point.z < GUST_HEAD else DIM
			var at := Vector2i(frame * GUST_SIZE.x + pixel.x, pixel.y)
			if image.get_pixel(at.x, at.y).a < tone.a:
				image.set_pixelv(at, tone)
	var path_out := ProjectSettings.globalize_path(DIR.path_join("wind_gust.png"))
	image.save_png(path_out)

## Points (x, y, arc length) a quarter pixel apart: straight along row 10,
## then most of a circle of radius 4 curling up over it.
func _gust_path() -> Array[Vector3]:
	var points: Array[Vector3] = []
	var length := 0.0
	var previous := Vector2(0, 10)
	var straight := 22.0
	var step := 0.25
	var x := 0.0
	while x <= straight:
		var here := Vector2(x, 10)
		length += here.distance_to(previous)
		points.append(Vector3(here.x, here.y, length))
		previous = here
		x += step
	var centre := Vector2(straight, 6)
	var t := 0.0
	while t <= TAU * 0.8:
		var here := centre + Vector2(sin(t), cos(t)) * 4.0
		length += here.distance_to(previous)
		points.append(Vector3(here.x, here.y, length))
		previous = here
		t += step / 4.0
	return points

const LIFE_NOTE := "res://assets/sprites/hud/life/life_note.png"
const LIFE_NOTE_SIZE := Vector2i(12, 16)
## "o" outline, "#" gold, "h" highlight, "s" shade - all from the world palette.
const LIFE_NOTE_TONES := {
	"o": Color("#221f19"),
	"#": Color("#ce9f4a"),
	"h": Color("#f5e5c3"),
	"s": Color("#8d5615"),
}
const LIFE_FLAG_DOWN := [
	"......oo..",
	"......o#o.",
	"......o.#o",
	"......o..o",
	"......o...",
]
const LIFE_FLAG_UP := [
	"......ooo.",
	"......o##o",
	"......o..o",
	"......o...",
	"......o...",
]
const LIFE_STEM_AND_HEAD := [
	"......o...",
	"......o...",
	"......o...",
	"......o...",
	"..ooooo...",
	".o#hh#o...",
	"o#h###o...",
	"o####so...",
	".ossso....",
	"..ooo.....",
]
## Each frame's flag and how far the note has risen (whole pixels): it lifts
## as the flag flicks up and settles back, a breath rather than a dance.
const LIFE_NOTE_FRAMES := [
	[false, 0], [false, 1], [true, 1], [true, 1], [true, 0], [false, 0],
]

func _draw_life_note() -> void:
	var image := Image.create(LIFE_NOTE_SIZE.x * LIFE_NOTE_FRAMES.size(), LIFE_NOTE_SIZE.y, false, Image.FORMAT_RGBA8)
	for i: int in LIFE_NOTE_FRAMES.size():
		var frame: Array = LIFE_NOTE_FRAMES[i]
		var rows: Array = (LIFE_FLAG_UP if frame[0] else LIFE_FLAG_DOWN) + LIFE_STEM_AND_HEAD
		var top: int = LIFE_NOTE_SIZE.y - rows.size() - int(frame[1])
		for y: int in rows.size():
			var row: String = rows[y]
			for x: int in row.length():
				if LIFE_NOTE_TONES.has(row[x]):
					image.set_pixel(i * LIFE_NOTE_SIZE.x + 1 + x, top + y, LIFE_NOTE_TONES[row[x]])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(LIFE_NOTE.get_base_dir()))
	image.save_png(ProjectSettings.globalize_path(LIFE_NOTE))

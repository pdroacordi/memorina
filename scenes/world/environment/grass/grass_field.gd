class_name GrassField
extends Node2D
## A room's generated grass: a spring per segment of every run, pushed by characters and stepped on each cell's memory
## clock, held below the stop threshold; drawn by a back and a front strip per run (architecture/generated-grass).

const SHADER := preload("res://scenes/world/environment/grass/grass_blades.gdshader")
## Physics frames between memory samples (as WaterBody).
const RATE_REFRESH_FRAMES := 3
## Game px per art px: the world's one pixel density (systems/art-pipeline).
const ART_SCALE := 2
## Clock seconds the sway clocks wrap at: 0.31 and 0.77 Hz both close whole cycles in it, so the wrap is seamless.
const CLOCK_WRAP := 100.0

var _runs: Array[GrassRun] = []
var _looks: Array[GrassLook] = []
var _springs: Array[GrassSprings] = []
var _textures: Array[ImageTexture] = []
var _images: Array[Image] = []
# Per run: each cell's memory rate, its two sway clocks (clock seconds), its segments' rates and world x, and its
# world rect (the run plus what its blades reach).
var _rates: Array[PackedFloat32Array] = []
var _clocks: Array[PackedVector2Array] = []
var _segment_rates: Array[PackedFloat32Array] = []
var _segment_xs: Array[PackedFloat32Array] = []
var _walks := PackedFloat32Array()
var _areas: Array[Rect2] = []
var _materials: Array[ShaderMaterial] = []
var _fronts: Array[CanvasItem] = []
var _memory: MemoryField
var _rates_frame := -RATE_REFRESH_FRAMES


func _ready() -> void:
	_memory = MemoryField.find_in(self)
	# Only in the tree: the pass bit must reach every ancestor (CanvasPass.join_layer).
	for strip: CanvasItem in _fronts:
		CanvasPass.join_layer(strip, CanvasPass.FOREGROUND)
	var reach := float(GrassLook.MAX_BLADE_ART * ART_SCALE)
	for i: int in _runs.size():
		var run := _runs[i]
		var left := to_global(Vector2(run.first * RoomMap.CELL_PX, run.row * RoomMap.CELL_PX))
		_walks.append(left.y)
		_areas.append(Rect2(left.x - reach, left.y - reach, run.cells() * RoomMap.CELL_PX + reach * 2.0, reach + ART_SCALE))
		var xs := PackedFloat32Array()
		xs.resize(_springs[i].count())
		for s: int in xs.size():
			xs[s] = left.x + (s + 0.5) * GrassSprings.SEGMENT_PX
		_segment_xs.append(xs)
	for material: ShaderMaterial in _materials:
		var i: int = material.get_meta(&"run")
		material.set_shader_parameter(&"run_left", _areas[i].position.x + reach)
		material.set_shader_parameter(&"walk_y", _walks[i])
	for i: int in _runs.size():
		_upload(i)

func _physics_process(delta: float) -> void:
	# A deactivated room is hidden; its grass waits.
	if not is_visible_in_tree() or delta <= 0.0:
		return
	if Engine.get_physics_frames() - _rates_frame >= RATE_REFRESH_FRAMES:
		_refresh_rates()
	var view := get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_visible_rect()
	var bodies: Array[Rect2] = []
	for node: Node in get_tree().get_nodes_in_group(Character.CHARACTERS_GROUP):
		var body := node as Character
		if body != null and body.is_visible_in_tree():
			bodies.append(body.body_rect())
	for i: int in _runs.size():
		# Off screen nothing advances, as with props.
		if view.intersects(_areas[i]) and _step_run(i, delta, bodies):
			_upload(i)

## Called by RoomMapNode before the field enters the tree: its runs, the look each grows, and the room's clip rect.
func setup(runs: Array[GrassRun], looks: Array[GrassLook], clip: Rect2) -> void:
	_runs = runs
	_looks = looks
	var reach := float(GrassLook.MAX_BLADE_ART * ART_SCALE)
	# Sideways the clip gives way by a blade's lean, so a tip may cross a room seam; up and down it is the room's.
	var wide := clip.grow_individual(reach, 0.0, reach, 0.0)
	for i: int in runs.size():
		var run := runs[i]
		var look := looks[i]
		var segments := run.cells() * RoomMap.CELL_PX / GrassSprings.SEGMENT_PX
		_springs.append(GrassSprings.new(segments))
		var image := Image.create_empty(segments, 1, false, Image.FORMAT_RGBAF)
		_images.append(image)
		_textures.append(ImageTexture.create_from_image(image))
		var rates := PackedFloat32Array()
		rates.resize(run.cells())
		_rates.append(rates)
		var segment_rates := PackedFloat32Array()
		segment_rates.resize(segments)
		_segment_rates.append(segment_rates)
		var clocks := PackedVector2Array()
		clocks.resize(run.cells())
		for c: int in run.cells():
			clocks[c] = CLOCK_WRAP * Vector2(AmbientMath.phase_for(Vector2(run.first + c, run.row)), AmbientMath.phase_for(Vector2(run.row, run.first + c)))
		_clocks.append(clocks)
		for front: bool in [false, true]:
			if front and look.front_share <= 0.0:
				continue
			var strip := GrassStrip.new()
			strip.name = "%s%d" % ["Front" if front else "Back", i]
			strip.area = Rect2(run.first * RoomMap.CELL_PX - reach, run.row * RoomMap.CELL_PX - reach,
					run.cells() * RoomMap.CELL_PX + reach * 2.0, reach + ART_SCALE)
			var material := ShaderMaterial.new()
			material.shader = SHADER
			material.set_meta(&"run", i)
			_configure(material, run, look, segments, front, wide, i)
			strip.material = material
			_materials.append(material)
			add_child(strip)
			if front:
				_fronts.append(strip)

func _step_run(index: int, delta: float, bodies: Array[Rect2]) -> bool:
	var run := _runs[index]
	var profile := _looks[index].profile
	var springs := _springs[index]
	var rates := _rates[index]
	var clocks := _clocks[index]
	var segment_rates := _segment_rates[index]
	var moved := false
	for c: int in run.cells():
		if rates[c] > 0.0:
			var clock := clocks[c] + Vector2.ONE * delta * rates[c]
			clocks[c] = Vector2(fposmod(clock.x, CLOCK_WRAP), fposmod(clock.y, CLOCK_WRAP))
			moved = true
	var per_cell := RoomMap.CELL_PX / GrassSprings.SEGMENT_PX
	for s: int in springs.count():
		segment_rates[s] = rates[s / per_cell]
	if _touched(index, bodies):
		var targets := GrassContact.targets(_segment_xs[index], _walks[index], bodies, profile.push, profile.reach)
		# A body in grey grass pushes nothing: that time is stopped.
		for s: int in springs.count():
			if segment_rates[s] > 0.0:
				springs.target[s] = targets[s]
	elif not springs.is_resting():
		for s: int in springs.count():
			if segment_rates[s] > 0.0:
				springs.target[s] = 0.0
	if not springs.is_resting():
		moved = springs.step(delta, segment_rates, profile) or moved
	return moved

# Whether any body stands within the run's contact band, so its push need be worked out at all.
func _touched(index: int, bodies: Array[Rect2]) -> bool:
	var area := _areas[index]
	var walk := _walks[index]
	for body: Rect2 in bodies:
		if body.end.y >= walk - GrassContact.ABOVE and body.end.y <= walk + GrassContact.BELOW \
				and body.end.x >= area.position.x and body.position.x <= area.end.x:
			return true
	return false

func _refresh_rates() -> void:
	_rates_frame = Engine.get_physics_frames()
	for i: int in _runs.size():
		var rates := _rates[i]
		var xs := _segment_xs[i]
		var per_cell := RoomMap.CELL_PX / GrassSprings.SEGMENT_PX
		for c: int in rates.size():
			var point := Vector2(xs[c * per_cell] - GrassSprings.SEGMENT_PX * 0.5 + RoomMap.CELL_PX * 0.5, _walks[i])
			var memory := _memory.sample(point) if _memory != null else 1.0
			rates[c] = AmbientMath.advance(0.0, 1.0, memory, AmbientMath.STOP_THRESHOLD)

func _upload(index: int) -> void:
	var springs := _springs[index]
	var clocks := _clocks[index]
	var hz := _looks[index].profile.sway_hz
	var image := _images[index]
	var per_cell := RoomMap.CELL_PX / GrassSprings.SEGMENT_PX
	for s: int in springs.count():
		var clock := clocks[s / per_cell]
		image.set_pixel(s, 0, Color(springs.bend[s], fposmod(clock.x * hz.x, 1.0), fposmod(clock.y * hz.y, 1.0), 1.0))
	_textures[index].update(image)

func _configure(material: ShaderMaterial, run: GrassRun, look: GrassLook, segments: int, front: bool, clip: Rect2, index: int) -> void:
	var profile := look.profile
	material.set_shader_parameter(&"blade_data", _textures[index])
	material.set_shader_parameter(&"palette", look.palette)
	material.set_shader_parameter(&"segments", segments)
	material.set_shader_parameter(&"segment_px", GrassSprings.SEGMENT_PX)
	material.set_shader_parameter(&"art_scale", ART_SCALE)
	material.set_shader_parameter(&"density", look.density)
	material.set_shader_parameter(&"height_min", look.height_min)
	material.set_shader_parameter(&"height_max", look.height_max)
	material.set_shader_parameter(&"band_of_season", look.band_of_season)
	material.set_shader_parameter(&"front_share", look.front_share)
	material.set_shader_parameter(&"front_height", look.front_height)
	material.set_shader_parameter(&"front", front)
	material.set_shader_parameter(&"lean", profile.lean)
	material.set_shader_parameter(&"shorten", profile.shorten)
	material.set_shader_parameter(&"sway_amplitude", profile.sway_amplitude)
	material.set_shader_parameter(&"free_left", look.corner_free if run.open_left else 0)
	material.set_shader_parameter(&"free_right", look.corner_free if run.open_right else 0)
	material.set_shader_parameter(&"clip_rect", Vector4(clip.position.x, clip.position.y, clip.size.x, clip.size.y))

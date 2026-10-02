class_name GreyhushRenderer extends ColorRect

## Packs the memory field into shader uniforms using the current canvas transform.
## Runs in _process so the transform matches the frame after physics moves the camera.

## Samples per shield falloff row.
const FALLOFF_SAMPLES := 64
## Sentinel for sources without a season; the shader checks for values below 0.
const NO_SEASON := -1.0
## Seconds after which `greyhush_time` wraps, keeping float precision.
const TIME_WRAP := 3600.0

@export_group("Atmosphere")
## Number of desaturation steps, from 2 to 16.
@export_range(2, 16) var memory_levels: int = 6: set = _set_levels
## Fraction of the light color applied to remembered pixels (0..1).
@export_range(0.0, 1.0) var tint_weight: float = 0.35: set = _set_tint_weight
## Haze strength in forgotten areas (0..1).
@export_range(0.0, 1.0) var haze_strength: float = 0.22: set = _set_haze
@export var haze_color: Color = Color(0.34, 0.37, 0.43): set = _set_haze_color
## Contrast reduction in forgotten areas (0..1).
@export_range(0.0, 1.0) var contrast_loss: float = 0.35: set = _set_contrast
## Amount forgotten pixels' blacks move toward black_lift_color (0..1).
@export_range(0.0, 1.0) var black_lift: float = 0.55: set = _set_black_lift
@export var black_lift_color: Color = Color(0.24, 0.26, 0.32): set = _set_black_lift_color
## Global scale for seasonal material distance fade (0..1).
@export_range(0.0, 1.0) var distance_fade: float = 0.8: set = _set_distance_fade

@export_group("Living grey")
## Seconds between edge-sector rerolls; 0 freezes the edge.
@export_range(0.0, 10.0) var edge_reroll_period: float = 1.6: set = _set_reroll
@export_group("Leading ring")
## Leading pulse ring width in game pixels (docs/design/03_mundo_e_ambiente.md section 3.1).
@export_range(0.0, 64.0) var ring_width: float = 10.0: set = _set_ring_width
@export_range(0.0, 1.0) var ring_strength: float = 0.8: set = _set_ring_strength

@export_group("Vignette")
@export_range(0.0, 1.0) var vignette_strength: float = 0.35: set = _set_vig
## Normalized radius where vignette darkening starts (0..1).
@export_range(0.0, 1.0) var vignette_start: float = 0.45: set = _set_vig_start
## Additional vignette strength in forgotten areas (0..2).
@export_range(0.0, 2.0) var vignette_grey_boost: float = 0.6: set = _set_vig_boost

## TextureRect that composites the creature pass; it receives the same uniforms as the world pass.
@export var creature_pass_path: NodePath
## SeasonMask viewport whose texture is published as `greyhush_season_mask`.
@export var season_mask_path: NodePath

var creature_pass: CanvasItem
var season_mask: SeasonMask

@onready var _field: MemoryField = MemoryField.find_in(self)

var _centers := PackedVector4Array()
var _params := PackedVector4Array()
var _tints := PackedColorArray()
var _seasons := PackedFloat32Array()
var _shields := PackedVector4Array()
var _shield_params := PackedVector4Array()

## Scaled seconds published as `greyhush_time`, wrapped at TIME_WRAP.
var _time: float = 0.0
## Baked shield curves, one FALLOFF_SAMPLES-wide row per shield.
var _falloff_image: Image
var _falloff_texture: ImageTexture

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not creature_pass_path.is_empty():
		creature_pass = get_node_or_null(creature_pass_path) as CanvasItem
	assert(creature_pass_path.is_empty() or creature_pass != null,
		"GreyhushRenderer.creature_pass_path does not resolve to a CanvasItem; creatures would render at full colour.")
	if not season_mask_path.is_empty():
		season_mask = get_node_or_null(season_mask_path) as SeasonMask
	assert(season_mask_path.is_empty() or season_mask != null,
		"GreyhushRenderer.season_mask_path does not resolve to a SeasonMask; no art would ever change season.")
	if season_mask:
		RenderingServer.global_shader_parameter_set(&"greyhush_season_mask", season_mask.get_texture())
	_centers.resize(MemoryField.MAX_SOURCES)
	_params.resize(MemoryField.MAX_SOURCES)
	_tints.resize(MemoryField.MAX_SOURCES)
	_seasons.resize(MemoryField.MAX_SOURCES)
	_seasons.fill(NO_SEASON)
	_shields.resize(MemoryField.MAX_SHIELDS)
	_shield_params.resize(MemoryField.MAX_SHIELDS)
	_falloff_image = Image.create_empty(FALLOFF_SAMPLES, MemoryField.MAX_SHIELDS, false, Image.FORMAT_RF)
	_falloff_texture = ImageTexture.create_from_image(_falloff_image)
	_set_param("shield_falloff", _falloff_texture)
	# CreatureMask renders creatures separately, so the main viewport must cull them.
	get_tree().root.canvas_cull_mask = CreatureMask.WORLD_CULL_MASK
	# The passes use different clipping values.
	if material:
		material.set_shader_parameter("clipped_pass", false)
	if creature_pass and creature_pass.material:
		creature_pass.material.set_shader_parameter("clipped_pass", true)
	_push_constants()
	_push_atmosphere()

## Shared shader passes must receive identical field uniforms.
func _set_param(name: StringName, value: Variant) -> void:
	if material:
		material.set_shader_parameter(name, value)
	if creature_pass and creature_pass.material:
		creature_pass.material.set_shader_parameter(name, value)
	if season_mask and season_mask.mask_material():
		season_mask.mask_material().set_shader_parameter(name, value)

func _exit_tree() -> void:
	# Restore global viewport state when this renderer leaves the tree.
	var tree := get_tree()
	if tree:
		tree.root.canvas_cull_mask = 0xFFFFFFFF
	# Clear the global texture when its viewport leaves the tree.
	RenderingServer.global_shader_parameter_set(&"greyhush_season_mask", null)

func _process(delta: float) -> void:
	# The scaled delta: the edge re-rolls through a performance freeze and stops under a hold.
	_time = fmod(_time + delta, TIME_WRAP)
	RenderingServer.global_shader_parameter_set(&"greyhush_time", _time)
	if _field == null or material == null:
		return

	# The shader needs a nonzero viewport size for culling and aspect calculations.
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var canvas := get_viewport().get_canvas_transform()
	var visible_world: Rect2 = canvas.affine_inverse() * Rect2(Vector2.ZERO, size)
	var scale: float = canvas.get_scale().x

	_pack_sources(canvas, scale, visible_world)
	_pack_shields(canvas, scale)

	_set_param("baseline", _field.baseline)
	# The season's tint rides on the baseline: the more a region remembers, the
	# more it wears its season (docs/design/03_mundo_e_ambiente.md section 5.2).
	var palette := _field.palette
	var tint := palette.tint if palette != null else Color.WHITE
	_set_param("region_tint", Vector3(tint.r, tint.g, tint.b))
	_set_param("region_tint_amount", _field.baseline if palette != null else 0.0)
	_set_param("game_size", size)
	# World materials read the region season through a global parameter.
	RenderingServer.global_shader_parameter_set(&"greyhush_region_season", int(_field.season))

func _pack_sources(canvas: Transform2D, scale: float, visible_world: Rect2) -> void:
	var sources := _field.sources_intersecting(visible_world)
	var count: int = mini(sources.size(), MemoryField.MAX_SOURCES)
	assert(sources.size() <= MemoryField.MAX_SOURCES,
		"%d memory sources on screen but the shader carries %d." % [sources.size(), MemoryField.MAX_SOURCES])

	for i: int in count:
		var source: MemorySource = sources[i]
		# Pixel snapping keeps the dithered edge stable as the camera scrolls.
		var center: Vector2 = (canvas * source.global_position).round()
		var extent: Vector2 = source.extent() * scale
		_centers[i] = Vector4(center.x, center.y, extent.x, extent.y)
		_params[i] = Vector4(
			source.strength,
			source.effective_feather() * scale,
			float(source.shape),
			source.edge_seed)
		# Tint alpha carries leading-ring brightness.
		var tint: Color = source.tint
		tint.a = source.ring
		_tints[i] = tint
		_seasons[i] = float(source.season) if source.carries_season else NO_SEASON

	_set_param("sources", _centers)
	_set_param("source_params", _params)
	_set_param("tints", _tints)
	_set_param("source_seasons", _seasons)
	_set_param("source_count", count)

func _pack_shields(canvas: Transform2D, scale: float) -> void:
	var shields := _field.shields()
	var count: int = mini(shields.size(), MemoryField.MAX_SHIELDS)
	assert(shields.size() <= MemoryField.MAX_SHIELDS,
		"%d creature shields active but the shader carries %d; the rest render unprotected." % [shields.size(), MemoryField.MAX_SHIELDS])
	for i: int in count:
		var shield: GreyhushShield = shields[i]
		var center: Vector2 = (canvas * shield.global_position).round()
		var extent: Vector2 = shield.extent() * scale
		_shields[i] = Vector4(center.x, center.y, extent.x, extent.y)
		_shield_params[i] = Vector4(
			shield.amount,
			shield.feather * scale,
			float(shield.shape),
			1.0 if shield.mode == GreyhushShield.Mode.SILHOUETTE else 0.0)
		_bake_falloff_row(i, shield)

	_set_param("shields", _shields)
	_set_param("shield_params", _shield_params)
	_set_param("shield_count", count)
	if count > 0:
		_falloff_texture.update(_falloff_image)

## Writes one shield's sampled falloff curve into its atlas row.
func _bake_falloff_row(row: int, shield: GreyhushShield) -> void:
	for x: int in FALLOFF_SAMPLES:
		var t := float(x) / float(FALLOFF_SAMPLES - 1)
		_falloff_image.set_pixel(x, row, Color(shield.sample_falloff(t), 0.0, 0.0))

## Keep renderer and shader constants synchronized with MemoryFieldMath.
func _push_constants() -> void:
	if material == null:
		return
	_set_param("edge_jaggedness", MemoryFieldMath.EDGE_JAGGEDNESS)
	_set_param("edge_sectors", MemoryFieldMath.EDGE_SECTORS)

func _push_atmosphere() -> void:
	if material == null:
		return
	_set_param("memory_levels", memory_levels)
	_set_param("tint_weight", tint_weight)
	_set_param("haze_strength", haze_strength)
	_set_param("haze_color", haze_color)
	_set_param("contrast_loss", contrast_loss)
	_set_param("black_lift", black_lift)
	_set_param("black_lift_color", black_lift_color)
	# World materials use these global haze settings.
	RenderingServer.global_shader_parameter_set(&"greyhush_haze_color", Vector3(haze_color.r, haze_color.g, haze_color.b))
	RenderingServer.global_shader_parameter_set(&"greyhush_distance_fade", distance_fade)
	# The life HUD shares the world's black-lift settings.
	RenderingServer.global_shader_parameter_set(&"greyhush_black_lift", black_lift)
	RenderingServer.global_shader_parameter_set(&"greyhush_black_lift_color", Vector3(black_lift_color.r, black_lift_color.g, black_lift_color.b))
	_set_param("edge_reroll_period", edge_reroll_period)
	_set_param("ring_width", ring_width)
	_set_param("ring_strength", ring_strength)
	_set_param("vignette_strength", vignette_strength)
	_set_param("vignette_start", vignette_start)
	_set_param("vignette_grey_boost", vignette_grey_boost)

func _set_levels(value: int) -> void:
	memory_levels = value
	_push_atmosphere()

func _set_tint_weight(value: float) -> void:
	tint_weight = value
	_push_atmosphere()

func _set_haze(value: float) -> void:
	haze_strength = value
	_push_atmosphere()

func _set_haze_color(value: Color) -> void:
	haze_color = value
	_push_atmosphere()

func _set_contrast(value: float) -> void:
	contrast_loss = value
	_push_atmosphere()

func _set_black_lift(value: float) -> void:
	black_lift = value
	_push_atmosphere()

func _set_black_lift_color(value: Color) -> void:
	black_lift_color = value
	_push_atmosphere()

func _set_distance_fade(value: float) -> void:
	distance_fade = value
	_push_atmosphere()

func _set_reroll(value: float) -> void:
	edge_reroll_period = value
	_push_atmosphere()

func _set_ring_width(value: float) -> void:
	ring_width = value
	_push_atmosphere()

func _set_ring_strength(value: float) -> void:
	ring_strength = value
	_push_atmosphere()

func _set_vig(value: float) -> void:
	vignette_strength = value
	_push_atmosphere()

func _set_vig_start(value: float) -> void:
	vignette_start = value
	_push_atmosphere()

func _set_vig_boost(value: float) -> void:
	vignette_grey_boost = value
	_push_atmosphere()

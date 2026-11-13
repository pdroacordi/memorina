class_name EngravingView
extends Control
## Shows a bearer fragment's engraved stills between the bars, opaque over the world, on the pausable, scaled clock; a
## director service beside Letterbox and Fade (architecture/story-04-bearer-fragments, "The look").

const GROUP := &"engraving_views"
const SHADER := preload("res://scenes/ui/engraving/engraving.gdshader")
## The art's paper grey; `paper` is it in the forgotten print.
const PAPER_GREY := Color8(184, 184, 184)

## The paper: `gh_print(PAPER_GREY)` at the project's black lift; a call's fade covers the screen in it.
@export var paper: Color = Color(0.758, 0.761, 0.771, 1.0)
## Luma the ink is darkened to at most, so a light season tint still reads on the paper (engraving.gdshader).
@export_range(0.0, 1.0) var ink_max_luma: float = 0.42

var _frame: EngravingFrame
var _dissolve: bool = false
var _tint: Color = Color.WHITE
## Scaled seconds into the current frame.
var _t: float = 0.0
var _sprites: Array[Sprite2D] = []
## The frame being dissolved over; freed once the new one is whole.
var _under: Array[Sprite2D] = []
## Scaled seconds of the clear left, and its length; 0 when none runs.
var _clear_left: float = 0.0
var _clear_seconds: float = 0.0
var _caption_keys: Array[StringName] = []

@onready var _paper: ColorRect = $Paper
@onready var _layers: Node2D = $Art/Layers
@onready var _caption: Label = $CaptionArt/Caption


## The view of the world `tree` runs; null when none is loaded.
static func find(tree: SceneTree) -> EngravingView:
	return tree.get_first_node_in_group(GROUP) as EngravingView

func _enter_tree() -> void:
	add_to_group(GROUP)

func _ready() -> void:
	_paper.color = paper
	hide_now()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_retranslate()

func _process(delta: float) -> void:
	if _frame == null:
		return
	_t += delta
	if _clear_left > 0.0:
		_clear_left = maxf(_clear_left - delta, 0.0)
	_apply()

## Shows `frame` with its ink in `tint`: dithered in from bare paper, or over the frame shown (`dissolve`).
func show_frame(frame: EngravingFrame, tint: Color, dissolve: bool) -> void:
	for sprite: Sprite2D in _under:
		sprite.queue_free()
	_under.clear()
	if dissolve:
		_under = _sprites.duplicate()
	else:
		_free_sprites()
	_sprites.clear()
	_frame = frame
	_dissolve = dissolve and not _under.is_empty()
	_tint = tint
	_t = 0.0
	_clear_left = 0.0
	_clear_seconds = 0.0
	for layer: EngravingLayer in frame.layers:
		_sprites.append(_make_sprite(layer))
	_caption_keys = frame.captions.duplicate()
	_retranslate()
	visible = true
	_apply()

## Dithers the frame out to bare paper over `seconds`; the paper stays.
func clear(seconds: float) -> void:
	if _frame == null:
		return
	_clear_seconds = maxf(seconds, 0.0)
	_clear_left = _clear_seconds
	if _clear_seconds <= 0.0:
		_free_sprites()
		_frame = null
		_caption.modulate.a = 0.0
		return
	_apply()

## Puts the current frame at its end at once.
func land() -> void:
	if _frame == null:
		return
	_t = maxf(_t, _frame.seconds)
	if _clear_seconds > 0.0:
		_clear_left = 0.0
	_apply()

## Hides the view and forgets its frames.
func hide_now() -> void:
	_free_sprites()
	for sprite: Sprite2D in _under:
		sprite.queue_free()
	_under.clear()
	_frame = null
	_t = 0.0
	_clear_left = 0.0
	_clear_seconds = 0.0
	_caption_keys.clear()
	_caption.text = ""
	_caption.modulate.a = 0.0
	visible = false

## Whether the current frame has come in whole; true with no frame.
func is_settled() -> bool:
	return _frame == null or (_under.is_empty() and EngravingMath.shown(_frame, _dissolve, _t) >= 1.0)

## The ink the current frame is drawn in, before the shader darkens it.
func tint() -> Color:
	return _tint

## The current frame's layer sprites, back to front.
func sprites() -> Array[Sprite2D]:
	return _sprites

## Scaled seconds into the current frame.
func elapsed() -> float:
	return _t

func caption_label() -> Label:
	return _caption

func _apply() -> void:
	var frame := _frame
	var shown := EngravingMath.shown(frame, _dissolve, _t)
	var cleared := 1.0
	if _clear_seconds > 0.0 and _clear_left < _clear_seconds:
		cleared = _clear_left / _clear_seconds
	for i: int in _sprites.size():
		var layer := frame.layers[i]
		var sprite := _sprites[i]
		sprite.position = -EngravingMath.layer_window(frame, layer, _t)
		sprite.frame = EngravingMath.cell(layer, _t)
		var material := sprite.material as ShaderMaterial
		material.set_shader_parameter(&"shown", minf(shown, cleared))
		material.set_shader_parameter(&"scroll", EngravingMath.scroll(layer, _t))
		material.set_shader_parameter(&"cell", sprite.frame)
	if shown >= 1.0 and not _under.is_empty():
		for sprite: Sprite2D in _under:
			sprite.queue_free()
		_under.clear()
	_caption.modulate.a = minf(EngravingMath.caption_alpha(frame, _dissolve, _t), cleared)
	if _clear_seconds > 0.0 and _clear_left <= 0.0:
		_free_sprites()
		_frame = null
		_caption.modulate.a = 0.0

func _make_sprite(layer: EngravingLayer) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture = layer.texture
	sprite.hframes = maxi(layer.hframes, 1)
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter(&"ink_colour", _tint)
	material.set_shader_parameter(&"ink_max_luma", ink_max_luma)
	material.set_shader_parameter(&"ink_only", layer.ink_only)
	material.set_shader_parameter(&"hframes", sprite.hframes)
	sprite.material = material
	_layers.add_child(sprite)
	return sprite

func _free_sprites() -> void:
	for sprite: Sprite2D in _sprites:
		sprite.queue_free()
	_sprites.clear()

func _retranslate() -> void:
	var lines := PackedStringArray()
	for key: StringName in _caption_keys:
		lines.append(tr(key))
	_caption.text = "\n".join(lines)

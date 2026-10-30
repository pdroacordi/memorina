class_name TeacherBalloon extends Control

## A teaching creature's phrase as note glyphs in a paper balloon over its head, drawn on the HUD so the grey never
## dims it (systems/teaching-creatures). Pausable: a hold or a lesson's freeze stills it.

const GROUP := &"teacher_balloons"
## Px between glyphs and around them.
const GAP := 4.0
const PADDING := 6.0
## Px from the box's bottom edge to the tail's tip.
const TAIL := 6.0
## Shake: seconds and px either side.
const SHAKE_TIME := 0.3
const SHAKE_PX := 2.0
## An unlit glyph is drawn faded so a lit one reads at true scale (playtests/2026-10-29-core04-teaching-creatures).
const UNLIT := Color(1.0, 1.0, 1.0, 0.4)
## Px the box keeps from the screen's edges.
const MARGIN := 2.0

## Indexed by Enums.GlyphSet.
@export var glyph_sets: Array[NoteGlyphSet] = []

var _anchor: Node2D
var _notes: Array[Enums.Note] = []
var _revealed: Array[bool] = []
var _lit_count: int = 0
var _lit_as_sung: bool = false
var _glyphs: Array[TextureRect] = []
var _shake: float = 0.0
## Px from the box's left edge to the tail's tip; the tail points at the anchor when the box is clamped.
var _tail_x: float = 0.0
var _shake_tween: Tween
var _close_tween: Tween

@onready var _box: Control = $Box


static func find(tree: SceneTree) -> TeacherBalloon:
	return tree.get_first_node_in_group(GROUP) as TeacherBalloon

func _ready() -> void:
	add_to_group(GROUP)
	assert(glyph_sets.size() == Enums.GlyphSet.size(),
		"TeacherBalloon has %d glyph sets for %d members of Enums.GlyphSet." % [glyph_sets.size(), Enums.GlyphSet.size()])
	_box.draw.connect(_draw_box)
	InputDevice.device_changed.connect(_on_device_changed.unbind(1))
	hide()

func _process(_delta: float) -> void:
	if not visible:
		return
	if not is_instance_valid(_anchor) or not _anchor.is_visible_in_tree():
		_anchor = null
		_stop_tweens()
		hide()
		return
	_follow()

## Opens the balloon over `anchor` with `notes` hidden; `lit_as_sung` lights each glyph as it is revealed.
func show_for(anchor: Node2D, notes: Array[Enums.Note], lit_as_sung: bool = false) -> void:
	_stop_tweens()
	_anchor = anchor
	_notes = notes.duplicate()
	_lit_count = 0
	_lit_as_sung = lit_as_sung
	_revealed.clear()
	_revealed.resize(_notes.size())
	_revealed.fill(false)
	_build_glyphs()
	_refresh()
	modulate = Color.WHITE
	show()
	_follow()

func reveal(index: int) -> void:
	if index < 0 or index >= _revealed.size():
		return
	_revealed[index] = true
	_refresh()

func reveal_all() -> void:
	_revealed.fill(true)
	_refresh()

## The box's place on screen; it stays fully inside the viewport.
func box_rect() -> Rect2:
	return Rect2(_box.position, _box.size)

## Shows every glyph and lights the first `count`.
func light(count: int) -> void:
	_lit_count = clampi(count, 0, _notes.size())
	reveal_all()

func shake() -> void:
	if _shake_tween != null:
		_shake_tween.kill()
	_shake_tween = create_tween()
	var quarter := SHAKE_TIME / 4.0
	_shake_tween.tween_property(self, "_shake", -SHAKE_PX, quarter)
	_shake_tween.tween_property(self, "_shake", SHAKE_PX, quarter * 2.0)
	_shake_tween.tween_property(self, "_shake", 0.0, quarter)

## Hides the balloon after `linger` seconds (scaled); zero hides it now.
func close(linger: float = 0.0) -> void:
	_stop_tweens()
	if linger <= 0.0:
		_anchor = null
		hide()
		return
	_close_tween = create_tween()
	_close_tween.tween_interval(linger)
	_close_tween.tween_callback(close)

## The node the balloon is over, or null when closed.
func speaker() -> Node2D:
	return _anchor if visible else null

func is_lit(index: int) -> bool:
	return index < _lit_count or (_lit_as_sung and _revealed[index])

func _build_glyphs() -> void:
	while _glyphs.size() < _notes.size():
		var glyph := TextureRect.new()
		glyph.name = "Glyph%d" % _glyphs.size()
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glyph.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glyph.size = Vector2.ONE * NoteSheet.ICON_SIZE
		_box.add_child(glyph)
		_glyphs.append(glyph)
	for i: int in _glyphs.size():
		_glyphs[i].position = Vector2(PADDING + i * (NoteSheet.ICON_SIZE + GAP), PADDING)
	var count := _notes.size()
	_box.size = Vector2(PADDING * 2.0 + count * NoteSheet.ICON_SIZE + maxi(count - 1, 0) * GAP, PADDING * 2.0 + NoteSheet.ICON_SIZE)
	_tail_x = roundf(_box.size.x / 2.0)
	_box.queue_redraw()

func _refresh() -> void:
	var glyphs := glyph_sets[InputDevice.glyph_set]
	for i: int in _glyphs.size():
		var glyph := _glyphs[i]
		glyph.visible = i < _notes.size() and _revealed[i]
		if i < _notes.size():
			glyph.texture = glyphs.texture(_notes[i], is_lit(i))
			glyph.modulate = Color.WHITE if is_lit(i) else UNLIT

func _follow() -> void:
	var screen := get_viewport().get_canvas_transform() * _anchor.global_position
	var placed := BalloonPlacement.above(screen, _box.size, TAIL, get_viewport_rect().size, MARGIN)
	_box.position = placed + Vector2(_shake, 0.0)
	var tail_x := BalloonPlacement.tail_x(screen.x, placed.x, _box.size.x, TAIL)
	if tail_x != _tail_x:
		_tail_x = tail_x
		_box.queue_redraw()

func _draw_box() -> void:
	var rect := Rect2(Vector2.ZERO, _box.size)
	# Corners cut by one px, as the world's emote bubbles.
	_box.draw_rect(rect.grow_individual(-1.0, 0.0, -1.0, 0.0), EmoteBubble.PAPER)
	_box.draw_rect(rect.grow_individual(0.0, -1.0, 0.0, -1.0), EmoteBubble.PAPER)
	var mid := _tail_x
	_box.draw_colored_polygon(PackedVector2Array([
		Vector2(mid - TAIL / 2.0, _box.size.y),
		Vector2(mid + TAIL / 2.0, _box.size.y),
		Vector2(mid, _box.size.y + TAIL),
	]), EmoteBubble.PAPER)

func _on_device_changed() -> void:
	if visible:
		_refresh()

func _stop_tweens() -> void:
	# A killed tween never emits finished; the shake's offset is put home here.
	if _shake_tween != null:
		_shake_tween.kill()
		_shake_tween = null
	_shake = 0.0
	if _close_tween != null:
		_close_tween.kill()
		_close_tween = null

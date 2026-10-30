class_name BarkBalloon extends Control

## A guardian's line in a paper balloon beside its head while it gathers itself to sing; it blocks nothing and records
## nothing (systems/guardians, "Talks"). Art px under a 2x root (systems/screens); pausable.

const GROUP := &"bark_balloons"
## The Art root's scale: screen px per art px.
const ART_SCALE := 2.0
## Art px: the text's widest row, and at most this many rows (bark_text_fit_test).
const TEXT_WIDTH := 120.0
const MAX_ROWS := 2
const PADDING := 4.0
## Art px from the box's bottom edge to the tail's tip.
const TAIL := 4.0
## Art px from the anchor to the box's near edge.
const GAP := 6.0
## Art px the box keeps from the screen's edges.
const MARGIN := 2.0

## The sheet's slot the box keeps clear of; null keeps clear of nothing.
@export var call_hud: GuardianCallHud

var _anchor: Node2D
## The speaker whose body the box keeps off when it hangs below the head; null keeps off nothing.
var _body: Character
var _side: int = 1
## Art px from the box's left edge to the tail's tip.
var _tail_x: float = 0.0
## The box hangs below the anchor and the tail rises from its top edge.
var _tail_up: bool = false

@onready var _art: Control = $Art
@onready var _box: Control = $Art/Box
@onready var _text: Label = %Text


static func find(tree: SceneTree) -> BarkBalloon:
	return tree.get_first_node_in_group(GROUP) as BarkBalloon

func _ready() -> void:
	add_to_group(GROUP)
	_box.draw.connect(_draw_box)
	hide()

func _process(_delta: float) -> void:
	if not visible:
		return
	if not is_instance_valid(_anchor) or not _anchor.is_visible_in_tree():
		close()
		return
	_follow()

## Shows `key`'s text beside `anchor`, on `side` (-1 west, 1 east) of it, never over `body`.
func say(anchor: Node2D, key: String, side: int, body: Character = null) -> void:
	_anchor = anchor
	_body = body
	_side = 1 if side >= 0 else -1
	_text.text = StutterText.strip(tr(key))
	_fit()
	show()
	_follow()

func close() -> void:
	_anchor = null
	_body = null
	hide()

## The node the balloon is beside, or null when closed.
func speaker() -> Node2D:
	return _anchor if visible else null

## Whether the tail rises from the box's top edge (the box hangs below the head).
func tail_points_up() -> bool:
	return _tail_up

## The box in screen px.
func box_rect() -> Rect2:
	return Rect2(_box.position * ART_SCALE, _box.size * ART_SCALE)

func text_label() -> Label:
	return _text

## The box hugs a short line and wraps a long one at TEXT_WIDTH.
func _fit() -> void:
	var font := _text.get_theme_font(&"font")
	var font_size := _text.get_theme_font_size(&"font_size")
	var one_row := ceilf(font.get_string_size(_text.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	var width := minf(one_row, TEXT_WIDTH)
	_text.position = Vector2(PADDING, PADDING)
	_text.size = Vector2(width, 0.0)
	var rows := clampi(_text.get_line_count(), 1, MAX_ROWS)
	var height := rows * _text.get_line_height() + (rows - 1) * _text.get_theme_constant(&"line_spacing")
	_text.size = Vector2(width, height)
	_box.size = Vector2(width + PADDING * 2.0, height + PADDING * 2.0)
	_box.queue_redraw()

func _follow() -> void:
	var canvas := get_viewport().get_canvas_transform()
	var screen := canvas * _anchor.global_position / ART_SCALE
	var avoid := Rect2()
	if call_hud != null:
		var slot := call_hud.slot_rect()
		avoid = Rect2(slot.position / ART_SCALE, slot.size / ART_SCALE)
	var body := Rect2()
	if is_instance_valid(_body):
		var world := canvas * _body.body_rect()
		body = Rect2(world.position / ART_SCALE, world.size / ART_SCALE)
	var art_screen := get_viewport_rect().size / ART_SCALE
	var placed := BalloonPlacement.beside(screen, _box.size, TAIL, _side, GAP, art_screen, MARGIN, avoid, body)
	_box.position = placed
	var tail_x := BalloonPlacement.tail_x(screen.x, placed.x, _box.size.x, TAIL)
	var tail_up := BalloonPlacement.tail_points_up(screen, placed)
	if tail_x != _tail_x or tail_up != _tail_up:
		_tail_x = tail_x
		_tail_up = tail_up
		_box.queue_redraw()

func _draw_box() -> void:
	var rect := Rect2(Vector2.ZERO, _box.size)
	# Corners cut by one px, as the world's emote bubbles.
	_box.draw_rect(rect.grow_individual(-1.0, 0.0, -1.0, 0.0), EmoteBubble.PAPER)
	_box.draw_rect(rect.grow_individual(0.0, -1.0, 0.0, -1.0), EmoteBubble.PAPER)
	var edge := 0.0 if _tail_up else _box.size.y
	var tip := -TAIL if _tail_up else _box.size.y + TAIL
	_box.draw_colored_polygon(PackedVector2Array([
		Vector2(_tail_x - TAIL / 2.0, edge),
		Vector2(_tail_x + TAIL / 2.0, edge),
		Vector2(_tail_x, tip),
	]), EmoteBubble.PAPER)

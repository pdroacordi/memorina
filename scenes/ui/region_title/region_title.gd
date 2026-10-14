class_name RegionTitle
extends Control
## The region's name, a rule and an epithet, faded in large over play on a first entry (systems/region-title).

## Width of the box the name and epithet are centred in, pack px; the fit test measures against it.
const TEXT_WIDTH := 300.0
## Pack px between the name's ends and the rule's ends.
const RULE_OVERHANG := 12
## The rule's line row, pack px from the top of the art.
const RULE_Y := 50.0

## Scaled seconds before the fade starts.
@export var lead_in: float = 0.3
## Scaled seconds the card takes to appear.
@export var fade_in: float = 0.8
## Scaled seconds the card stays fully shown.
@export var hold: float = 2.5
## Scaled seconds the card takes to disappear.
@export var fade_out: float = 1.0
## Pack px the card rises while it fades in.
@export var rise: float = 3.0

var _tween: Tween

@onready var _art: Control = $Art
@onready var _card: Control = $Art/Card
@onready var _name: Label = $Art/Card/Name
@onready var _rule: RegionTitleOrnament = $Art/Card/Rule
@onready var _epithet: Label = $Art/Card/Epithet


func _ready() -> void:
	_art.modulate.a = 0.0
	_art.visible = false

## Fades the title in, holds it and fades it out; a title still showing fades out first.
## Pausable and scaled, so it stops under a performance freeze and a menu hold and resumes where it was.
func show_title(name_key: String, epithet_key: String) -> void:
	if _tween != null:
		_tween.kill()
	# A killed tween leaves its properties wherever it stopped (gotchas/a-killed-tween-never-emits-finished).
	var shown := _art.modulate.a if _art.visible else 0.0
	_art.modulate.a = shown
	_tween = create_tween().set_trans(Tween.TRANS_SINE)
	if shown > 0.0:
		_tween.tween_property(_art, "modulate:a", 0.0, fade_out * shown * 0.5).set_ease(Tween.EASE_IN)
		_tween.tween_callback(_set_text.bind(name_key, epithet_key))
	else:
		_set_text(name_key, epithet_key)
		_tween.tween_interval(lead_in)
	_tween.tween_callback(_begin_rise)
	_tween.tween_property(_art, "modulate:a", 1.0, fade_in).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(_card, "position:y", 0.0, fade_in).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(hold)
	_tween.tween_property(_art, "modulate:a", 0.0, fade_out).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_art.hide)

## The name the card shows or last showed, translated.
func shown_name() -> String:
	return _name.text

func is_showing() -> bool:
	return _art.visible and _art.modulate.a > 0.0

## The card's opacity, 0..1.
func alpha() -> float:
	return _art.modulate.a if _art.visible else 0.0

func _set_text(name_key: String, epithet_key: String) -> void:
	_name.text = tr(name_key)
	_epithet.text = tr(epithet_key) if not epithet_key.is_empty() else ""
	var font := _name.get_theme_font(&"font")
	var width := font.get_string_size(_name.text, HORIZONTAL_ALIGNMENT_LEFT, -1, _name.get_theme_font_size(&"font_size")).x
	var widest := floori((TEXT_WIDTH - RegionTitleOrnament.DIAMOND) * 0.5)
	_rule.line_length = mini(ceili(width * 0.5) + RULE_OVERHANG, widest)
	_rule.place(_art.size.x * 0.5, RULE_Y)

func _begin_rise() -> void:
	_art.modulate.a = 0.0
	_card.position.y = rise
	_art.show()

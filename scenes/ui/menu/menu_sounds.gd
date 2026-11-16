class_name MenuSounds
extends Node
## Menu cues for the controls under `scope`, at most one per frame (systems/sound-effects).
## It inherits ALWAYS from the Screens root, so it sounds under a hold; cooldowns run on real time.

@export var sounds: MenuSoundSet
## Its navigation presses tell a focus move from a focus grab.
@export var menu_input: MenuInput
## Only focus and buttons inside it sound, so the dialogue box's buttons never click.
@export var scope: Control

var _gate := MenuCueGate.new()

@onready var _emitter: SfxEmitter = $SfxEmitter


func _ready() -> void:
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	if menu_input != null:
		menu_input.focus_stepped.connect(_on_navigated.unbind(1))
		menu_input.page_pressed.connect(_on_navigated.unbind(1))

func _process(_delta: float) -> void:
	var cue := _gate.flush()
	if cue != MenuCueGate.Cue.NONE and sounds != null:
		_emitter.play(sounds.cue(cue))

## The emitter every voice goes through, for tests and the playtest log.
func emitter() -> SfxEmitter:
	return _emitter

## The map opens and closes silently (user, 2026-11-16).
func on_screen_changed(from: ScreenRouter.Kind, to: ScreenRouter.Kind) -> void:
	if from == ScreenRouter.Kind.MAP or to == ScreenRouter.Kind.MAP:
		return
	_gate.ask(MenuCueGate.Cue.OPEN if to != ScreenRouter.Kind.NONE else MenuCueGate.Cue.CLOSE)

# The notebook's step back is its shutting, which ends in a CLOSE.
func on_screen_stepped_back(kind: ScreenRouter.Kind) -> void:
	if kind != ScreenRouter.Kind.NOTEBOOK:
		on_stepped_back()

func on_stepped_back() -> void:
	_gate.ask(MenuCueGate.Cue.BACK)

func on_page_turned(_direction: int) -> void:
	_gate.ask(MenuCueGate.Cue.PAGE)

func _on_navigated() -> void:
	_gate.navigated()

func _on_focus_changed(control: Control) -> void:
	if scope == null or not (control == scope or scope.is_ancestor_of(control)):
		return
	_gate.focus_moved()
	var button := control as BaseButton
	if button != null and not button.pressed.is_connected(_on_confirmed):
		button.pressed.connect(_on_confirmed)

func _on_confirmed() -> void:
	_gate.ask(MenuCueGate.Cue.CONFIRM)

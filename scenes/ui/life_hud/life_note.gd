class_name LifeNote extends Control

## One unit of Ivo's life (design 02, "Vida"): a small note in colour that,
## lost, goes grey AND still. Grey is not a tint here any more than it is in
## the world: the note's own clock runs at its memory, the way MemoryClock runs
## the environment's, so a forgotten note holds the frame it was on and resumes
## from exactly there when a bench gives it back. The colour leaves through
## life_note.gdshader, on the greyhush's Bayer cell.

const MEMORY := &"memory"
const FLASH := &"flash"

## Frames per second of the sway while fully remembered.
@export var fps: float = 6.0
## Seconds the colour takes to leave or come back.
@export var fade_time: float = 0.6
## Where in the sway this note starts, in frames, so a row does not breathe in
## unison. Set before the note enters the tree.
@export var phase: float = 0.0
## A note given back (regain) flashes white and hops a pixel, for this long.
@export var flash_time: float = 0.35
@export var hop_time: float = 0.12

var _memory: float = 1.0
var _target: float = 1.0
var _clock: float = 0.0
## Seconds until a pending regain lands; below 0, none is pending.
var _regain_in: float = -1.0
var _flash: float = 0.0
var _hop: float = 0.0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_clock = phase
	_show()

func _process(delta: float) -> void:
	if _regain_in >= 0.0:
		_regain_in -= delta
		if _regain_in < 0.0:
			_regain_now()
	_memory = move_toward(_memory, _target, delta / maxf(fade_time, 0.001))
	_clock = fposmod(_clock + delta * fps * _memory, float(_sprite.hframes))
	_flash = move_toward(_flash, 0.0, delta / maxf(flash_time, 0.001))
	_hop = maxf(_hop - delta, 0.0)
	_show()

## Remembered or forgotten. `instant` skips the fade - the first time the HUD
## hears the pool, nothing should drain in front of the player.
func remember(remembered: bool, instant: bool = false) -> void:
	if not remembered:
		_regain_in = -1.0
	_target = 1.0 if remembered else 0.0
	if instant:
		_memory = _target
		if is_node_ready():
			_show()

## Given back, after `delay` seconds: the colour returns with a white flash and
## a hop, so a row refilled at a bench fills one note after another.
func regain(delay: float) -> void:
	_regain_in = maxf(delay, 0.0)

func is_remembered() -> bool:
	return _target > 0.5 or _regain_in >= 0.0

## How much colour the note holds right now, 0..1.
func memory() -> float:
	return _memory

func _regain_now() -> void:
	_regain_in = -1.0
	_target = 1.0
	_flash = 1.0
	_hop = hop_time

func _show() -> void:
	_sprite.frame = int(_clock)
	_sprite.position.y = -1.0 if _hop > 0.0 else 0.0
	var material := _sprite.material as ShaderMaterial
	material.set_shader_parameter(MEMORY, _memory)
	material.set_shader_parameter(FLASH, _flash)

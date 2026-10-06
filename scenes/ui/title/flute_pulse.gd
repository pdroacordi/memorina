class_name FlutePulse
extends ColorRect
## A faint glow of the four seasons behind the logo's flute, breathing; user decision 2026-10-06, "Drift + pulse".

## Real seconds for one breath, in and out.
@export var period: float = 4.0
## Alpha at the glow's centre at the top of a breath, 0..1.
@export_range(0.0, 1.0) var peak_alpha: float = 0.45
## Winter, autumn, spring, summer, left to right under the pipes: the season palettes' tints.
@export var season_colors: PackedColorArray = PackedColorArray([
	Color(0.667, 0.82, 0.95),
	Color(0.85, 0.5, 0.27),
	Color(0.58, 0.83, 0.5),
	Color(0.98, 0.79, 0.35),
])

## Where in the breath it is, 0..1.
var _phase: float = 0.0

@onready var _shader := material as ShaderMaterial


func _ready() -> void:
	_shader.set_shader_parameter(&"size_px", size)
	_shader.set_shader_parameter(&"season_colors", season_colors)
	_shader.set_shader_parameter(&"peak_alpha", peak_alpha)
	_show_breath()

func _process(delta: float) -> void:
	_phase = fmod(_phase + delta / period, 1.0)
	_show_breath()

## 0 at rest, 1 at the top of the breath.
func breath() -> float:
	return 0.5 - 0.5 * cos(TAU * _phase)

func _show_breath() -> void:
	_shader.set_shader_parameter(&"breath", breath())

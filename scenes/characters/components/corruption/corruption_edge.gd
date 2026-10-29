class_name CorruptionEdge
extends Node
## The one writer of a creature sprite's corruption-edge uniforms: fray from health and hits, agitation
## while a move telegraphs, and the dissolve that is its waking and its death (docs/knowledge/systems/creatures.md).

## How long a hit's extra fray takes to fade, s.
const HIT_SPIKE_TIME := 0.3

@export var sprite: Sprite2D
@export var health: Health
## Fray at full health, 0..1.
@export_range(0.0, 1.0) var rest_fray: float = 0.15
## Fray at no health, 0..1.
@export_range(0.0, 1.0) var hurt_fray: float = 0.55
## Extra fray a hit adds, fading over HIT_SPIKE_TIME, 0..1.
@export_range(0.0, 1.0) var hit_fray: float = 0.35
## Fray added while a move telegraphs, 0..1.
@export_range(0.0, 1.0) var agitation_fray: float = 0.5
## Art px a stray steps away from the silhouette, texture space (before the sprite's flip).
@export var drift: Vector2 = Vector2(0.0, -1.0)
## One frame of the species' strips, texels.
@export var frame_size: Vector2 = Vector2(96.0, 64.0)
## Gathering out of the grey, s (scaled, pausable).
@export var appear_time: float = 0.5
## Dissolving at death, s (scaled, pausable).
@export var vanish_time: float = 0.6

var _dissolve: float = 0.0
var _agitated: bool = false
var _spike_left: float = 0.0
var _appearing: bool = false
var _vanishing: bool = false
var _gone: bool = false
var _tween: Tween
var _material: ShaderMaterial


func _ready() -> void:
	CanvasPass.join_layer(get_parent() as CanvasItem, CanvasPass.CREATURES)
	_material = sprite.material as ShaderMaterial
	health.damaged.connect(_on_health_damaged)
	_uniform(&"seed", float(get_instance_id() % 1009))
	_uniform(&"frame_size", frame_size)
	_uniform(&"drift", drift)
	_write()

func _process(delta: float) -> void:
	_spike_left = maxf(_spike_left - delta, 0.0)
	_write()

## Drawn as nothing at once: a creature hidden until woken.
func hide_now() -> void:
	_stop_tween()
	_dissolve = 1.0
	_write()

## Gathers out of the grey (the dissolve reversed).
func appear() -> void:
	if _vanishing:
		return
	_appearing = true
	_tween_dissolve(0.0, appear_time * _dissolve)

## Dissolves for good; is_gone() turns true at the end.
func vanish() -> void:
	_appearing = false
	_vanishing = true
	_tween_dissolve(1.0, vanish_time * (1.0 - _dissolve))

func agitate(on: bool) -> void:
	_agitated = on

func is_appearing() -> bool:
	return _appearing

func is_gone() -> bool:
	return _gone

func _tween_dissolve(to: float, seconds: float) -> void:
	_stop_tween()
	_tween = create_tween()
	_tween.tween_method(_set_dissolve, _dissolve, to, maxf(seconds, 0.001))
	_tween.finished.connect(_on_tween_finished)

func _stop_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null

func _set_dissolve(value: float) -> void:
	_dissolve = value
	_write()

func _write() -> void:
	var fray := CorruptionMath.fray(rest_fray, hurt_fray, health.current_hp, health.max_hp) \
			+ CorruptionMath.spike(hit_fray, _spike_left, HIT_SPIKE_TIME)
	_uniform(&"fray", clampf(fray, 0.0, 1.0))
	_uniform(&"agitation", agitation_fray if _agitated else 0.0)
	_uniform(&"dissolve", _dissolve)

func _uniform(uniform: StringName, value: Variant) -> void:
	if _material != null:
		_material.set_shader_parameter(uniform, value)

func _on_tween_finished() -> void:
	_tween = null
	_appearing = false
	_gone = _vanishing

func _on_health_damaged(_amount: int, _current: int) -> void:
	_spike_left = HIT_SPIKE_TIME

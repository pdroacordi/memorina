class_name SfxMuffle
extends Node
## Low-passes the SfxWorld bus by the memory at `subject`; the only writer of that bus's effect (systems/sound-effects).
## Pausable: a freeze or a hold keeps the last cutoff, which the paused world voices keep too.

## Ivo, whose memory muffles the world's objects; he and the creatures stay on Sfx, clear.
@export var subject: Node2D

var _field: MemoryField
var _bus: int = -1
var _index: int = -1
var _low_pass: AudioEffectLowPassFilter


func _ready() -> void:
	_bus = AudioServer.get_bus_index(AudioBuses.SFX_WORLD)
	if _bus < 0:
		return
	for i: int in AudioServer.get_bus_effect_count(_bus):
		var effect := AudioServer.get_bus_effect(_bus, i) as AudioEffectLowPassFilter
		if effect != null:
			_low_pass = effect
			_index = i
			break

func _process(_delta: float) -> void:
	if subject == null:
		return
	if _field == null:
		_field = MemoryField.find_in(self)
		if _field == null:
			return
	apply(_field.sample(subject.global_position))

# The bus outlives the game.tscn swap, so it is left open.
func _exit_tree() -> void:
	apply(1.0)

## Sets the filter for `memory` (0..1): off at 1, else the cutoff of SfxMuffleMath.
func apply(memory: float) -> void:
	if _low_pass == null:
		return
	var on := not SfxMuffleMath.is_open(memory)
	if AudioServer.is_bus_effect_enabled(_bus, _index) != on:
		AudioServer.set_bus_effect_enabled(_bus, _index, on)
	_low_pass.cutoff_hz = SfxMuffleMath.cutoff(memory)

func is_muffling() -> bool:
	return _low_pass != null and AudioServer.is_bus_effect_enabled(_bus, _index)

## Hz the filter is set to now.
func cutoff_hz() -> float:
	return _low_pass.cutoff_hz if _low_pass != null else SfxMuffleMath.OPEN_HZ

class_name HeroSilhouette extends Node2D

## Ivo at the final battle's revelation: his sprite turns to a flat silhouette and alternates with the original
## guardian's past self, faster as the revelation rises, fused at the peak (design 02 section 5.2;
## architecture/grd-06-final-battle). Owns the sprite's material only while the revelation is above zero.

## Alternations per second at the revelation's start and at its peak.
@export var flicker_rate_low: float = 3.0
@export var flicker_rate_high: float = 16.0
@export var silhouette_material: ShaderMaterial

var _level: float = 0.0
## Real seconds since the flicker started.
var _clock: float = 0.0

@onready var _player: Player = get_parent() as Player
@onready var _sprite: Sprite2D = $"../Sprite2D"
@onready var _past_self: Sprite2D = $PastSelf


func _ready() -> void:
	_player.dissonance_changed.connect(_on_dissonance_changed)
	_past_self.hide()
	set_process(false)

func _on_dissonance_changed(_veil: float, revelation: float) -> void:
	var was := _level
	_level = revelation
	if _level > 0.0 and was <= 0.0:
		assert(_sprite.material == null, "HeroSilhouette borrows Ivo's sprite material, which must be free")
		_sprite.material = silhouette_material
		_clock = 0.0
		set_process(true)
	elif _level <= 0.0 and was > 0.0:
		_sprite.material = null
		_sprite.visible = true
		_past_self.hide()
		set_process(false)

func _process(delta: float) -> void:
	_clock += delta / maxf(Engine.time_scale, 0.001)
	# Authored facing west, Ivo facing east: the past self flips the other way.
	_past_self.flip_h = not _sprite.flip_h
	if _level >= 1.0:
		_sprite.visible = true
		_past_self.visible = true
		return
	var rate := lerpf(flicker_rate_low, flicker_rate_high, _level)
	var past := fmod(_clock * rate, 2.0) >= 1.0
	_sprite.visible = not past
	_past_self.visible = past
	_past_self.frame = int(_clock * 6.0) % _past_self.hframes

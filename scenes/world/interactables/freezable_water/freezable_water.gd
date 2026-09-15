class_name FreezableWater extends Node2D

## Placeholder water that FREEZE turns into standable ice. The first world
## object to answer a song, and the template for every later one: it composes
## a SongReceiver and reacts, and the song system knows nothing about it.
##
## It also shows the other half of the greyhush. Its surface bobs on a
## MemoryClock, so in a dead area the water is not merely grey - it is
## geometrically flat and still, which is what
## docs/design/03_mundo_e_ambiente.md section 6.2 asks for.
##
## Out of scope here, and deliberately: the thaw front that retreats from
## where the player stood, hardening before it looks solid, and reflections.
## Freezing is on while the light is on, off when it leaves.

@onready var _ice: CanvasItem = $Ice
@onready var _ice_shape: CollisionShape2D = $IceBody/CollisionShape2D

func _ready() -> void:
	_set_frozen(false)

func _on_song_entered(_song: Song) -> void:
	_set_frozen(true)

func _on_song_left(_song: Song) -> void:
	_set_frozen(false)

func _set_frozen(frozen: bool) -> void:
	_ice.visible = frozen
	# Deferred because these arrive during the physics flush, when the space is
	# locked against shape changes.
	_ice_shape.set_deferred("disabled", not frozen)

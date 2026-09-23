class_name FreezableWater extends Node2D

## Water that FREEZE lays a crossing of ice over. The first world object to
## answer a song, and still the template for every later one: it composes a
## SongReceiver and reacts, and the song system knows nothing about it.
##
## Glue only. The water is a WaterBody, the ice's life is an IceFront, its weight
## is an IceCollider; this node starts the front where the pulse was lit and,
## each physics frame, carries the front's state to the other two. Being the
## parent, it runs before the water it holds, so the water steps and draws with
## this frame's ice.
##
## Design 03 §6.3-6.4: the ice grows only over living water (the pulse that
## carried the song is what wakes it), stills the surface before it looks
## solid, and thaws on its own clock from where the song was played - so it
## melts behind the player, who must commit forward.

## World pixels above the waterline a pulse can reach the water from.
const RECEIVER_HEADROOM := 8

@export var ice: IceProfile

var _front: IceFront

@onready var _water: WaterBody = $Water
@onready var _collider: IceCollider = $IceCollider
@onready var _receiver_shape: CollisionShape2D = $SongReceiver/CollisionShape2D

func _ready() -> void:
	assert(ice != null, "%s needs an IceProfile" % name)
	_front = IceFront.new(_water.column_count(), _water.column_width(), ice)
	_water.set_ice_thickness(ice.thickness)
	var left := _water.global_position.x - _water.size.x * 0.5
	_collider.build(left, _water.size.x, _water.surface_rest_y(), ice.segment_width, ice.thickness)
	# Sized from the water, which a WaterLayer may have painted at any size;
	# a shape of its own, never shared between instances.
	var reach := RectangleShape2D.new()
	reach.size = Vector2(_water.size.x, _water.size.y + RECEIVER_HEADROOM)
	_receiver_shape.shape = reach
	_receiver_shape.position = _water.position + Vector2(0.0, (_water.size.y - RECEIVER_HEADROOM) * 0.5)

func _physics_process(delta: float) -> void:
	if not _front.is_active():
		return
	_front.advance(delta, _water.column_rates())
	for column in _front.column_count():
		_water.set_hold(column, _front.hold(column))
		_water.set_solidity(column, _front.solidity(column))
	_collider.set_solid(_front.solid_segments())

func _on_song_entered(_song: Song, origin: Vector2) -> void:
	_front.freeze_from(_water.column_of(origin.x))

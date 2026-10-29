class_name CachePickup
extends Area2D
## A season seed lying in a CACHE reward slot: Up in reach takes it (systems/seeds-and-the-seller). It shows only while
## the save lacks the cache, so a death before a bench puts it back.

## The seed was taken.
signal taken(slot_id: StringName)

## Reach, in cells, centred on the slot and rising from its floor.
const REACH_CELLS := Vector2(2.0, 2.0)

## Set before the node enters the tree.
var slot_id: StringName

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _reach: UpReach = $UpReach


## Whether the cache `id` still holds its seed under `data`.
static func lies(id: StringName, data: PlayerData) -> bool:
	return not data.caches_taken.has(id)

func _init() -> void:
	collision_layer = Seat.LAYER
	collision_mask = Seat.PLAYER_BODY
	monitorable = true
	monitoring = true

func _ready() -> void:
	assert(slot_id != &"", "A CachePickup needs its slot id before _ready")
	_reach.setup(REACH_CELLS, -float(_sprite.texture.get_height()))
	SaveSystem.progress_changed.connect(_refresh)
	_refresh()

func _physics_process(_delta: float) -> void:
	_reach.refresh(_sprite.visible)

## Shown and still lying: Up may take it. Read at the press, never cached.
func is_available() -> bool:
	return is_visible_in_tree() and lies(slot_id, SaveSystem.player_data)

func is_lying() -> bool:
	return _sprite.visible

## Live, like every gain: a bench commits it, a death forgets it.
func take() -> void:
	SaveSystem.take_cache(slot_id)
	taken.emit(slot_id)

func _refresh() -> void:
	_sprite.visible = lies(slot_id, SaveSystem.player_data)
